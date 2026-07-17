import Foundation

// MARK: - Virginia Tech–style tabular schedule export (JSON)
//
// Schema matches a common SIS email/table paste: CRN, course code, modality, title, grade option,
// credit hours, time, days, location, instructor, part of term, exam.

struct VTTabularExport: Codable, Equatable {
    var inputFormat: String
    var student: String?
    var enrollments: [VTTabularEnrollment]
    var parsingNotes: VTTabularParsingNotes?

    enum CodingKeys: String, CodingKey {
        case inputFormat = "input_format"
        case student
        case enrollments
        case parsingNotes = "_parsing_notes"
    }
}

struct VTTabularEnrollment: Codable, Equatable {
    var crn: String
    var courseName: String
    var courseCode: String
    var section: String?
    var gradeOption: String
    var creditHours: Int
    var modality: String
    var partOfTerm: String
    var exam: String
    var instructors: [String]
    var meetingPatterns: [VTTabularMeetingPattern]
}

struct VTTabularMeetingPattern: Codable, Equatable {
    var days: [String]
    var startTime: String?
    var endTime: String?
    var type: String
    var location: String?
    var building: String?
    var room: String?
}

struct VTTabularFormatSpecific: Codable, Equatable {
    var ignoreLines: [String]
    var columnOrder: [String]
    var rowStructure: String

    enum CodingKeys: String, CodingKey {
        case ignoreLines = "ignore_lines"
        case columnOrder = "column_order"
        case rowStructure = "row_structure"
    }
}

struct VTTabularParsingNotes: Codable, Equatable {
    var enrollmentCount: Int
    var meetingPatternCount: Int
    var formatSpecific: VTTabularFormatSpecific?
    var trickyCases: [StructuredParsingNote]?

    enum CodingKeys: String, CodingKey {
        case enrollmentCount = "enrollment_count"
        case meetingPatternCount = "meeting_pattern_count"
        case formatSpecific = "format_specific"
        case trickyCases = "tricky_cases"
    }
}

enum VTTabularExportBuilder {
    static let defaultInputFormatIdentifier = "vt_tabular"

    static let defaultFormatSpecific = VTTabularFormatSpecific(
        ignoreLines: [
            "Email header lines: '(No subject)', 'Summarize', sender name/email",
            "The column header row (CRN, Course, Modality, ...)",
            "'Total Credit Hours:' footer line",
        ],
        columnOrder: [
            "CRN", "Course", "Modality", "Title", "Grade Opt", "Credit Hrs", "Time", "Days",
            "Location", "Instructor", "Part of Term", "Exam",
        ],
        rowStructure: "Each data row is 12 tab/whitespace-separated tokens. CRN is always a pure integer. Rows where the first token is not an integer are header, footer, or noise — skip them."
    )

    static let defaultTrickyCases: [StructuredParsingNote] = [
        .init(
            field: "Days — TBA",
            note: "When Days column is 'TBA', set days to empty array []. Do NOT set to null or ['TBA']. There is simply no scheduled meeting day."
        ),
        .init(
            field: "Days — day code splitting",
            note: "TR means Tuesday + Thursday. MWF means Monday + Wednesday + Friday. These map to ONE meeting pattern with multiple days — not multiple patterns — because the time and location are identical. Full map: M=Monday, T=Tuesday, W=Wednesday, R=Thursday, F=Friday, S=Saturday."
        ),
        .init(
            field: "Time — TBA",
            note: "When Time column is 'TBA', set startTime and endTime to null."
        ),
        .init(
            field: "Location — ONLINE",
            note: "When Location column is 'ONLINE', set location='Online', building=null, room=null. Do not attempt to split 'ONLINE' into building+room."
        ),
        .init(
            field: "Location — room split",
            note: "For face-to-face locations like 'MCB 100' or 'LIBR 121', split on the LAST space: everything before = building abbreviation, last token = room number. Store the building abbreviation in both location and building fields since no full building name is given in this format."
        ),
        .init(
            field: "Modality → type mapping",
            note: "'Online: Asynchronous' → type='Online'. 'Online with Synchronous Mtgs.' → type='Online' (it still meets online even if synchronous). 'Face-to-Face Instruction' → type='Class'."
        ),
        .init(
            field: "section",
            note: "This format does not include a section number. Set section=null."
        ),
        .init(
            field: "instructor name format",
            note: "Names here are 'First M. Last' order (e.g. 'Jean M. Lacoste'). Store as-is; do not reformat to 'Last, First'."
        ),
    ]

    private static let clock: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let weekdayName: [Int: String] = [
        1: "Sunday", 2: "Monday", 3: "Tuesday", 4: "Wednesday",
        5: "Thursday", 6: "Friday", 7: "Saturday",
    ]

    static func build(
        from rows: [VTTabularParsedRow],
        student: String? = nil,
        inputFormat: String = defaultInputFormatIdentifier,
        trickyCases: [StructuredParsingNote]? = defaultTrickyCases,
        formatSpecific: VTTabularFormatSpecific? = defaultFormatSpecific
    ) -> VTTabularExport {
        let enrollments = rows.map { row -> VTTabularEnrollment in
            let pattern = meetingPattern(from: row)
            return VTTabularEnrollment(
                crn: row.crn,
                courseName: row.title,
                courseCode: row.courseCode,
                section: nil,
                gradeOption: row.gradeOption,
                creditHours: row.creditHoursInt,
                modality: row.modality,
                partOfTerm: row.partOfTerm,
                exam: row.exam,
                instructors: [row.instructor],
                meetingPatterns: [pattern]
            )
        }

        let notes = VTTabularParsingNotes(
            enrollmentCount: enrollments.count,
            meetingPatternCount: enrollments.count,
            formatSpecific: formatSpecific,
            trickyCases: trickyCases
        )

        return VTTabularExport(
            inputFormat: inputFormat,
            student: student,
            enrollments: enrollments,
            parsingNotes: notes
        )
    }

    static func jsonData(from export: VTTabularExport, prettyPrinted: Bool = true) throws -> Data {
        let enc = JSONEncoder()
        if prettyPrinted { enc.outputFormatting = [.prettyPrinted, .sortedKeys] }
        enc.dateEncodingStrategy = .deferredToDate
        return try enc.encode(export)
    }

    private static func meetingPattern(from row: VTTabularParsedRow) -> VTTabularMeetingPattern {
        let type = patternType(modality: row.modality)
        let loc = splitLocationToken(row.locationToken)
        let dayNames = row.weekdayNumbers.sorted().compactMap { weekdayName[$0] }

        if row.timeStart == nil || row.timeEnd == nil {
            return VTTabularMeetingPattern(
                days: dayNames,
                startTime: nil,
                endTime: nil,
                type: type,
                location: loc.location,
                building: loc.building,
                room: loc.room
            )
        }

        return VTTabularMeetingPattern(
            days: dayNames,
            startTime: formatClock(hour: row.timeStart!.hour, minute: row.timeStart!.minute),
            endTime: formatClock(hour: row.timeEnd!.hour, minute: row.timeEnd!.minute),
            type: type,
            location: loc.location,
            building: loc.building,
            room: loc.room
        )
    }

    private static func patternType(modality: String) -> String {
        let m = modality.trimmingCharacters(in: .whitespacesAndNewlines)
        if m.hasPrefix("Face-to-Face") { return "Class" }
        return "Online"
    }

    private static func splitLocationToken(_ raw: String) -> (location: String?, building: String?, room: String?) {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return (nil, nil, nil) }
        if t.uppercased() == "ONLINE" { return ("Online", nil, nil) }
        if let r = t.lastIndex(of: " ") {
            let b = String(t[..<r]).trimmingCharacters(in: .whitespaces)
            let room = String(t[t.index(after: r)...]).trimmingCharacters(in: .whitespaces)
            if b.isEmpty { return (t, nil, nil) }
            return (b, b, room.isEmpty ? nil : room)
        }
        return (t, nil, nil)
    }

    private static func formatClock(hour: Int, minute: Int) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let base = cal.startOfDay(for: Date())
        guard let d = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) else { return "" }
        return clock.string(from: d)
    }
}
