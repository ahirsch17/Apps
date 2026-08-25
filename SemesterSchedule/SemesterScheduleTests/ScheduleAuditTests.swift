import XCTest
@testable import SemesterSchedule

/// Regression tests for review/export: notes, ICS, week layout, and loose-paste edge cases.
final class ScheduleAuditTests: XCTestCase {

    private static let eastern = TimeZone(identifier: "America/New_York")!

    private static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = eastern
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return cal.date(from: c)!
    }

    private func event(
        title: String,
        days: Set<Int>,
        start: (Int, Int),
        end: (Int, Int),
        notes: String = "",
        kind: String? = nil,
        selected: Bool = true,
        tba: Bool = false
    ) -> EditableScheduleEvent {
        EditableScheduleEvent(
            title: title,
            location: "Hall 1",
            notes: notes,
            semesterStart: Self.date(2026, 8, 24),
            semesterEnd: Self.date(2026, 12, 11),
            weekdays: days,
            startHour: start.0,
            startMinute: start.1,
            endHour: end.0,
            endMinute: end.1,
            sessionKind: kind,
            isSelected: selected,
            isTBA: tba
        )
    }

    // MARK: - Instructor / ICS notes

    func testMarkdownMailto_keepsEmailWithoutMailtoToken() {
        let formatted = ScheduleNoteFormatting.instructorDisplay(
            from: "Instructor: [Knoeckel, Sarah](mailto:sarahknoeckel@gmail.com) (Primary)"
        )
        XCTAssertEqual(formatted, "Knoeckel, Sarah — sarahknoeckel@gmail.com")
        XCTAssertFalse(formatted?.localizedCaseInsensitiveContains("mailto") == true)
    }

    func testCalendarNotes_doesNotDuplicateSessionKind() {
        let ev = event(
            title: "Dosage",
            days: [3],
            start: (11, 15),
            end: (12, 5),
            notes: "Class\nCRN 11886\nKnoeckel, Sarah — sarahknoeckel@gmail.com",
            kind: "Class"
        )
        let notes = ScheduleNoteFormatting.calendarNotes(for: ev)
        XCTAssertEqual(notes.components(separatedBy: "Class").count - 1, 1)
        XCTAssertTrue(notes.contains("sarahknoeckel@gmail.com"))
        XCTAssertTrue(notes.contains("11886"))
    }

    func testPlanner_icsDescriptionIncludesInstructorEmail() {
        let paste = """
        Dosage Calculations | Nursing 301 Section 01 | Registered
        08/24/2026 -- 12/11/2026
        Tuesday
        11:15 AM - 12:05 PM Type: Class Location: Campus Building: Artis Center Room: 310
        Instructor: Knoeckel, Sarah (mailto:sarahknoeckel@gmail.com) (Primary)
        CRN: 11886
        """
        let events = ScheduleTextParser.parse(paste, defaultSemesterEnd: nil)
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events[0].notes.contains("sarahknoeckel@gmail.com"))

        let plans = CalendarEventPlanner.blueprints(from: events, timeZone: Self.eastern)
        XCTAssertEqual(plans.count, 1)
        XCTAssertTrue(plans[0].notes.contains("sarahknoeckel@gmail.com"))
        XCTAssertTrue(plans[0].notes.contains("Knoeckel, Sarah"))
        XCTAssertFalse(plans[0].notes.localizedCaseInsensitiveContains("mailto"))

        let ics = ICSCalendarExport.calendarString(from: plans, timeZone: Self.eastern)
        XCTAssertTrue(ics.contains("DESCRIPTION:"))
        XCTAssertTrue(ics.contains("sarahknoeckel@gmail.com"))
        XCTAssertTrue(ics.contains("Artis Center") || ics.contains("LOCATION:"))
    }

    func testICS_foldsLongDescriptionAt75Octets() {
        let long = String(repeating: "Instructor notes ", count: 20)
        let ev = event(title: "Long Notes", days: [2], start: (10, 0), end: (11, 0), notes: long)
        let plans = CalendarEventPlanner.blueprints(from: [ev], timeZone: Self.eastern)
        let ics = ICSCalendarExport.calendarString(from: plans, timeZone: Self.eastern)
        XCTAssertTrue(ics.contains("\r\n "))
        let payloadLines = ics.components(separatedBy: "\r\n").filter { $0.isEmpty == false }
        for line in payloadLines where line.hasPrefix(" ") == false {
            XCTAssertLessThanOrEqual(line.utf8.count, 75, line)
        }
        for line in payloadLines where line.hasPrefix(" ") {
            XCTAssertLessThanOrEqual(line.utf8.count, 75, line)
        }
    }

    func testBlankClass_needsDays_notPlanned() {
        let blank = EditableScheduleEvent.blank(
            semesterStart: Self.date(2026, 8, 24),
            semesterEnd: Self.date(2026, 12, 11)
        )
        XCTAssertTrue(blank.needsWeekdayPick)
        XCTAssertFalse(blank.canAddToCalendar)
        XCTAssertTrue(CalendarEventPlanner.blueprints(from: [blank], timeZone: Self.eastern).isEmpty)
    }

    func testDeselectedMeeting_notPlanned() {
        var ev = event(title: "Skip me", days: [2], start: (9, 0), end: (10, 0))
        ev.isSelected = false
        XCTAssertTrue(CalendarEventPlanner.blueprints(from: [ev], timeZone: Self.eastern).isEmpty)
    }

    // MARK: - Week layout

    func testWeekLayout_earlyMorningNotClipped() {
        let ev = event(title: "Dawn lab", days: [2], start: (6, 0), end: (7, 50))
        let hours = WeekScheduleLayout.hourRange(for: [ev])
        XCTAssertLessThanOrEqual(hours.lowerBound, 6)
        let blocks = WeekScheduleLayout.placedBlocks(from: [ev], on: 2, clippingTo: hours)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].startMinutes, 6 * 60)
        XCTAssertGreaterThanOrEqual(blocks[0].startMinutes, hours.lowerBound * 60)
    }

    func testWeekLayout_mwfIsOneEventThreeDayBlocks() {
        let ev = event(title: "Calc", days: [2, 4, 6], start: (9, 0), end: (9, 50), kind: "Class")
        XCTAssertEqual(WeekScheduleLayout.visibleDays(for: [ev]), [2, 3, 4, 5, 6])
        XCTAssertEqual(WeekScheduleLayout.placedBlocks(from: [ev], on: 2, clippingTo: 8...12).count, 1)
        XCTAssertEqual(WeekScheduleLayout.placedBlocks(from: [ev], on: 4, clippingTo: 8...12).count, 1)
        XCTAssertEqual(WeekScheduleLayout.placedBlocks(from: [ev], on: 6, clippingTo: 8...12).count, 1)
        XCTAssertTrue(WeekScheduleLayout.placedBlocks(from: [ev], on: 3, clippingTo: 8...12).isEmpty)
    }

    func testWeekLayout_labAndLectureAreSeparateTuesdayBlocks() {
        let lecture = event(title: "Patho", days: [3], start: (8, 0), end: (10, 50), kind: "Class")
        let other = event(title: "Pharm", days: [3], start: (13, 0), end: (15, 50), kind: "Class")
        let hours = WeekScheduleLayout.hourRange(for: [lecture, other])
        let blocks = WeekScheduleLayout.placedBlocks(from: [lecture, other], on: 3, clippingTo: hours)
        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(Set(blocks.map(\.eventID)), Set([lecture.id, other.id]))
        XCTAssertTrue(blocks.allSatisfy { $0.columnCount == 1 })
    }

    func testWeekLayout_overlappingSameSlotGetsTwoColumns() {
        let a = event(title: "A", days: [3], start: (10, 0), end: (11, 15))
        let b = event(title: "B", days: [3], start: (10, 30), end: (11, 45))
        let blocks = WeekScheduleLayout.placedBlocks(from: [a, b], on: 3, clippingTo: 8...16)
        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(Set(blocks.map(\.column)), Set([0, 1]))
        XCTAssertTrue(blocks.allSatisfy { $0.columnCount == 2 })
    }

    func testWeekLayout_weekendClassShowsSundayColumn() {
        let ev = event(title: "Clinical", days: [1], start: (8, 0), end: (14, 0))
        XCTAssertEqual(WeekScheduleLayout.visibleDays(for: [ev]).first, 1)
        XCTAssertEqual(WeekScheduleLayout.visibleDays(for: [ev]).count, 7)
    }

    func testWeekLayout_tbaAndEmptyDaysHidden() {
        let tba = event(title: "Async", days: [], start: (0, 0), end: (0, 0), tba: true)
        let needsDays = event(title: "Fix me", days: [], start: (10, 0), end: (11, 0))
        XCTAssertTrue(WeekScheduleLayout.timedEvents(in: [tba, needsDays]).isEmpty)
    }

    // MARK: - Loose paste

    func testLoosePaste_doesNotStealNextCourseAsLocation() {
        let fixture = """
        CS 2114 Data Structures
        TR 12:30 PM - 1:45 PM
        MATH 2114 Linear Algebra
        MWF 9:00 AM - 9:50 AM McBryde 100
        """
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.date(2026, 12, 11))
        XCTAssertEqual(events.count, 2)
        let cs = events.first { $0.title.contains("2114") && $0.title.lowercased().contains("data") }
            ?? events.first { $0.weekdays == Set([3, 5]) }
        let math = events.first { $0.weekdays == Set([2, 4, 6]) }
        XCTAssertNotNil(cs)
        XCTAssertNotNil(math)
        XCTAssertFalse(cs!.location.lowercased().contains("math"), cs!.location)
        XCTAssertFalse(cs!.location.lowercased().contains("algebra"), cs!.location)
        XCTAssertTrue(math!.location.lowercased().contains("mcbryde"), math!.location)
    }

    func testLoosePaste_keepsRoomLineAfterTime() {
        let fixture = """
        Public Speaking
        Tuesday/Thursday 6:00 PM – 8:50 PM
        Shanks 160
        """
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.date(2026, 12, 11))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].weekdays, Set([3, 5]))
        XCTAssertTrue(events[0].location.lowercased().contains("shanks"))
    }

    func testNursingPortal_weekLayoutHasSevenMeetingBlocks() {
        let paste = StudentPortalPasteGoldenTests.portalPaste
        let events = ScheduleTextParser.parse(paste, defaultSemesterEnd: nil)
        XCTAssertEqual(events.count, 7)
        let tue = WeekScheduleLayout.placedBlocks(
            from: events,
            on: 3,
            clippingTo: WeekScheduleLayout.hourRange(for: events)
        )
        XCTAssertGreaterThanOrEqual(tue.count, 2, "Tuesday should show distinct Patho vs Pharm (and Dosage) blocks")
    }
}
