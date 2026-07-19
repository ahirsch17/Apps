import XCTest
@testable import SemesterSchedule

/// Verifies parse → blueprint → ICS event creation (Apple/Google calendar payload).
final class CalendarEventCreationTests: XCTestCase {

    private static let eastern = TimeZone(identifier: "America/New_York")!

    private static func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = eastern
        return cal
    }

    private static func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var cal = makeCalendar()
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = hour; c.minute = minute
        return cal.date(from: c)!
    }

    private static let nursingBannerFixture = #"""
Dosage Calculations | Nursing 301 Section 01 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered 
08/24/2026 -- 12/11/2026   
Tuesday
S
M
T
W
T
F
S
   11:15 AM - 12:05PM Type: Class Location: Main Campus Building: Artis Center Room: 310
Instructor: Knoeckel, Sarah (Primary) 
CRN: 11886
Pathophysiology | Nursing 321 Section 01 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered 
08/24/2026 -- 12/11/2026   
Tuesday
S
M
T
W
T
F
S
   08:00 AM - 10:50AM Type: Class Location: Main Campus Building: Artis Center Room: 310
Instructor: Prucha, Anne (Primary) 
CRN: 11902
"""#

    func testPlanner_nursingBanner_createsWeeklyBlueprints() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let plans = CalendarEventPlanner.blueprints(from: events, timeZone: Self.eastern)
        XCTAssertEqual(plans.count, 2)

        let dosage = plans.first { $0.notes.contains("11886") }
        let patho = plans.first { $0.notes.contains("11902") }
        XCTAssertNotNil(dosage)
        XCTAssertNotNil(patho)

        // First Tuesday on/after 08/24/2026 is Aug 25.
        XCTAssertEqual(dosage?.weekdays, [3])
        XCTAssertEqual(patho?.weekdays, [3])

        var cal = Self.makeCalendar()
        XCTAssertEqual(cal.component(.weekday, from: dosage!.firstStart), 3)
        XCTAssertEqual(cal.component(.hour, from: dosage!.firstStart), 11)
        XCTAssertEqual(cal.component(.minute, from: dosage!.firstStart), 15)
        XCTAssertEqual(cal.component(.hour, from: dosage!.firstEnd), 12)
        XCTAssertEqual(cal.component(.minute, from: dosage!.firstEnd), 5)

        let duration = dosage!.firstEnd.timeIntervalSince(dosage!.firstStart)
        XCTAssertEqual(duration, 50 * 60, accuracy: 0.5)
    }

    func testICS_containsRRULEAndAlarmForGoogleAndApple() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let plans = CalendarEventPlanner.blueprints(from: events, timeZone: Self.eastern)
        let ics = ICSCalendarExport.calendarString(from: plans, timeZone: Self.eastern)

        XCTAssertTrue(ics.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(ics.contains("BEGIN:VEVENT"))
        XCTAssertTrue(ics.contains("RRULE:FREQ=WEEKLY;BYDAY=TU;UNTIL="))
        XCTAssertTrue(ics.contains("SUMMARY:Dosage Calculations"))
        XCTAssertTrue(ics.contains("SUMMARY:Pathophysiology"))
        XCTAssertTrue(ics.contains("TRIGGER:-PT15M"))
        XCTAssertTrue(ics.contains("END:VCALENDAR"))
        // Two distinct UIDs / events
        XCTAssertEqual(ics.components(separatedBy: "BEGIN:VEVENT").count - 1, 2)
    }

    func testICS_mwfTableRow_byDayTokens() {
        let end = Self.date(2026, 12, 11)
        let fixture = "22678 MATH 2114 Intro to Linear Algebra 9:00 AM - 9:50 AM MWF MCCH 311"
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: end)
        XCTAssertEqual(events.count, 1)
        let plans = CalendarEventPlanner.blueprints(from: events, timeZone: Self.eastern)
        XCTAssertEqual(plans.count, 1)
        let ics = ICSCalendarExport.calendarString(from: plans, timeZone: Self.eastern)
        XCTAssertTrue(ics.contains("BYDAY=MO,WE,FR") || ics.contains("BYDAY=FR,MO,WE") || ics.contains("BYDAY=MO,FR,WE"))
        // Sorted weekdays → MO,WE,FR
        XCTAssertTrue(ics.contains("BYDAY=MO,WE,FR"))
        XCTAssertTrue(ics.contains("LOCATION:MCCH 311"))
    }

    func testOvernightDuration_spansPastMidnight() {
        let start = Self.date(2026, 8, 24)
        let end = Self.date(2026, 12, 11)
        let ev = EditableScheduleEvent(
            title: "Night Lab",
            location: "Science 1",
            notes: "CRN 99999",
            semesterStart: start,
            semesterEnd: end,
            weekdays: [2],
            startHour: 22,
            startMinute: 0,
            endHour: 1,
            endMinute: 0
        )
        let cal = Self.makeCalendar()
        XCTAssertEqual(ev.durationSeconds(calendar: cal), 3 * 3600, accuracy: 0.5)
        let plans = CalendarEventPlanner.blueprints(from: [ev], timeZone: Self.eastern)
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].firstEnd.timeIntervalSince(plans[0].firstStart), 3 * 3600, accuracy: 0.5)
    }

    func testTBARows_excludedFromBlueprints() {
        let end = Self.date(2026, 12, 11)
        let start = Self.date(2026, 8, 11)
        let fixture = """
CRN\tCourse\tModality\tTitle\tGrade Opt\tCredit Hrs\tTime\tDays\tLocation\tInstructor\tPart of Term\tExam
10152\tACIS 1004\tOnline: Asynchronous\tAccounting Foundations\tA - F\t3.00\tTBA\tTBA\tONLINE\tJean M. Lacoste\tE\t00X
22774\tCS 4094\tOnline with Synchronous Mtgs.\tComputer Science Capstone\tA - F\t3.00\t12:30 PM - 1:45 PM\tTR\tONLINE\tSehrish Basir Nizamani\tE\t12T
"""
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: end)
        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.contains { $0.isTBA && $0.notes.contains("10152") })
        let plans = CalendarEventPlanner.blueprints(from: events, timeZone: Self.eastern)
        XCTAssertEqual(plans.count, 1)
        XCTAssertTrue(plans[0].notes.contains("22774"))
        XCTAssertEqual(plans[0].weekdays, [3, 5])
        _ = start
    }

    func testDeselectedRows_notPlanned() {
        let end = Self.date(2026, 12, 11)
        var events = ScheduleTextParser.parse(
            "22678 MATH 2114 Intro to Linear Algebra 9:00 AM - 9:50 AM MWF MCCH 311",
            defaultSemesterEnd: end
        )
        XCTAssertEqual(events.count, 1)
        events[0].isSelected = false
        XCTAssertTrue(CalendarEventPlanner.blueprints(from: events, timeZone: Self.eastern).isEmpty)
    }

    /// Second full pass: same fixtures must stay stable (regression guard).
    func testEventCreation_secondPass_matchesFirstPass() {
        let eventsA = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let eventsB = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let plansA = CalendarEventPlanner.blueprints(from: eventsA, timeZone: Self.eastern)
        let plansB = CalendarEventPlanner.blueprints(from: eventsB, timeZone: Self.eastern)
        XCTAssertEqual(plansA.count, plansB.count)
        XCTAssertEqual(plansA.map(\.title), plansB.map(\.title))
        XCTAssertEqual(plansA.map(\.weekdays), plansB.map(\.weekdays))
        XCTAssertEqual(plansA.map(\.firstStart), plansB.map(\.firstStart))
        XCTAssertEqual(plansA.map(\.firstEnd), plansB.map(\.firstEnd))

        let icsA = ICSCalendarExport.calendarString(from: plansA, timeZone: Self.eastern)
        let icsB = ICSCalendarExport.calendarString(from: plansB, timeZone: Self.eastern)
        // Strip DTSTAMP (wall-clock) before comparing.
        func stripStamp(_ s: String) -> String {
            s.replacingOccurrences(
                of: #"DTSTAMP:\d{8}T\d{6}Z"#,
                with: "DTSTAMP:FIXED",
                options: .regularExpression
            )
        }
        XCTAssertEqual(stripStamp(icsA), stripStamp(icsB))
    }
}
