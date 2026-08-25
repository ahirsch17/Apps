import XCTest
@testable import SemesterSchedule

/// Golden test for a real student-portal copy-paste (Banner self-service layout).
/// Widget rows (`• S` … `• S`) are noise. Instructor `mailto:` wrappers are stripped,
/// but the email itself is kept on the calendar notes.
final class StudentPortalPasteGoldenTests: XCTestCase {

    private enum WD: Int { case mon = 2, tue = 3, thu = 5, fri = 6 }

    /// Exact registrar paste the user provided.
    static let portalPaste = #"""
Dosage Calculations | Nursing 301 Section 01 | Registered
08/24/2026 -- 12/11/2026
Tuesday
    •    S
    •    M
    •    T
    •    W
    •    T
    •    F
    •    S
   11:15 AM - 12:05PM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Knoeckel, Sarah (mailto:sarahknoeckel@gmail.com) (Primary)
CRN: 11886
Foundations of Nursing Practice | Nursing 345 Section 05 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered
08/24/2026 -- 12/11/2026
Thursday
    •    S
    •    M
    •    T
    •    W
    •    T
    •    F
    •    S
   08:00 AM - 12:00 PM Type: Lab Location:None Building: None Room: None
08/24/2026 -- 12/11/2026
Monday
    •    S
    •    M
    •    T
    •    W
    •    T
    •    F
    •    S
   01:00 PM - 04:50PM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Haynes, Jayme (Primary)
Adkins, Megan
Levitt, Marie (mailto:bmlevitt@radford.edu)
Stevenson, Kimberly (mailto:kstevenson4@radford.edu)
Woods, Amy (mailto:awoods@radford.edu)
CRN: 11966
Health Assessment Throughout the Lifespan | Nursing 340 Section 05 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered
08/24/2026 -- 12/11/2026
Friday
    •    S
    •    M
    •    T
    •    W
    •    T
    •    F
    •    S
   09:00 AM - 11:00 AM Type: Lab Location:Radford Building: Center for the Sciences Room: M73
08/24/2026 -- 12/11/2026
Monday
    •    S
    •    M
    •    T
    •    W
    •    T
    •    F
    •    S
   10:00 AM - 11:50AM Type: Class Location: Radford Building: Cook Hall Room: 107
Instructor: Sohrabi, Dommetae (mailto:dsohrabi@radford.edu) (Primary)
Coats, Louise (mailto:lcoats@radford.edu)
Harkonen, Kira
Katz, Katie (mailto:krkatz@radford.edu)
CRN: 11929
Pathophysiology | Nursing 321 Section 01 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered
08/24/2026 -- 12/11/2026
Tuesday
    •    S
    •    M
    •    T
    •    W
    •    T
    •    F
    •    S
   08:00 AM - 10:50AM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Prucha, Anne (mailto:aprucha@radford.edu) (Primary)
CRN: 11902
Pharmacology | Nursing 368 Section 01 | Class Begin: 08/24/2026 | Class End: 12/11/2026
Registered
08/24/2026 -- 12/11/2026
Tuesday
    •    S
    •    M
    •    T
    •    W
    •    T
    •    F
    •    S
   01:00 PM - 03:50PM Type: Class Location: Radford Building: Artis Center Room: 310
Instructor: Knoeckel, Sarah (mailto:sarahknoeckel@gmail.com) (Primary)
CRN: 12154
"""#

    func testPortalPaste_sevenMeetingsFiveCRNs() {
        let events = ScheduleTextParser.parse(Self.portalPaste, defaultSemesterEnd: nil)
        XCTAssertEqual(events.count, 7)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 5)
    }

    func testPortalPaste_dosage_registeredOnSameHeaderLine() {
        let events = ScheduleTextParser.parse(Self.portalPaste, defaultSemesterEnd: nil)
        let row = events.first { notes($0).contains("11886") }
        XCTAssertNotNil(row)
        XCTAssertTrue(row!.title.contains("Dosage Calculations"), row!.title)
        XCTAssertTrue(row!.title.contains("301"), row!.title)
        XCTAssertEqual(row!.weekdays, Set([WD.tue.rawValue]))
        XCTAssertEqual(row!.startHour, 11)
        XCTAssertEqual(row!.startMinute, 15)
        XCTAssertEqual(row!.endHour, 12)
        XCTAssertEqual(row!.endMinute, 5)
        XCTAssertEqual(row!.sessionKind, "Class")
        XCTAssertTrue(row!.location.contains("Artis Center"), row!.location)
        XCTAssertTrue(row!.location.contains("310"), row!.location)
        XCTAssertTrue(notes(row!).contains("Knoeckel, Sarah"))
        XCTAssertTrue(notes(row!).contains("sarahknoeckel@gmail.com"))
        XCTAssertFalse(notes(row!).localizedCaseInsensitiveContains("mailto"))
        XCTAssertFalse(row!.title.localizedCaseInsensitiveContains("Registered"))
    }

    func testPortalPaste_foundations_twoMeetingsSameCRN() {
        let events = ScheduleTextParser.parse(Self.portalPaste, defaultSemesterEnd: nil)
        let rows = events.filter { notes($0).contains("11966") }
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows.allSatisfy { $0.title.contains("Foundations of Nursing Practice") })
        XCTAssertTrue(rows.contains { $0.weekdays == Set([WD.thu.rawValue]) && $0.sessionKind == "Lab" && $0.startHour == 8 })
        XCTAssertTrue(rows.contains { $0.weekdays == Set([WD.mon.rawValue]) && $0.sessionKind == "Class" && $0.startHour == 13 && $0.endHour == 16 && $0.endMinute == 50 })
        if let lab = rows.first(where: { $0.sessionKind == "Lab" }) {
            XCTAssertTrue(lab.location.trimmingCharacters(in: .whitespaces).isEmpty, "Location/Building/Room None should drop out; got \(lab.location)")
        }
    }

    func testPortalPaste_healthAssessment_labAndLecture() {
        let events = ScheduleTextParser.parse(Self.portalPaste, defaultSemesterEnd: nil)
        let rows = events.filter { notes($0).contains("11929") }
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows.contains {
            $0.weekdays == Set([WD.fri.rawValue]) && $0.sessionKind == "Lab" && $0.location.contains("Center for the Sciences") && $0.location.contains("M73")
        })
        XCTAssertTrue(rows.contains {
            $0.weekdays == Set([WD.mon.rawValue]) && $0.startHour == 10 && $0.endHour == 11 && $0.endMinute == 50 && $0.location.contains("Cook Hall")
        })
    }

    func testPortalPaste_pathophysiologyAndPharmacology_distinctTuesdayBlocks() {
        let events = ScheduleTextParser.parse(Self.portalPaste, defaultSemesterEnd: nil)
        let patho = events.first { notes($0).contains("11902") }
        let pharm = events.first { notes($0).contains("12154") }
        XCTAssertEqual(patho?.weekdays, Set([WD.tue.rawValue]))
        XCTAssertEqual(patho?.startHour, 8)
        XCTAssertEqual(patho?.endHour, 10)
        XCTAssertEqual(patho?.endMinute, 50)
        XCTAssertTrue(patho?.title.contains("Pathophysiology") == true)

        XCTAssertEqual(pharm?.weekdays, Set([WD.tue.rawValue]))
        XCTAssertEqual(pharm?.startHour, 13)
        XCTAssertEqual(pharm?.endHour, 15)
        XCTAssertEqual(pharm?.endMinute, 50)
        XCTAssertTrue(pharm?.title.contains("Pharmacology") == true, pharm?.title ?? "nil")
        XCTAssertTrue(pharm?.title.contains("368") == true)
    }

    func testPortalPaste_calendarWidgetLettersAreNotWeekdays() {
        let events = ScheduleTextParser.parse(Self.portalPaste, defaultSemesterEnd: nil)
        for event in events {
            XCTAssertEqual(event.weekdays.count, 1, "Widget S/M/T/W/F letters must not become extra meeting days: \(event.title) \(event.weekdays)")
        }
    }

    private func notes(_ e: EditableScheduleEvent) -> String { e.notes }
}
