import XCTest
@testable import SemesterSchedule

/// Golden tests for Mon–Sun schedule graph pastes (column-aligned CRN blocks).
final class WeeklyGridPasteGoldenTests: XCTestCase {

    private static let semesterEnd: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        var c = DateComponents()
        c.year = 2026; c.month = 12; c.day = 11
        return cal.date(from: c)!
    }()

    /// Two CRN blocks under a short weekday header row (indented Tuesday + Monday).
    private static let gridFixture = """
Mon       Tue       Wed       Thu       Fri       Sat       Sun
               CRN: 22774
               CS 4094
               Computer Science Capstone
               12:30 PM - 1:45 PM
               ONLINE
CRN: 21937
CS 4944
Seminar
2:30 PM - 3:20 PM
MCB 100
"""

    func testGrid_parseProducesTwoRows() {
        let events = ScheduleTextParser.parse(Self.gridFixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 2)
    }

    func testGrid_exportMatchesExpectedPayload() throws {
        let events = ScheduleTextParser.parse(Self.gridFixture, defaultSemesterEnd: Self.semesterEnd)
        let export = StructuredScheduleExportBuilder.build(
            events: events,
            student: nil,
            inputFormat: "weekly_grid"
        )

        let expected = StructuredScheduleExport(
            inputFormat: "weekly_grid",
            student: nil,
            enrollments: [
                StructuredScheduleEnrollment(
                    crn: "22774",
                    courseName: "Computer Science Capstone (CS 4094)",
                    courseCode: "",
                    section: "",
                    dateStart: "08/11/2026",
                    dateEnd: "12/11/2026",
                    instructors: [],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Tuesday"],
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
                    crn: "21937",
                    courseName: "Seminar (CS 4944)",
                    courseCode: "",
                    section: "",
                    dateStart: "08/11/2026",
                    dateEnd: "12/11/2026",
                    instructors: [],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Monday"],
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
                enrollmentCount: 2,
                meetingPatternCount: 2,
                trickyCases: nil
            )
        )

        XCTAssertEqual(export, expected)

        let data = try StructuredScheduleExportBuilder.jsonData(from: export, prettyPrinted: false)
        let roundTrip = try JSONDecoder().decode(StructuredScheduleExport.self, from: data)
        XCTAssertEqual(roundTrip, expected)
    }

    func testGrid_columnIndentMapsWeekdaysAndLocations() {
        let events = ScheduleTextParser.parse(Self.gridFixture, defaultSemesterEnd: Self.semesterEnd)
        let capstone = events.first { $0.notes.contains("22774") }
        let seminar = events.first { $0.notes.contains("21937") }
        XCTAssertEqual(capstone?.weekdays, Set([3]), "Indented CRN under Tue column")
        XCTAssertEqual(seminar?.weekdays, Set([2]), "Left-aligned CRN under Mon column")
        XCTAssertEqual(capstone?.location, "ONLINE")
        XCTAssertEqual(seminar?.location, "MCB 100")
    }

    func testGrid_titlesIncludeCourseCodes() {
        let events = ScheduleTextParser.parse(Self.gridFixture, defaultSemesterEnd: Self.semesterEnd)
        let capstone = events.first { $0.notes.contains("22774") }
        let seminar = events.first { $0.notes.contains("21937") }
        XCTAssertEqual(capstone?.title, "Computer Science Capstone (CS 4094)")
        XCTAssertEqual(seminar?.title, "Seminar (CS 4944)")
    }

    func testGrid_repeatedBlockWithoutDistinctColumnsClearsWeekdays() {
        /// Same CRN/title/time stacked with identical indent — user must pick days in the app.
        let fixture = """
Mon       Tue       Wed       Thu       Fri       Sat       Sun
CRN: 22774
CS 4094
Capstone
12:30 PM - 1:45 PM
CRN: 22774
CS 4094
Capstone
12:30 PM - 1:45 PM
"""
        let events = ScheduleTextParser.parse(fixture, defaultSemesterEnd: Self.semesterEnd)
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events[0].weekdays.isEmpty)
        XCTAssertTrue(events[0].notes.contains("Graph: repeated block"))
    }
}
