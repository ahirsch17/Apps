import XCTest
@testable import SemesterSchedule

/// Extra registrar surface forms beyond the original Banner / VT / table / grid fixtures.
final class ScheduleVariationTests: XCTestCase {

    private static let semesterEnd: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        var c = DateComponents()
        c.year = 2026; c.month = 12; c.day = 11
        return cal.date(from: c)!
    }()

    func testTuThSlashDays() {
        let fixture = "21905 MUS 3064 Digital Sound Manipulation 9:30 AM - 10:45 AM Tu/Th LIBR 121"
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].weekdays, Set([3, 5]))
    }

    func testMWFWithSlashes() {
        let fixture = "22678 MATH 2114 Intro to Linear Algebra 9:00 AM - 9:50 AM M/W/F MCCH 311"
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].weekdays, Set([2, 4, 6]))
    }

    func testTwentyFourHourTableRow() {
        let fixture = "22774 CS 4094 Computer Science Capstone 12:30-13:45 TR ONLINE"
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].startHour, 12)
        XCTAssertEqual(events[0].startMinute, 30)
        XCTAssertEqual(events[0].endHour, 13)
        XCTAssertEqual(events[0].endMinute, 45)
        XCTAssertEqual(events[0].weekdays, Set([3, 5]))
    }

    func testEnDashTimeRange() {
        let fixture = "21937 CS 4944 Seminar 2:30 PM – 3:20 PM F MCB 100"
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].startHour, 14)
        XCTAssertEqual(events[0].endHour, 15)
        XCTAssertEqual(events[0].endMinute, 20)
    }

    func testISODateRangeBanner() {
        let fixture = """
Algorithms | CS 4104 Section 01
Registered
2026-08-24 -- 2026-12-11
Monday
   10:00 AM - 11:15 AM Type: Class Location: Main Campus Building: McBryde Room: 100
Instructor: Test, Prof (Primary)
CRN: 33333
"""
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: nil)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].weekdays, Set([2]))
        XCTAssertTrue(events[0].title.contains("Algorithms") || events[0].title.contains("4104"))
        XCTAssertTrue(events[0].notes.contains("33333"))
    }

    func testTTHBundle() {
        let fixture = "21905 MUS 3064 Digital Sound Manipulation 9:30 AM - 10:45 AM TTH LIBR 121"
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].weekdays, Set([3, 5]))
    }
}
