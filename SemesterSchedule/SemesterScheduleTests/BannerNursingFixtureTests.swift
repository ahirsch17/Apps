import XCTest
@testable import SemesterSchedule

/// Ground truth for the Banner “Nursing bundle” paste: **7 meetings**, **5 distinct CRNs**.
/// One enrollment can span multiple day+time rows before a single CRN + closing title.
final class BannerNursingFixtureTests: XCTestCase {

    /// Calendar weekday: 1 = Sunday … 7 = Saturday (matches `Calendar` / parser).
    private enum WD: Int {
        case mon = 2, tue = 3, thu = 5, fri = 6
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
   01:00 PM - 04:50PM Type: Class Location: Main Campus Building: Artis Center Room: 310
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
   09:00 AM - 11:00 AM Type: Lab Location:Main Campus Building: Center for the Sciences Room: M73
08/24/2026 -- 12/11/2026   
Monday
S
M
T
W
T
F
S
   10:00 AM - 11:50AM Type: Class Location: Main Campus Building: Cook Hall Room: 107
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
   08:00 AM - 10:50AM Type: Class Location: Main Campus Building: Artis Center Room: 310
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
   11:15 AM - 12:05PM Type: Class Location: Main Campus Building: Artis Center Room: 310
Instructor: Knoeckel, Sarah (Primary) 
CRN: 12154.
"""#

    func testNursingBanner_meetingAndClassCounts() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        XCTAssertEqual(events.count, 7, "Expected 7 calendar rows (lab/lecture splits + two Tue 11:15 courses).")
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 5, "Expected 5 distinct CRNs.")
    }

    func testNursingBanner_firstBlock_dosageLeadOverridesClosingTitle() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let first = events.first { notes($0).contains("11886") && $0.weekdays == Set([WD.tue.rawValue]) }
        XCTAssertNotNil(first)
        XCTAssertTrue(
            first!.title.contains("Dosage"),
            "Lead line before Registered must title the Tuesday 11:15 / CRN 11886 row; got: \(first!.title)"
        )
        XCTAssertTrue(first!.title.contains("301"), first!.title)
        XCTAssertEqual(first!.startHour, 11)
        XCTAssertEqual(first!.startMinute, 15)
        XCTAssertEqual(first!.endHour, 12)
        XCTAssertEqual(first!.endMinute, 5)
    }

    func testNursingBanner_foundationsOfNursing_twoMeetingsSameCRN() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let rows = events.filter { notes($0).contains("11966") }
        XCTAssertEqual(rows.count, 2, "Foundations: Thursday lab + Monday lecture.")
        for r in rows {
            XCTAssertTrue(r.title.contains("Foundations of Nursing Practice"), r.title)
            XCTAssertTrue(r.title.contains("345"), r.title)
        }
        XCTAssertTrue(rows.contains { $0.weekdays == Set([WD.thu.rawValue]) && $0.sessionKind == "Lab" })
        XCTAssertTrue(rows.contains { $0.weekdays == Set([WD.mon.rawValue]) && $0.startHour == 13 })
    }

    func testNursingBanner_healthAssessment_twoMeetingsSameCRN() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let rows = events.filter { notes($0).contains("11929") }
        XCTAssertEqual(rows.count, 2, "Health Assessment: Friday lab + Monday lecture.")
        XCTAssertEqual(
            Set(rows.map(\.title)),
            ["Health Assessment Throughout the Lifespan | Nursing 340 Section 05"],
            "Title comes from the catalog line above Registered (Class Begin suffix optional)."
        )
        XCTAssertTrue(rows.contains { $0.weekdays == Set([WD.fri.rawValue]) && $0.sessionKind == "Lab" })
        XCTAssertTrue(rows.contains { $0.weekdays == Set([WD.mon.rawValue]) && $0.startHour == 10 })
    }

    func testNursingBanner_pathophysiology_singleMeeting() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let rows = events.filter { notes($0).contains("11902") }
        XCTAssertEqual(rows.count, 1)
        XCTAssertTrue(rows[0].title.contains("Pathophysiology"))
        XCTAssertTrue(rows[0].title.contains("321"), rows[0].title)
        XCTAssertEqual(rows[0].weekdays, Set([WD.tue.rawValue]))
        XCTAssertEqual(rows[0].startHour, 8)
        XCTAssertEqual(rows[0].endHour, 10)
        XCTAssertEqual(rows[0].endMinute, 50)
    }

    func testNursingBanner_secondTuesdaySlot_crn12154_pharmacology() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let last = events.filter { notes($0).contains("12154") }
        XCTAssertEqual(last.count, 1, "Second Tuesday 11:15 block is its own CRN.")
        let row = last[0]
        XCTAssertEqual(row.weekdays, Set([WD.tue.rawValue]))
        XCTAssertEqual(row.startHour, 11)
        XCTAssertEqual(row.startMinute, 15)
        XCTAssertEqual(row.endHour, 12)
        XCTAssertEqual(row.endMinute, 5)
        XCTAssertTrue(row.title.contains("Pharmacology"), "Catalog line above Registered titles this block; got: \(row.title)")
        XCTAssertTrue(row.title.contains("368"), row.title)
    }

    func testNursingBanner_noDuplicatePathophysiologyTitlesWrongCRN() {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let pathTitles = events.filter { $0.title.contains("Pathophysiology") }
        XCTAssertEqual(pathTitles.count, 1, "Single Pathophysiology row; title must not leak onto other CRNs.")
        XCTAssertTrue(pathTitles.allSatisfy { notes($0).contains("11902") })
    }

    func testNursingBanner_structuredExport_matchesFixtureCRNs() throws {
        let events = ScheduleTextParser.parse(Self.nursingBannerFixture, defaultSemesterEnd: nil)
        let export = StructuredScheduleExportBuilder.build(events: events, student: nil)
        XCTAssertEqual(export.inputFormat, StructuredScheduleExportBuilder.defaultInputFormatIdentifier)
        XCTAssertEqual(export.parsingNotes?.enrollmentCount, 5)
        XCTAssertEqual(export.parsingNotes?.meetingPatternCount, 7)
        let byCRN = Dictionary(uniqueKeysWithValues: export.enrollments.map { ($0.crn, $0) })
        XCTAssertTrue(byCRN["11886"]?.courseName.contains("Dosage") == true)
        XCTAssertTrue(byCRN["11966"]?.courseName.contains("Foundations") == true)
        XCTAssertTrue(byCRN["11929"]?.courseName.contains("Health Assessment") == true)
        XCTAssertTrue(byCRN["11902"]?.courseName.contains("Pathophysiology") == true)
        XCTAssertTrue(byCRN["12154"]?.courseName.contains("Pharmacology") == true)
        XCTAssertEqual(byCRN["11966"]?.meetingPatterns.count, 2)
        XCTAssertEqual(byCRN["11929"]?.meetingPatterns.count, 2)
        XCTAssertEqual(byCRN["11902"]?.meetingPatterns.count, 1)
        XCTAssertEqual(byCRN["12154"]?.meetingPatterns.count, 1)
        let lab11966 = byCRN["11966"]?.meetingPatterns.first { $0.type == "Lab" }
        XCTAssertEqual(lab11966?.location, nil)
        XCTAssertEqual(lab11966?.building, nil)
        XCTAssertEqual(lab11966?.room, nil)
        _ = try StructuredScheduleExportBuilder.jsonData(from: export, prettyPrinted: true)
    }

    private func notes(_ e: EditableScheduleEvent) -> String { e.notes }
}
