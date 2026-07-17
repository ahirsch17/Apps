import XCTest
@testable import SemesterSchedule

/// Golden export for a real email-wrapped Banner vertical paste. Campus name appears only in **fixture text**
/// (as in the registrar), not in product identifiers.
final class VerticalPasteEmailWrapperGoldenTests: XCTestCase {

    private static let emailNoisePrefix = """
    schedule

    Summarize
    Jesus Jimenez-Chavez<jesusajimenez679@gmail.com>

    Hirsch, Alex

    """

    /// Registrar body copied from the user’s paste (including `Location: Radford` lines as printed).
    private static let registrarBody = #"""
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
   11:15 AM - 12:05PM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Knoeckel, Sarah (Primary)
Greene, Ellen
CRN: 11886
Foundations of Nursing Practice | Nursing 345 Section 05 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered
08/24/2026 -- 12/11/2026
Thursday
S
M
T
W
T
F
S
   08:00 AM - 12:00 PM Type: Lab Location:None Building: None Room: None
08/24/2026 -- 12/11/2026
Monday
S
M
T
W
T
F
S
   01:00 PM - 04:50PM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Haynes, Jayme (Primary)
Adkins, Megan
Levitt, Marie
Stevenson, Kimberly
Woods, Amy
CRN: 11966
Health Assessment Throughout the Lifespan | Nursing 340 Section 05 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered
08/24/2026 -- 12/11/2026
Friday
S
M
T
W
T
F
S
   09:00 AM - 11:00 AM Type: Lab Location:Radford Building: Center for the Sciences Room: M73
08/24/2026 -- 12/11/2026
Monday
S
M
T
W
T
F
S
   10:00 AM - 11:50AM Type: Class Location: Radford Building: Cook Hall Room: 107
Instructor: Sohrabi, Dommetae (Primary)
Coats, Louise
Harkonen, Kira
Katz, Katie
CRN: 11929
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
   08:00 AM - 10:50AM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Prucha, Anne (Primary)
CRN: 11902
Pharmacology | Nursing 368 Section 01 | Class Begin: 08/24/2026 | Class End: 12/11/2026
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
   11:15 AM - 12:05PM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Knoeckel, Sarah (Primary)
CRN: 12154
"""#

    private static let fullPaste = emailNoisePrefix + registrarBody

    private static let trickyCases: [StructuredParsingNote] = [
        .init(
            crn: "11966",
            note: "Two meeting patterns. After the Thursday lab time block closes, the next date range line '08/24/2026 -- 12/11/2026' followed by 'Monday' opens a SECOND pattern within the same enrollment. Do not start a new enrollment here — there is no new course title/pipe/section header."
        ),
        .init(
            crn: "11929",
            note: "Same structure as 11966. Friday lab and Monday class are both under 'Health Assessment Throughout the Lifespan'. The second date range + day name mid-block is the signal, not a new enrollment."
        ),
        .init(
            field: "endTime normalization",
            note: "Raw input has '12:05PM', '04:50PM', '11:50AM' with no space before AM/PM. Normalize all end times to include a space: '12:05 PM', '04:50 PM', '11:50 AM'."
        ),
        .init(
            field: "location None",
            note: "Raw input 'Location:None Building: None Room: None' (note no space after colon on Location). All three fields should be stored as null, not the string 'None'."
        ),
        .init(
            field: "instructors",
            note: "Strip '(Primary)' role tag — it is not part of any name. Names are in 'Last, First' format extracted from markdown links __[Last, First](mailto:...)__ or plain __[Last, First](url)__."
        ),
    ]

    func testEmailWrappedPaste_exportMatchesExpectedPayload() throws {
        let events = ScheduleTextParser.parse(Self.fullPaste, defaultSemesterEnd: nil)
        XCTAssertEqual(events.count, 7)

        let export = StructuredScheduleExportBuilder.build(
            events: events,
            student: "Hirsch, Alex",
            inputFormat: "radford_vertical",
            trickyCases: Self.trickyCases
        )

        let expected = StructuredScheduleExport(
            inputFormat: "radford_vertical",
            student: "Hirsch, Alex",
            enrollments: [
                StructuredScheduleEnrollment(
                    crn: "11886",
                    courseName: "Dosage Calculations",
                    courseCode: "Nursing 301",
                    section: "01",
                    dateStart: "08/24/2026",
                    dateEnd: "12/11/2026",
                    instructors: ["Knoeckel, Sarah", "Greene, Ellen"],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Tuesday"],
                            startTime: "11:15 AM",
                            endTime: "12:05 PM",
                            type: "Class",
                            location: "Radford",
                            building: "Artis Center",
                            room: "310"
                        ),
                    ]
                ),
                StructuredScheduleEnrollment(
                    crn: "11966",
                    courseName: "Foundations of Nursing Practice",
                    courseCode: "Nursing 345",
                    section: "05",
                    dateStart: "08/24/2026",
                    dateEnd: "12/11/2026",
                    instructors: ["Haynes, Jayme", "Adkins, Megan", "Levitt, Marie", "Stevenson, Kimberly", "Woods, Amy"],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Thursday"],
                            startTime: "08:00 AM",
                            endTime: "12:00 PM",
                            type: "Lab",
                            location: nil,
                            building: nil,
                            room: nil
                        ),
                        StructuredMeetingPattern(
                            days: ["Monday"],
                            startTime: "01:00 PM",
                            endTime: "04:50 PM",
                            type: "Class",
                            location: "Radford",
                            building: "Artis Center",
                            room: "310"
                        ),
                    ]
                ),
                StructuredScheduleEnrollment(
                    crn: "11929",
                    courseName: "Health Assessment Throughout the Lifespan",
                    courseCode: "Nursing 340",
                    section: "05",
                    dateStart: "08/24/2026",
                    dateEnd: "12/11/2026",
                    instructors: ["Sohrabi, Dommetae", "Coats, Louise", "Harkonen, Kira", "Katz, Katie"],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Friday"],
                            startTime: "09:00 AM",
                            endTime: "11:00 AM",
                            type: "Lab",
                            location: "Radford",
                            building: "Center for the Sciences",
                            room: "M73"
                        ),
                        StructuredMeetingPattern(
                            days: ["Monday"],
                            startTime: "10:00 AM",
                            endTime: "11:50 AM",
                            type: "Class",
                            location: "Radford",
                            building: "Cook Hall",
                            room: "107"
                        ),
                    ]
                ),
                StructuredScheduleEnrollment(
                    crn: "11902",
                    courseName: "Pathophysiology",
                    courseCode: "Nursing 321",
                    section: "01",
                    dateStart: "08/24/2026",
                    dateEnd: "12/11/2026",
                    instructors: ["Prucha, Anne"],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Tuesday"],
                            startTime: "08:00 AM",
                            endTime: "10:50 AM",
                            type: "Class",
                            location: "Radford",
                            building: "Artis Center",
                            room: "310"
                        ),
                    ]
                ),
                StructuredScheduleEnrollment(
                    crn: "12154",
                    courseName: "Pharmacology",
                    courseCode: "Nursing 368",
                    section: "01",
                    dateStart: "08/24/2026",
                    dateEnd: "12/11/2026",
                    instructors: ["Knoeckel, Sarah"],
                    meetingPatterns: [
                        StructuredMeetingPattern(
                            days: ["Tuesday"],
                            startTime: "11:15 AM",
                            endTime: "12:05 PM",
                            type: "Class",
                            location: "Radford",
                            building: "Artis Center",
                            room: "310"
                        ),
                    ]
                ),
            ],
            parsingNotes: StructuredExportParsingNotes(
                enrollmentCount: 5,
                meetingPatternCount: 7,
                trickyCases: Self.trickyCases
            )
        )

        XCTAssertEqual(export, expected)

        let data = try StructuredScheduleExportBuilder.jsonData(from: export, prettyPrinted: false)
        let roundTrip = try JSONDecoder().decode(StructuredScheduleExport.self, from: data)
        XCTAssertEqual(roundTrip, expected)
    }
}
