import Foundation

/// Parser for the Student Schedule page most US Banner / self-service portals print.
/// Same layout at many schools — not specific to one campus.
///
/// Read a real paste first, then match this layout:
///
/// 1. Course header: `Title | Subject 301 Section 01` plus optional `| Registered`
///    or `| Class Begin: … | Class End: …`. `Section` may be its own pipe cell.
/// 2. Optional status line: `Registered`, `Waitlisted`, `Status: Enrolled`, …
///    `Dropped` / `Withdrawn` enrollments are skipped.
/// 3. One or more meetings, each:
///    - date range `08/24/2026 -- 12/11/2026` (also `to`, en-dash, ISO, month names)
///    - full weekday name (`Tuesday`)
///    - ignored calendar widget (`S M T W T F S`, often with `•`)
///    - clock + details, together or on the next line:
///      `11:15 AM - 12:05PM Type: Class Location: Campus Building: Hall Room: 310`
/// 4. `Instructor:` plus extra `Last, First` lines (mailto and `(Primary)` are noise)
/// 5. `CRN: 11886` or `CRN 11886`
///
/// A second date range inside the same header is another meeting of the same class,
/// not a new course.
enum StudentPortalScheduleParser {
    static func looksLikePortalPaste(_ text: String) -> Bool {
        let lower = text.lowercased()
        guard lower.contains("crn") else { return false }
        guard lower.contains("type:") else { return false }
        guard lower.contains("section") else { return false }
        return true
    }

    static func parse(_ raw: String, defaultSemesterEnd: Date?) -> [EditableScheduleEvent] {
        let lines = normalize(raw)
        guard lines.isEmpty == false else { return [] }

        var enrollments: [Enrollment] = []
        var current: Enrollment?
        var openMeeting: MeetingDraft?

        func commitMeeting() {
            guard var enrollment = current else {
                openMeeting = nil
                return
            }
            if let meeting = openMeeting, meeting.isComplete {
                enrollment.meetings.append(meeting)
                current = enrollment
            }
            openMeeting = nil
        }

        func commitEnrollment() {
            commitMeeting()
            if let enrollment = current {
                enrollments.append(enrollment)
            }
            current = nil
        }

        for line in lines {
            if isCalendarWidgetLine(line) { continue }
            if isDroppedStatusLine(line) {
                if var enrollment = current {
                    enrollment.dropped = true
                    current = enrollment
                }
                continue
            }
            if isIgnorableStatusLine(line) { continue }

            if let title = parseCourseHeader(line) {
                commitEnrollment()
                current = Enrollment(title: title, dropped: lineIndicatesDropped(line))
                continue
            }

            if let range = parseDateRange(line) {
                commitMeeting()
                var meeting = MeetingDraft()
                meeting.semesterStart = range.start
                meeting.semesterEnd = defaultSemesterEnd ?? range.end
                openMeeting = meeting
                continue
            }

            if let weekday = parseStandaloneWeekday(line) {
                if openMeeting == nil { openMeeting = MeetingDraft() }
                openMeeting?.weekday = weekday
                continue
            }

            if let times = parseTimeRange(line) {
                if openMeeting == nil { openMeeting = MeetingDraft() }
                openMeeting?.startHour = times.startHour
                openMeeting?.startMinute = times.startMinute
                openMeeting?.endHour = times.endHour
                openMeeting?.endMinute = times.endMinute
                if var meeting = openMeeting {
                    applyMeetingDetails(line, to: &meeting)
                    openMeeting = meeting
                }
                continue
            }

            if looksLikeMeetingDetails(line) {
                if var meeting = openMeeting {
                    applyMeetingDetails(line, to: &meeting)
                    openMeeting = meeting
                }
                continue
            }

            if let crn = parseCRN(line) {
                commitMeeting()
                if var enrollment = current {
                    enrollment.crn = crn
                    current = enrollment
                }
                continue
            }

            if let name = parseInstructorLine(line) {
                if var enrollment = current {
                    enrollment.instructors.append(name)
                    current = enrollment
                }
                continue
            }
        }

        commitEnrollment()
        return enrollments.flatMap { $0.asEvents() }
    }

    // MARK: - Models

    private struct MeetingDraft {
        var semesterStart: Date?
        var semesterEnd: Date?
        var weekday: Int?
        var startHour: Int?
        var startMinute: Int?
        var endHour: Int?
        var endMinute: Int?
        var sessionKind: String?
        var location: String?
        var building: String?
        var room: String?

        var isComplete: Bool {
            weekday != nil
                && startHour != nil && startMinute != nil
                && endHour != nil && endMinute != nil
                && semesterStart != nil && semesterEnd != nil
        }

        var locationDisplay: String {
            [location, building, room].compactMap { $0 }.joined(separator: " · ")
        }
    }

    private struct Enrollment {
        var title: String
        var crn: String?
        var instructors: [String] = []
        var meetings: [MeetingDraft] = []
        var dropped = false

        func asEvents() -> [EditableScheduleEvent] {
            if dropped { return [] }
            return meetings.compactMap { meeting in
                guard meeting.isComplete,
                      let start = meeting.semesterStart,
                      let end = meeting.semesterEnd,
                      let weekday = meeting.weekday,
                      let sh = meeting.startHour, let sm = meeting.startMinute,
                      let eh = meeting.endHour, let em = meeting.endMinute
                else { return nil }

                var notes: [String] = []
                if let kind = meeting.sessionKind { notes.append(kind) }
                if let crn { notes.append("CRN \(crn)") }
                notes.append(contentsOf: instructors)

                return EditableScheduleEvent(
                    title: title,
                    location: meeting.locationDisplay,
                    notes: notes.joined(separator: "\n"),
                    semesterStart: start,
                    semesterEnd: end,
                    weekdays: [weekday],
                    startHour: sh,
                    startMinute: sm,
                    endHour: eh,
                    endMinute: em,
                    sessionKind: meeting.sessionKind
                )
            }
        }
    }

    // MARK: - Normalize

    private static func normalize(_ raw: String) -> [String] {
        var text = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{2007}", with: " ")

        let glued = NSMutableString(string: text)
        amPmGlue.replaceMatches(
            in: glued,
            options: [],
            range: NSRange(location: 0, length: glued.length),
            withTemplate: "$1 $2"
        )
        text = glued as String

        return text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    // MARK: - Line classifiers

    /// Mini-calendar row copied from the portal (`S`, `• M`, or a full `S M T W T F S` line).
    private static func isCalendarWidgetLine(_ line: String) -> Bool {
        let stripped = line
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "·", with: "")
            .replacingOccurrences(of: "●", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespaces)
        if stripped.count == 1, let ch = stripped.uppercased().first, "SMTWF".contains(ch) {
            return true
        }
        let tokens = stripped.split { $0.isWhitespace }.map { $0.uppercased() }
        return tokens.count == 7 && tokens.allSatisfy { $0.count == 1 && "SMTWF".contains($0) }
    }

    private static func isIgnorableStatusLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces).lowercased()
        let noise: Set<String> = [
            "registered",
            "waitlisted",
            "wait listed",
            "wait-listed",
            "enrolled",
            "web registered",
        ]
        if noise.contains(t) { return true }
        if t.hasPrefix("status:") {
            let rest = t.dropFirst("status:".count).trimmingCharacters(in: .whitespaces)
            if rest.contains("drop") || rest.contains("withdraw") { return false }
            return rest.contains("register") || rest.contains("enroll") || rest.contains("wait")
        }
        return false
    }

    private static func isDroppedStatusLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces).lowercased()
        if t == "dropped" || t == "withdrawn" { return true }
        if t.hasPrefix("status:") {
            let rest = t.dropFirst("status:".count).trimmingCharacters(in: .whitespaces)
            return rest.contains("drop") || rest.contains("withdraw")
        }
        return false
    }

    private static func lineIndicatesDropped(_ line: String) -> Bool {
        line.range(of: #"\b(dropped|withdrawn)\b"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func looksLikeMeetingDetails(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("type:")
            || lower.contains("location:")
            || lower.contains("building:")
            || lower.contains("room:")
    }

    /// Keep `Title | Subject 301 Section 01`; join split catalog cells; drop status / Class Begin tails.
    private static func parseCourseHeader(_ line: String) -> String? {
        guard line.contains("|") else { return nil }
        guard line.range(of: #"\bSection\b"#, options: [.regularExpression, .caseInsensitive]) != nil else {
            return nil
        }
        var parts = line.split(separator: "|", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { $0.isEmpty == false }

        let status: Set<String> = [
            "registered", "waitlisted", "wait listed", "wait-listed",
            "enrolled", "web registered", "dropped", "withdrawn",
        ]
        parts.removeAll { status.contains($0.lowercased()) }
        parts.removeAll {
            $0.range(
                of: #"^(Class\s+)?(Begin|End|Start|Class Begin|Class End)\s*:"#,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
        }

        guard parts.count >= 2, parts[0].isEmpty == false else { return nil }
        let catalog = parts.dropFirst().joined(separator: " | ")
        guard catalog.range(of: #"\bSection\b"#, options: [.regularExpression, .caseInsensitive]) != nil else {
            return nil
        }
        return "\(parts[0]) | \(catalog)"
    }

    private static func parseStandaloneWeekday(_ line: String) -> Int? {
        let t = line.trimmingCharacters(in: CharacterSet.letters.inverted).lowercased()
        switch t {
        case "sunday", "sun": return 1
        case "monday", "mon": return 2
        case "tuesday", "tue", "tues": return 3
        case "wednesday", "wed": return 4
        case "thursday", "thu", "thur", "thurs": return 5
        case "friday", "fri": return 6
        case "saturday", "sat": return 7
        default: return nil
        }
    }

    private static func parseCRN(_ line: String) -> String? {
        guard let m = firstMatch(crnPattern, line), m.numberOfRanges >= 2,
              let r = Range(m.range(at: 1), in: line)
        else { return nil }
        return String(line[r])
    }

    private static func parseInstructorLine(_ line: String) -> String? {
        if looksLikeMeetingDetails(line) { return nil }
        if parseDateRange(line) != nil { return nil }
        if parseTimeRange(line) != nil { return nil }
        return ScheduleNoteFormatting.instructorDisplay(from: line)
    }

    private static func applyMeetingDetails(_ line: String, to meeting: inout MeetingDraft) {
        if let kind = capture(#"Type:\s*(.+?)(?=\s+(?:Location|Building|Room)\s*:|$)"#, line) {
            meeting.sessionKind = kind
        }
        meeting.location = cleanedPlace(capture(#"Location:\s*(.*?)(?=\s+Building:|$)"#, line))
        meeting.building = cleanedPlace(capture(#"Building:\s*(.*?)(?=\s+Room:|$)"#, line))
        meeting.room = cleanedPlace(capture(#"Room:\s*(.+)$"#, line))
    }

    private static func cleanedPlace(_ raw: String?) -> String? {
        guard var t = raw?.trimmingCharacters(in: .whitespacesAndNewlines), t.isEmpty == false else {
            return nil
        }
        if t.hasSuffix(",") { t.removeLast() }
        t = t.trimmingCharacters(in: .whitespaces)
        let drop: Set<String> = ["none", "n/a", "na", "null"]
        if drop.contains(t.lowercased()) { return nil }
        return t
    }

    // MARK: - Dates / times

    private static func parseDateRange(_ line: String) -> (start: Date, end: Date)? {
        if let m = firstMatch(isoDateRange, line), m.numberOfRanges >= 3,
           let r0 = Range(m.range(at: 1), in: line),
           let r1 = Range(m.range(at: 2), in: line),
           let s = yMd.date(from: String(line[r0])),
           let e = yMd.date(from: String(line[r1]))
        {
            return (s, e)
        }
        if let m = firstMatch(mdyDateRange, line), m.numberOfRanges >= 3,
           let r0 = Range(m.range(at: 1), in: line),
           let r1 = Range(m.range(at: 2), in: line),
           let s = mdY.date(from: String(line[r0])),
           let e = mdY.date(from: String(line[r1]))
        {
            return (s, e)
        }
        return parseNamedMonthDateRange(line)
    }

    private static func parseNamedMonthDateRange(_ line: String) -> (start: Date, end: Date)? {
        guard let m = firstMatch(namedMonthDateRange, line), m.numberOfRanges >= 3,
              let r0 = Range(m.range(at: 1), in: line),
              let r1 = Range(m.range(at: 2), in: line)
        else { return nil }
        let startRaw = String(line[r0])
        let endRaw = String(line[r1])
        guard let s = namedMonth.date(from: startRaw) ?? namedMonthLong.date(from: startRaw),
              let e = namedMonth.date(from: endRaw) ?? namedMonthLong.date(from: endRaw)
        else { return nil }
        return (s, e)
    }

    private static func parseTimeRange(_ line: String) -> (
        startHour: Int, startMinute: Int, endHour: Int, endMinute: Int
    )? {
        let glued = NSMutableString(string: line)
        amPmGlue.replaceMatches(
            in: glued,
            options: [],
            range: NSRange(location: 0, length: glued.length),
            withTemplate: "$1 $2"
        )
        let norm = glued as String
        guard let m = firstMatch(timeRange, norm), m.numberOfRanges >= 3,
              let r0 = Range(m.range(at: 1), in: norm),
              let r1 = Range(m.range(at: 2), in: norm),
              let t0 = parseClock(String(norm[r0])),
              let t1 = parseClock(String(norm[r1]))
        else { return nil }
        return (t0.hour, t0.minute, t1.hour, t1.minute)
    }

    private static func parseClock(_ s: String) -> (hour: Int, minute: Int)? {
        let t = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "  ", with: " ")
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        for format in ["h:mm a", "h a", "hh:mm a"] {
            f.dateFormat = format
            if let d = f.date(from: t) {
                return (cal.component(.hour, from: d), cal.component(.minute, from: d))
            }
        }
        return nil
    }

    private static func capture(_ pattern: String, _ s: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        guard let m = firstMatch(re, s), m.numberOfRanges >= 2, let r = Range(m.range(at: 1), in: s) else {
            return nil
        }
        return String(s[r]).trimmingCharacters(in: .whitespaces)
    }

    private static func firstMatch(_ re: NSRegularExpression, _ s: String) -> NSTextCheckingResult? {
        re.firstMatch(in: s, options: [], range: NSRange(s.startIndex ..< s.endIndex, in: s))
    }

    private static let mdyDateRange = try! NSRegularExpression(
        pattern: #"(\d{1,2}/\d{1,2}/\d{4})\s*(?:--|–|-|—|to|through)\s*(\d{1,2}/\d{1,2}/\d{4})"#
    )
    private static let isoDateRange = try! NSRegularExpression(
        pattern: #"(\d{4}-\d{2}-\d{2})\s*(?:--|–|-|—|to|through|until)\s*(\d{4}-\d{2}-\d{2})"#,
        options: [.caseInsensitive]
    )
    private static let namedMonthDateRange = try! NSRegularExpression(
        pattern: #"((?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{1,2},\s*\d{4})\s*(?:--|–|-|—|to|through)\s*((?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{1,2},\s*\d{4})"#,
        options: [.caseInsensitive]
    )
    private static let timeRange = try! NSRegularExpression(
        pattern: #"(\d{1,2}(?::\d{2})?\s*[AP]M)\s*(?:-|–|—|to)\s*(\d{1,2}(?::\d{2})?\s*[AP]M)"#,
        options: .caseInsensitive
    )
    private static let amPmGlue = try! NSRegularExpression(
        pattern: #"(\d{1,2}(?::\d{2})?)([AP]M)\b"#,
        options: .caseInsensitive
    )
    private static let crnPattern = try! NSRegularExpression(
        pattern: #"CRN\s*:?\s*(\d+)"#,
        options: .caseInsensitive
    )

    private static let mdY: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "MM/dd/yyyy"
        return f
    }()

    private static let yMd: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let namedMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static let namedMonthLong: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()
}
