import XCTest
@testable import SemesterSchedule

/// Golden tests for registrar table-style pastes (CRN + dept + course # + title + time + days + location).
final class TableLikePasteGoldenTests: XCTestCase {

    private static let semesterEnd: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        var c = DateComponents()
        c.year = 2026; c.month = 12; c.day = 11
        return cal.date(from: c)!
    }()

    /// Typical HTML table copy: one logical row per course (footer line ignored).
    private static let wrappedTableFixture = """
21905 MUS 3064 Digital Sound Manipulation 9:30 AM - 10:45 AM TR LIBR 121
22774 CS 4094 Computer Science Capstone 12:30 PM - 1:45 PM TR ONLINE
21937 CS 4944 Seminar 2:30 PM - 3:20 PM F MCB 100
Total Credits 10.00
"""

    /// TBA rows lack a clock range and are skipped by the table regex.
    private static let tbaRowFixture = """
10152 ACIS 1004 Accounting Foundations TBA TBA ONLINE
"""

    func testTableLike_parseProducesThreeRows() {
        let events = ScheduleTextParser.parse(Self.wrappedTableFixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 3)
    }

    func testTableLike_tbaRowDoesNotParse() {
        let events = ScheduleTextParser.parse(Self.tbaRowFixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertTrue(events.isEmpty)
    }

    func testTableLike_exportMatchesExpectedPayload() throws {
        let events = ScheduleTextParser.parse(Self.wrappedTableFixture, defaultSemesterEnd: Self.semesterEnd)
        let export = StructuredScheduleExportBuilder.build(
            events: events,
            student: nil,
            inputFormat: "table_like"
        )

        let expected = StructuredScheduleExport(
            inputFormat: "table_like",
            student: nil,
            enrollments: [
                StructuredScheduleEnrollment(
                    crn: "22774",
                    courseName: "Computer Science Capstone",
                    courseCode: "",
                    section: "",
                    dateStart: "08/11/2026",
                    dateEnd: "12/11/2026",
                    instructors: [],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Thursday", "Tuesday"],
                            startTime: "12:30 PM",
                            endTime: "01:45 PM",
                            type: nil,
                            location: "ONLINE",
                            building: nil,
                            room: nil
                        ),
                    ]
                ),
                StructuredScheduleEnrollment(
                    crn: "21905",
                    courseName: "Digital Sound Manipulation",
                    courseCode: "",
                    section: "",
                    dateStart: "08/11/2026",
                    dateEnd: "12/11/2026",
                    instructors: [],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Thursday", "Tuesday"],
                            startTime: "09:30 AM",
                            endTime: "10:45 AM",
                            type: nil,
                            location: "LIBR 121",
                            building: nil,
                            room: nil
                        ),
                    ]
                ),
                StructuredScheduleEnrollment(
                    crn: "21937",
                    courseName: "Seminar",
                    courseCode: "",
                    section: "",
                    dateStart: "08/11/2026",
                    dateEnd: "12/11/2026",
                    instructors: [],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Friday"],
                            startTime: "02:30 PM",
                            endTime: "03:20 PM",
                            type: nil,
                            location: "MCB 100",
                            building: nil,
                            room: nil
                        ),
                    ]
                ),
            ],
            parsingNotes: StructuredExportParsingNotes(
                enrollmentCount: 3,
                meetingPatternCount: 3,
                trickyCases: nil
            )
        )

        XCTAssertEqual(export, expected)

        let data = try StructuredScheduleExportBuilder.jsonData(from: export, prettyPrinted: false)
        let roundTrip = try JSONDecoder().decode(StructuredScheduleExport.self, from: data)
        XCTAssertEqual(roundTrip, expected)
    }

    func testTableLike_mwfAbbreviation() {
        let fixture = "22678 MATH 2114 Intro to Linear Algebra 9:00 AM - 9:50 AM MWF MCCH 311"
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].weekdays, Set([2, 4, 6])) // Mon, Wed, Fri
        XCTAssertEqual(events[0].startHour, 9)
        XCTAssertEqual(events[0].endMinute, 50)
        XCTAssertEqual(events[0].location, "MCCH 311")
    }

    func testTableLike_wrappedMultilineRow() {
        let fixture = """
21905 MUS 3064 Digital Sound Manipulation
9:30 AM - 10:45 AM TR LIBR 121
"""
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].title, "Digital Sound Manipulation")
        XCTAssertEqual(events[0].weekdays, Set([3, 5])) // TR = Tue + Thu
    }
}
