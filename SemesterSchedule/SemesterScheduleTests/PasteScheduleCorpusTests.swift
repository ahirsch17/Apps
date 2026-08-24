import XCTest
@testable import SemesterSchedule

/// Corpus of registrar-style copy-pastes: several majors, messy layout variants,
/// and a couple of table-style pastes. Asserts meetings, CRNs, days, and times.
final class PasteScheduleCorpusTests: XCTestCase {

    private enum WD: Int {
        case sun = 1, mon = 2, tue = 3, wed = 4, thu = 5, fri = 6, sat = 7
    }

    private func parse(_ text: String) -> [EditableScheduleEvent] {
        ScheduleTextParser.parse(text, defaultSemesterEnd: nil)
    }

    private func withCRN(_ events: [EditableScheduleEvent], _ crn: String) -> [EditableScheduleEvent] {
        events.filter { $0.notes.contains(crn) }
    }

    private func widget() -> String {
        ["S", "M", "T", "W", "T", "F", "S"].map { "    •    \($0)" }.joined(separator: "\n")
    }

    private func meeting(
        dates: String = "08/24/2026 -- 12/11/2026",
        day: String,
        time: String,
        type: String,
        location: String,
        building: String,
        room: String
    ) -> String {
        """
        \(dates)
        \(day)
        \(widget())
           \(time) Type: \(type) Location: \(location) Building: \(building) Room: \(room)
        """
    }

    // MARK: - Computer science / math / comm

    func testCorpus_computerScienceBannerPortal() {
        let paste = """
        Introduction to Programming | CS 1114 Section 01 | Class Begin: 08/24/2026 | Class End: 12/11/2026
        Registered
        \(meeting(day: "Monday", time: "10:00 AM - 10:50 AM", type: "Class", location: "Blacksburg", building: "McBryde Hall", room: "129"))
        \(meeting(day: "Wednesday", time: "10:00 AM - 10:50 AM", type: "Class", location: "Blacksburg", building: "McBryde Hall", room: "129"))
        \(meeting(day: "Friday", time: "10:00 AM - 10:50 AM", type: "Class", location: "Blacksburg", building: "McBryde Hall", room: "129"))
        Instructor: Nguyen, Linh (Primary)
        CRN: 15201
        Data Structures | CS 2114 Section 03 | Class Begin: 08/24/2026 | Class End: 12/11/2026
        Registered
        \(meeting(day: "Tuesday", time: "12:30 PM - 01:45 PM", type: "Class", location: "Blacksburg", building: "Goodwin Hall", room: "135"))
        \(meeting(day: "Thursday", time: "12:30 PM - 01:45 PM", type: "Class", location: "Blacksburg", building: "Goodwin Hall", room: "135"))
        \(meeting(day: "Wednesday", time: "02:00 PM - 03:50 PM", type: "Lab", location: "Blacksburg", building: "Torgersen Hall", room: "1120"))
        Instructor: Patel, Ravi (Primary)
        CRN: 15288
        Introduction to Linear Algebra | MATH 2114 Section 02
        Registered
        \(meeting(day: "Monday", time: "09:00 AM - 09:50 AM", type: "Class", location: "Blacksburg", building: "McBryde Hall", room: "100"))
        \(meeting(day: "Wednesday", time: "09:00 AM - 09:50 AM", type: "Class", location: "Blacksburg", building: "McBryde Hall", room: "100"))
        \(meeting(day: "Friday", time: "09:00 AM - 09:50 AM", type: "Class", location: "Blacksburg", building: "McBryde Hall", room: "100"))
        Instructor: Cho, Min (Primary)
        CRN: 14820
        Public Speaking | COMM 2004 Section 08
        Registered
        \(meeting(day: "Tuesday", time: "06:00 PM - 08:50 PM", type: "Class", location: "Blacksburg", building: "Shanks Hall", room: "160"))
        Instructor: Brooks, Elena (Primary)
        CRN: 16011
        """

        let events = parse(paste)
        XCTAssertEqual(events.count, 10)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 4)

        let intro = withCRN(events, "15201")
        XCTAssertEqual(intro.count, 3)
        XCTAssertTrue(intro.allSatisfy { $0.title.contains("Introduction to Programming") && $0.title.contains("1114") })
        XCTAssertEqual(Set(intro.flatMap(\.weekdays)), Set([WD.mon.rawValue, WD.wed.rawValue, WD.fri.rawValue]))
        XCTAssertTrue(intro.allSatisfy { $0.startHour == 10 && $0.endMinute == 50 })
        XCTAssertTrue(intro.first?.location.contains("McBryde") == true)
        XCTAssertTrue(intro.first?.notes.contains("Nguyen, Linh") == true)

        let ds = withCRN(events, "15288")
        XCTAssertEqual(ds.count, 3)
        XCTAssertTrue(ds.contains { $0.weekdays == Set([WD.tue.rawValue]) && $0.sessionKind == "Class" && $0.startHour == 12 && $0.startMinute == 30 })
        XCTAssertTrue(ds.contains { $0.weekdays == Set([WD.thu.rawValue]) && $0.endHour == 13 && $0.endMinute == 45 })
        XCTAssertTrue(ds.contains { $0.weekdays == Set([WD.wed.rawValue]) && $0.sessionKind == "Lab" && $0.startHour == 14 && $0.location.contains("Torgersen") })

        let math = withCRN(events, "14820")
        XCTAssertEqual(math.count, 3)
        XCTAssertTrue(math.allSatisfy { $0.startHour == 9 && $0.endHour == 9 && $0.endMinute == 50 })

        let speak = withCRN(events, "16011")
        XCTAssertEqual(speak.count, 1)
        XCTAssertEqual(speak.first?.weekdays, Set([WD.tue.rawValue]))
        XCTAssertEqual(speak.first?.startHour, 18)
        XCTAssertEqual(speak.first?.endHour, 20)
        XCTAssertEqual(speak.first?.endMinute, 50)
    }

    // MARK: - Humanities

    func testCorpus_humanitiesBannerPortal() {
        let paste = """
        United States History | HIST 1115 Section 01 | Registered
        \(meeting(day: "Monday", time: "11:00 AM - 12:15 PM", type: "Lecture", location: "Campus", building: "Major Williams", room: "220"))
        \(meeting(day: "Wednesday", time: "11:00 AM - 12:15 PM", type: "Lecture", location: "Campus", building: "Major Williams", room: "220"))
        Instructor: Alvarez, Sofia (Primary)
        CRN: 17110
        First-Year Writing | ENGL 1106 Section 22
        Status: Enrolled
        \(meeting(day: "Tuesday", time: "09:30 AM - 10:45 AM", type: "Class", location: "Campus", building: "Shanks Hall", room: "370"))
        \(meeting(day: "Thursday", time: "09:30 AM - 10:45 AM", type: "Class", location: "Campus", building: "Shanks Hall", room: "370"))
        Instructor: Reed, Jordan (Primary)
        CRN: 17144
        Elementary Spanish | SPAN 1106 Section 04
        Registered
        \(meeting(day: "Monday", time: "01:00 PM - 01:50 PM", type: "Class", location: "Campus", building: "Newman Hall", room: "12"))
        \(meeting(day: "Wednesday", time: "01:00 PM - 01:50 PM", type: "Class", location: "Campus", building: "Newman Hall", room: "12"))
        \(meeting(day: "Friday", time: "01:00 PM - 01:50 PM", type: "Class", location: "Campus", building: "Newman Hall", room: "12"))
        Instructor: Vargas, Diego (Primary)
        CRN: 17202
        """

        let events = parse(paste)
        XCTAssertEqual(events.count, 7)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 3)
        XCTAssertTrue(withCRN(events, "17110").allSatisfy { $0.sessionKind == "Lecture" })
        XCTAssertEqual(Set(withCRN(events, "17144").flatMap(\.weekdays)), Set([WD.tue.rawValue, WD.thu.rawValue]))
        XCTAssertTrue(withCRN(events, "17202").allSatisfy { $0.startHour == 13 })
        XCTAssertFalse(events.contains { $0.title.localizedCaseInsensitiveContains("Registered") })
        XCTAssertFalse(events.contains { $0.title.localizedCaseInsensitiveContains("Enrolled") })
    }

    // MARK: - Community college + clinical Saturday + dropped

    func testCorpus_communityCollege_droppedSkipped_saturdayClinicalKept() {
        let paste = """
        Composition I | ENGL 101 Section 01W | Registered
        \(meeting(day: "Tuesday", time: "08:00 AM - 09:15 AM", type: "Class", location: "Main", building: "Humanities", room: "204"))
        \(meeting(day: "Thursday", time: "08:00 AM - 09:15 AM", type: "Class", location: "Main", building: "Humanities", room: "204"))
        Instructor: Hall, Priya (Primary)
        CRN: 33001
        College Algebra | MATH 121 Section 03
        Registered
        \(meeting(day: "Monday", time: "10:00 AM - 10:50 AM", type: "Class", location: "Main", building: "Science Annex", room: "18"))
        \(meeting(day: "Wednesday", time: "10:00 AM - 10:50 AM", type: "Class", location: "Main", building: "Science Annex", room: "18"))
        \(meeting(day: "Friday", time: "10:00 AM - 10:50 AM", type: "Class", location: "Main", building: "Science Annex", room: "18"))
        Instructor: Okonkwo, Chidi (Primary)
        CRN: 33040
        Intro to Psychology | PSYC 200 Section 02
        Registered
        \(meeting(day: "Monday", time: "02:00 PM - 03:15 PM", type: "Class", location: "Main", building: "Social Sciences", room: "101"))
        \(meeting(day: "Wednesday", time: "02:00 PM - 03:15 PM", type: "Class", location: "Main", building: "Social Sciences", room: "101"))
        Instructor: Bennett, Claire (Primary)
        CRN: 33112
        Clinical Practicum | NURS 210 Section 01
        Registered
        \(meeting(day: "Saturday", time: "07:00 AM - 03:00 PM", type: "Clinical", location: "Hospital", building: "Memorial", room: "Floor 3"))
        Instructor: Singh, Amrita (Primary)
        CRN: 33990
        General Biology | BIOL 101 Section 01 | Dropped
        \(meeting(day: "Friday", time: "01:00 PM - 02:50 PM", type: "Lab", location: "Main", building: "Science", room: "12"))
        Instructor: Staff, Biology (Primary)
        CRN: 33800
        """

        let events = parse(paste)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 4)
        XCTAssertTrue(withCRN(events, "33800").isEmpty, "Dropped courses must not become calendar rows")
        XCTAssertFalse(events.contains { $0.title.contains("General Biology") })

        let clinical = withCRN(events, "33990")
        XCTAssertEqual(clinical.count, 1)
        XCTAssertEqual(clinical.first?.weekdays, Set([WD.sat.rawValue]))
        XCTAssertEqual(clinical.first?.startHour, 7)
        XCTAssertEqual(clinical.first?.endHour, 15)
        XCTAssertEqual(clinical.first?.sessionKind, "Clinical")
        XCTAssertTrue(clinical.first?.location.contains("Memorial") == true)
    }

    // MARK: - Layout variants from real portal copies

    func testCorpus_layoutVariants_splitDetails_sectionCell_crnWithoutColon() {
        let paste = """
        Organic Chemistry | CHEM 2535 | Section 02
        Status: Registered
        08/24/2026 – 12/11/2026
        Monday
        • S • M • T • W • T • F • S
        9:00AM - 9:50AM
        Type: Lecture Location:Campus Building: Hahn Hall Room: 110
        Instructor: Kim, Hana (mailto:hana.kim@school.edu) (Primary)
        CRN 20441
        Organic Chemistry Laboratory | CHEM 2545 Section 06 | Waitlisted
        08/24/2026 to 12/11/2026
        Thursday
        \(widget())
           01:00 PM - 03:50PM Type: Laboratory Location: Campus Building: Hahn Hall North Room: 21
        Instructor: Kim, Hana (Primary)
        CRN: 20458.
        """

        let events = parse(paste)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 2)

        let lecture = withCRN(events, "20441").first
        XCTAssertNotNil(lecture)
        XCTAssertTrue(lecture!.title.contains("Organic Chemistry"))
        XCTAssertTrue(lecture!.title.contains("2535"))
        XCTAssertTrue(lecture!.title.contains("Section 02"))
        XCTAssertEqual(lecture!.weekdays, Set([WD.mon.rawValue]))
        XCTAssertEqual(lecture!.startHour, 9)
        XCTAssertEqual(lecture!.endHour, 9)
        XCTAssertEqual(lecture!.endMinute, 50)
        XCTAssertEqual(lecture!.sessionKind, "Lecture")
        XCTAssertTrue(lecture!.location.contains("Hahn Hall"))
        XCTAssertTrue(lecture!.location.contains("110"))
        XCTAssertTrue(lecture!.notes.contains("Kim, Hana"))
        XCTAssertFalse(lecture!.notes.localizedCaseInsensitiveContains("mailto"))

        let lab = withCRN(events, "20458").first
        XCTAssertNotNil(lab)
        XCTAssertEqual(lab!.weekdays, Set([WD.thu.rawValue]))
        XCTAssertEqual(lab!.startHour, 13)
        XCTAssertEqual(lab!.endHour, 15)
        XCTAssertEqual(lab!.endMinute, 50)
        XCTAssertEqual(lab!.sessionKind, "Laboratory")
        XCTAssertTrue(lab!.title.contains("Waitlisted") == false)
    }

    func testCorpus_monthNames_online_hourWithoutMinutes_tbaSkipped() {
        let paste = """
        Statistics Online | STAT 2004 Section 01 | Registered
        August 24, 2026 -- December 11, 2026
        Wednesday
        \(widget())
           11 AM - 12 PM Type: Class Location: Online Building: WEB Room: None
        Instructor: Cole, Aaron (Primary)
        CRN: 18801
        Research Seminar | STAT 4004 Section 01
        Registered
        08/24/2026 -- 12/11/2026
        Friday
        \(widget())
           TBA Type: Class Location: Online Building: WEB Room: None
        Instructor: Cole, Aaron (Primary)
        CRN: 18840
        """

        let events = parse(paste)
        XCTAssertEqual(withCRN(events, "18801").count, 1)
        let online = withCRN(events, "18801").first!
        XCTAssertEqual(online.weekdays, Set([WD.wed.rawValue]))
        XCTAssertEqual(online.startHour, 11)
        XCTAssertEqual(online.endHour, 12)
        XCTAssertTrue(online.location.localizedCaseInsensitiveContains("Online"))
        XCTAssertFalse(online.location.localizedCaseInsensitiveContains("None"))

        XCTAssertTrue(withCRN(events, "18840").isEmpty, "TBA clock times should not become calendar meetings")
    }

    func testCorpus_emailWrapperNoise_doesNotStealMeetings() {
        let paste = """
        Your student schedule
        From: registrar@college.edu
        To: student@college.edu

        Calculus I | MATH 140 Section 01 | Registered
        \(meeting(day: "Monday", time: "08:00 AM - 08:50 AM", type: "Class", location: "Campus", building: "King Hall", room: "120"))
        \(meeting(day: "Wednesday", time: "08:00 AM - 08:50 AM", type: "Class", location: "Campus", building: "King Hall", room: "120"))
        \(meeting(day: "Friday", time: "08:00 AM - 08:50 AM", type: "Class", location: "Campus", building: "King Hall", room: "120"))
        Instructor: Chen, Li (Primary)
        CRN: 84521
        """

        let events = parse(paste)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 1)
        XCTAssertTrue(events.allSatisfy { $0.title.contains("Calculus") })
        XCTAssertEqual(Set(events.flatMap(\.weekdays)), Set([WD.mon.rawValue, WD.wed.rawValue, WD.fri.rawValue]))
    }

    func testCorpus_widgetLettersAreNeverWeekdays() {
        let paste = """
        Night Studio | ART 120 Section 01
        Registered
        \(meeting(day: "Wednesday", time: "07:00 PM - 09:45 PM", type: "Studio", location: "Campus", building: "Art Center", room: "2"))
        Instructor: Moore, Tess (Primary)
        CRN: 41002
        """
        let events = parse(paste)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.weekdays, Set([WD.wed.rawValue]))
        XCTAssertEqual(events.first?.startHour, 19)
        XCTAssertEqual(events.first?.endHour, 21)
        XCTAssertEqual(events.first?.endMinute, 45)
        XCTAssertEqual(events.first?.sessionKind, "Studio")
    }

    func testCorpus_waitlistedCourseStillParses() {
        let paste = """
        Yoga I | PHED 100 Section 07 | Waitlisted
        \(meeting(day: "Friday", time: "12:00 PM - 12:50 PM", type: "Class", location: "Campus", building: "War Memorial Hall", room: "Gym"))
        Instructor: Diaz, Marco (Primary)
        CRN: 19901
        """
        let events = parse(paste)
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events[0].title.contains("Yoga"))
        XCTAssertEqual(events[0].weekdays, Set([WD.fri.rawValue]))
        XCTAssertFalse(events[0].title.localizedCaseInsensitiveContains("Waitlisted"))
    }

    func testCorpus_tableLikeSTEM_stillParses() {
        let paste = """
        15201 CS 1114 Introduction to Programming 10:00 AM - 10:50 AM MWF MCB 129
        15288 CS 2114 Data Structures 12:30 PM - 1:45 PM TR GOOD 135
        14820 MATH 2114 Linear Algebra 9:00 AM - 9:50 AM MWF MCB 100
        16011 COMM 2004 Public Speaking 6:00 PM - 8:50 PM T SHAN 160
        """
        let events = parse(paste)
        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(ScheduleTextParser.distinctRegisteredCourseCount(in: events), 4)
        XCTAssertEqual(withCRN(events, "15201").first?.weekdays, Set([WD.mon.rawValue, WD.wed.rawValue, WD.fri.rawValue]))
        XCTAssertEqual(withCRN(events, "15288").first?.weekdays, Set([WD.tue.rawValue, WD.thu.rawValue]))
        XCTAssertEqual(withCRN(events, "16011").first?.startHour, 18)
    }

    func testCorpus_emptyAndGarbageDoNotCrash() {
        XCTAssertTrue(parse("").isEmpty)
        XCTAssertTrue(parse("hello world\nnot a schedule").isEmpty)
        XCTAssertTrue(parse("CRN: 1\nType: Class\nSection").isEmpty)
    }
}
