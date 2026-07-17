import Foundation

// MARK: - Structured schedule export (JSON)
//
// School-agnostic schema: one enrollment per CRN (from parsed notes) with `meetingPatterns[]`
// for each calendar row. Values come from **parsed** `EditableScheduleEvent`s (titles and CRNs
// as read from the paste), not from an external catalog crosswalk.

struct StructuredScheduleExport: Codable, Equatable {
    var inputFormat: String
    var student: String?
    var enrollments: [StructuredScheduleEnrollment]
    var parsingNotes: StructuredExportParsingNotes?

    enum CodingKeys: String, CodingKey {
        case inputFormat = "input_format"
        case student
        case enrollments
        case parsingNotes = "_parsing_notes"
    }
}

struct StructuredScheduleEnrollment: Codable, Equatable {
    var crn: String
    var courseName: String
    var courseCode: String
    var section: String
    var dateStart: String
    var dateEnd: String
    var instructors: [String]
    var meetingPatterns: [StructuredMeetingPattern]
}

struct StructuredMeetingPattern: Codable, Equatable {
    var days: [String]
    var startTime: String
    var endTime: String
    var type: String?
    var location: String?
    var building: String?
    var room: String?
}

/// Optional human/LLM annotations for tricky vertical-paste cases (each entry has `note` plus either `crn` or `field`).
struct StructuredParsingNote: Codable, Equatable {
    var crn: String?
    var field: String?
    var note: String
}

struct StructuredExportParsingNotes: Codable, Equatable {
    var enrollmentCount: Int
    var meetingPatternCount: Int
    var trickyCases: [StructuredParsingNote]?

    enum CodingKeys: String, CodingKey {
        case enrollmentCount = "enrollment_count"
        case meetingPatternCount = "meeting_pattern_count"
        case trickyCases = "tricky_cases"
    }
}

enum StructuredScheduleExportBuilder {
    /// Default `input_format` when callers do not supply one — versioned, institution-neutral.
    static let defaultInputFormatIdentifier = "vertical_enrollment_v1"

    private static let notesCrn = try! NSRegularExpression(pattern: #"CRN\s*:?\s*(\d+)"#, options: .caseInsensitive)
    private static let catalogTail = try! NSRegularExpression(
        pattern: #"^(.+?)\s+Section\s+([^|\\s]+)"#,
        options: .caseInsensitive
    )

    private static let mdY: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "MM/dd/yyyy"
        return f
    }()

    private static let clock: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        // Two-digit hour so JSON matches common registrar exports (e.g. `08:00 AM`, not `8:00 AM`).
        f.dateFormat = "hh:mm a"
        return f
    }()

    private static let weekdayName: [Int: String] = [
        1: "Sunday", 2: "Monday", 3: "Tuesday", 4: "Wednesday",
        5: "Thursday", 6: "Friday", 7: "Saturday",
    ]

    /// Builds the export model from already-parsed events (e.g. `ScheduleTextParser.parse(...)`).
    /// - Parameters:
    ///   - trickyCases: Optional `_parsing_notes.tricky_cases` entries (caller-supplied; not inferred from the paste).
    static func build(
        events: [EditableScheduleEvent],
        student: String? = nil,
        inputFormat: String = defaultInputFormatIdentifier,
        trickyCases: [StructuredParsingNote]? = nil
    ) -> StructuredScheduleExport {
        var crnOrder: [String] = []
        var groups: [String: [EditableScheduleEvent]] = [:]
        for e in events {
            guard let c = crn(from: e.notes), c != "00000" else { continue }
            if groups[c] == nil {
                crnOrder.append(c)
                groups[c] = []
            }
            groups[c]?.append(e)
        }

        var enrollments: [StructuredScheduleEnrollment] = []
        for crn in crnOrder {
            guard let rows = groups[crn], let first = rows.first else { continue }
            let catalog = parseCatalogTitle(first.title)
            let name = catalog?.name ?? first.title
            let code = catalog?.code ?? ""
            let section = catalog?.section ?? ""

            let mergedInstructors = mergedInstructors(from: rows)

            let patterns = rows.map { ev -> StructuredMeetingPattern in
                let days = ev.weekdays.compactMap { weekdayName[$0] }.sorted()
                let locParts = splitLocation(ev.location)
                return StructuredMeetingPattern(
                    days: days,
                    startTime: formatClock(hour: ev.startHour, minute: ev.startMinute),
                    endTime: formatClock(hour: ev.endHour, minute: ev.endMinute),
                    type: ev.sessionKind,
                    location: locParts.location,
                    building: locParts.building,
                    room: locParts.room
                )
            }

            enrollments.append(
                StructuredScheduleEnrollment(
                    crn: crn,
                    courseName: name,
                    courseCode: code,
                    section: section,
                    dateStart: mdY.string(from: first.semesterStart),
                    dateEnd: mdY.string(from: first.semesterEnd),
                    instructors: mergedInstructors,
                    meetingPatterns: patterns
                )
            )
        }

        let notes = StructuredExportParsingNotes(
            enrollmentCount: enrollments.count,
            meetingPatternCount: events.count,
            trickyCases: trickyCases
        )

        return StructuredScheduleExport(
            inputFormat: inputFormat,
            student: student,
            enrollments: enrollments,
            parsingNotes: notes
        )
    }

    static func jsonData(
        from export: StructuredScheduleExport,
        prettyPrinted: Bool = true
    ) throws -> Data {
        let enc = JSONEncoder()
        if prettyPrinted { enc.outputFormatting = [.prettyPrinted, .sortedKeys] }
        enc.dateEncodingStrategy = .deferredToDate
        return try enc.encode(export)
    }

    // MARK: - Helpers

    private static func crn(from notes: String) -> String? {
        let range = NSRange(notes.startIndex ..< notes.endIndex, in: notes)
        guard let m = notesCrn.firstMatch(in: notes, options: [], range: range),
              m.numberOfRanges >= 2,
              let r = Range(m.range(at: 1), in: notes)
        else { return nil }
        return String(notes[r])
    }

    private static func parseCatalogTitle(_ full: String) -> (name: String, code: String, section: String)? {
        let t = full.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = t.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard parts.count >= 2 else { return nil }
        let name = parts[0]
        let tail = parts[1]
        let ns = tail as NSString
        guard let m = catalogTail.firstMatch(in: tail, options: [], range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 3,
              let r0 = Range(m.range(at: 1), in: tail),
              let r1 = Range(m.range(at: 2), in: tail)
        else { return (name, tail, "") }
        let code = String(tail[r0]).trimmingCharacters(in: .whitespaces)
        let section = String(tail[r1]).trimmingCharacters(in: .whitespaces)
        return (name, code, section)
    }

    private static func mergedInstructors(from rows: [EditableScheduleEvent]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for row in rows {
            for name in instructors(from: row.notes) {
                let key = name.lowercased()
                if seen.insert(key).inserted {
                    out.append(name)
                }
            }
        }
        return out
    }

    private static func instructors(from notes: String) -> [String] {
        var out: [String] = []
        for line in notes.split(separator: "\n") {
            let raw = line.trimmingCharacters(in: .whitespaces)
            if raw.lowercased().hasPrefix("crn") { continue }
            let stripped = raw
                .replacingOccurrences(of: "Instructor:", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            let noRole = stripped
                .replacingOccurrences(of: "(Primary)", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "(Secondary)", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            if noRole.isEmpty == false { out.append(noRole) }
        }
        return out
    }

    private static func formatClock(hour: Int, minute: Int) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let base = cal.startOfDay(for: Date())
        guard let d = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) else { return "" }
        return clock.string(from: d)
    }

    private static func splitLocation(_ joined: String) -> (location: String?, building: String?, room: String?) {
        let t = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return (nil, nil, nil) }
        let parts = t.split(separator: "·").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if parts.count >= 3 {
            return (parts[0], parts[1], parts[2])
        }
        if parts.count == 2 { return (parts[0], parts[1], nil) }
        return (parts[0], nil, nil)
    }
}
