import XCTest
@testable import SemesterSchedule

final class VTTabularPasteGoldenTests: XCTestCase {

    /// Canonical 12-column tab-separated rows (header + 5 courses).
    private static let tabularFixture = """
CRN\tCourse\tModality\tTitle\tGrade Opt\tCredit Hrs\tTime\tDays\tLocation\tInstructor\tPart of Term\tExam
10152\tACIS 1004\tOnline: Asynchronous\tAccounting Foundations\tA - F\t3.00\tTBA\tTBA\tONLINE\tJean M. Lacoste\tE\t00X
21977\tCS 3714\tOnline: Asynchronous\tMobile Software Development\tA - F\t3.00\tTBA\tTBA\tONLINE\tKenneth R. Edmison\tE\t00X
22774\tCS 4094\tOnline with Synchronous Mtgs.\tComputer Science Capstone\tA - F\t3.00\t12:30 PM - 1:45 PM\tTR\tONLINE\tSehrish Basir Nizamani\tE\t12T
21937\tCS 4944\tFace-to-Face Instruction\tSeminar\tPass/Fail\t1.00\t2:30 PM - 3:20 PM\tF\tMCB 100\tStephen H. Edwards\t1\t14F
21905\tMUS 3064\tFace-to-Face Instruction\tDigital Sound Manipulation\tA - F\t3.00\t9:30 AM - 10:45 AM\tTR\tLIBR 121\tJustin A. Kerobo\t1\t09T
"""

    func testVtTabular_parseProducesFiveRows() {
        let rows = VTTabularScheduleParser.parse(Self.tabularFixture)!
        XCTAssertEqual(rows.count, 5)
        XCTAssertEqual(rows.map(\.crn), ["10152", "21977", "22774", "21937", "21905"])
    }

    func testVtTabular_exportMatchesExpectedJSONContract() throws {
        let rows = VTTabularScheduleParser.parse(Self.tabularFixture)!
        let export = VTTabularExportBuilder.build(from: rows, student: "Hirsch, Alex")

        let expected = VTTabularExport(
            inputFormat: "vt_tabular",
            student: "Hirsch, Alex",
            enrollments: [
                VTTabularEnrollment(
                    crn: "10152",
                    courseName: "Accounting Foundations",
                    courseCode: "ACIS 1004",
                    section: nil,
                    gradeOption: "A - F",
                    creditHours: 3,
                    modality: "Online: Asynchronous",
                    partOfTerm: "E",
                    exam: "00X",
                    instructors: ["Jean M. Lacoste"],
                    meetingPatterns: [
                        VTTabularMeetingPattern(
                            days: [],
                            startTime: nil,
                            endTime: nil,
                            type: "Online",
                            location: "Online",
                            building: nil,
                            room: nil
                        ),
                    ]
                ),
                VTTabularEnrollment(
                    crn: "21977",
                    courseName: "Mobile Software Development",
                    courseCode: "CS 3714",
                    section: nil,
                    gradeOption: "A - F",
                    creditHours: 3,
                    modality: "Online: Asynchronous",
                    partOfTerm: "E",
                    exam: "00X",
                    instructors: ["Kenneth R. Edmison"],
                    meetingPatterns: [
                        VTTabularMeetingPattern(
                            days: [],
                            startTime: nil,
                            endTime: nil,
                            type: "Online",
                            location: "Online",
                            building: nil,
                            room: nil
                        ),
                    ]
                ),
                VTTabularEnrollment(
                    crn: "22774",
                    courseName: "Computer Science Capstone",
                    courseCode: "CS 4094",
                    section: nil,
                    gradeOption: "A - F",
                    creditHours: 3,
                    modality: "Online with Synchronous Mtgs.",
                    partOfTerm: "E",
                    exam: "12T",
                    instructors: ["Sehrish Basir Nizamani"],
                    meetingPatterns: [
                        VTTabularMeetingPattern(
                            days: ["Tuesday", "Thursday"],
                            startTime: "12:30 PM",
                            endTime: "1:45 PM",
                            type: "Online",
                            location: "Online",
                            building: nil,
                            room: nil
                        ),
                    ]
                ),
                VTTabularEnrollment(
                    crn: "21937",
                    courseName: "Seminar",
                    courseCode: "CS 4944",
                    section: nil,
                    gradeOption: "Pass/Fail",
                    creditHours: 1,
                    modality: "Face-to-Face Instruction",
                    partOfTerm: "1",
                    exam: "14F",
                    instructors: ["Stephen H. Edwards"],
                    meetingPatterns: [
                        VTTabularMeetingPattern(
                            days: ["Friday"],
                            startTime: "2:30 PM",
                            endTime: "3:20 PM",
                            type: "Class",
                            location: "MCB",
                            building: "MCB",
                            room: "100"
                        ),
                    ]
                ),
                VTTabularEnrollment(
                    crn: "21905",
                    courseName: "Digital Sound Manipulation",
                    courseCode: "MUS 3064",
                    section: nil,
                    gradeOption: "A - F",
                    creditHours: 3,
                    modality: "Face-to-Face Instruction",
                    partOfTerm: "1",
                    exam: "09T",
                    instructors: ["Justin A. Kerobo"],
                    meetingPatterns: [
                        VTTabularMeetingPattern(
                            days: ["Tuesday", "Thursday"],
                            startTime: "9:30 AM",
                            endTime: "10:45 AM",
                            type: "Class",
                            location: "LIBR",
                            building: "LIBR",
                            room: "121"
                        ),
                    ]
                ),
            ],
            parsingNotes: VTTabularParsingNotes(
                enrollmentCount: 5,
                meetingPatternCount: 5,
                formatSpecific: VTTabularExportBuilder.defaultFormatSpecific,
                trickyCases: VTTabularExportBuilder.defaultTrickyCases
            )
        )

        XCTAssertEqual(export.inputFormat, expected.inputFormat)
        XCTAssertEqual(export.student, expected.student)
        XCTAssertEqual(export.enrollments, expected.enrollments)
        XCTAssertEqual(export.parsingNotes?.enrollmentCount, expected.parsingNotes?.enrollmentCount)
        XCTAssertEqual(export.parsingNotes?.meetingPatternCount, expected.parsingNotes?.meetingPatternCount)
        XCTAssertEqual(export.parsingNotes?.formatSpecific, expected.parsingNotes?.formatSpecific)
        XCTAssertEqual(export.parsingNotes?.trickyCases, expected.parsingNotes?.trickyCases)

        let data = try VTTabularExportBuilder.jsonData(from: export, prettyPrinted: false)
        let roundTrip = try JSONDecoder().decode(VTTabularExport.self, from: data)
        XCTAssertEqual(roundTrip.enrollments, expected.enrollments)
    }

    func testVtTabular_scheduleTextParserRoutesBeforeGrid() {
        let events = ScheduleTextParser.parse(Self.tabularFixture, defaultSemesterEnd: nil)
        XCTAssertEqual(events.count, 5)
        XCTAssertTrue(events.allSatisfy { $0.notes.contains("CRN") })
    }
}
