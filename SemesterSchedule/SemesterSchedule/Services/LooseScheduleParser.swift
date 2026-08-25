import Foundation

/// Last-resort paste parser for syllabi, Canvas blurbs, and notes that are not Banner/SIS tables.
/// Looks for a clock range plus nearby day names or codes (`MWF`, `TR`, `Tue/Thu`).
enum LooseScheduleParser {
    static func parse(_ raw: String, defaultSemesterEnd: Date?) -> [EditableScheduleEvent] {
        let lines = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard lines.isEmpty == false else { return [] }

        let end = defaultSemesterEnd ?? Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
        let start = Calendar.current.date(byAdding: .month, value: -4, to: end) ?? end

        var out: [EditableScheduleEvent] = []
        var i = 0
        while i < lines.count {
            let line = normalizeTimeLine(lines[i])
            if isIgnorableLooseLine(line) {
                i += 1
                continue
            }
            guard let times = matchTimeRange(in: line),
                  let timeSpan = timeRangeSpan(in: line)
            else {
                i += 1
                continue
            }

            let before = String(line[..<timeSpan.lowerBound]).trimmingCharacters(in: .whitespacesAndPunctuation)
            let after = String(line[timeSpan.upperBound...]).trimmingCharacters(in: .whitespacesAndPunctuation)
            let prev = i > 0 ? lines[i - 1] : ""
            let next = i + 1 < lines.count ? lines[i + 1] : ""
            let next2 = i + 2 < lines.count ? lines[i + 2] : ""

            var days = extractDays(before)
                .union(extractDays(after))
                .union(extractDays(line))
            if days.isEmpty { days = extractDays(prev) }
            if days.isEmpty { days = extractDays(next) }

            var title = stripScheduleNoise(before)
            if title.count < 3 { title = stripScheduleNoise(prev) }
            if looksLikeDaysOnly(title) || looksLikeTimeOnly(title) { title = "" }
            if title.count < 3 { title = stripScheduleNoise(next) }
            if title.count < 3 { title = "Class" }

            var location = stripScheduleNoise(after)
            if looksLikeDaysOnly(location) { location = "" }
            if location.count < 2,
               looksLikePlace(next),
               matchTimeRange(in: next) == nil,
               matchTimeRange(in: next2) == nil,
               looksLikeCourseHeading(next) == false
            {
                location = stripScheduleNoise(next)
            }

            out.append(
                EditableScheduleEvent(
                    title: title,
                    location: location,
                    notes: "",
                    semesterStart: start,
                    semesterEnd: end,
                    weekdays: days,
                    startHour: times.startHour,
                    startMinute: times.startMinute,
                    endHour: times.endHour,
                    endMinute: times.endMinute
                )
            )
            i += 1
        }

        return coalesceSameSlot(out)
    }

    // MARK: - Coalesce

    private static func coalesceSameSlot(_ events: [EditableScheduleEvent]) -> [EditableScheduleEvent] {
        var map: [String: EditableScheduleEvent] = [:]
        for e in events {
            let key = "\(e.title.lowercased())|\(e.startHour):\(e.startMinute)|\(e.endHour):\(e.endMinute)|\(e.location.lowercased())"
            if var existing = map[key] {
                existing.weekdays.formUnion(e.weekdays)
                map[key] = existing
            } else {
                map[key] = e
            }
        }
        return Array(map.values).sorted { ($0.title, $0.startHour, $0.startMinute) < ($1.title, $1.startHour, $1.startMinute) }
    }

    private static func isIgnorableLooseLine(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: "•", with: "").trimmingCharacters(in: .whitespaces)
        if stripped.count == 1, let ch = stripped.uppercased().first, "SMTWF".contains(ch) {
            return true
        }
        let tokens = stripped.split { $0.isWhitespace }.map { $0.uppercased() }
        return tokens.count == 7 && tokens.allSatisfy { $0.count == 1 && "SMTWF".contains($0) }
    }

    // MARK: - Days

    private static func extractDays(_ s: String) -> Set<Int> {
        var set = Set<Int>()
        let lower = s.lowercased()

        let named: [(String, Int)] = [
            ("sundays", 1), ("mondays", 2), ("tuesdays", 3), ("wednesdays", 4),
            ("thursdays", 5), ("fridays", 6), ("saturdays", 7),
            ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7),
            ("tues", 3), ("thur", 5), ("thurs", 5),
        ]
        for (name, wd) in named where lower.contains(name) {
            set.insert(wd)
        }

        let ns = s as NSString
        abbrevTokenPattern.enumerateMatches(in: s, options: [], range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match, let r = Range(match.range, in: s),
                  let days = parseAbbrevDays(String(s[r]))
            else { return }
            set.formUnion(days)
        }

        return set
    }

    private static let abbrevTokenPattern = try! NSRegularExpression(
        pattern: #"\b(MTWRF|MTWR|MWTH|MWF|TUTH|TTH|TR|MW|WF|MF|Tu/?Th|M/?W/?F|[MTWRF]{1,5})\b"#,
        options: [.caseInsensitive]
    )

    /// US-style abbreviations: M=Mon, T=Tue, W=Wed, R=Thu, F=Fri.
    static func parseAbbrevDays(_ s: String) -> Set<Int>? {
        let u = s.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "–", with: "")
            .replacingOccurrences(of: "—", with: "")
            .replacingOccurrences(of: "-", with: "")
        if u == "TBA" || u.isEmpty { return nil }

        let bundles: [String: Set<Int>] = [
            "MWF": [2, 4, 6],
            "MW": [2, 4],
            "WF": [4, 6],
            "MF": [2, 6],
            "TR": [3, 5],
            "TTH": [3, 5],
            "TUTH": [3, 5],
            "TUTHURS": [3, 5],
            "MWTH": [2, 4, 5],
            "MTWR": [2, 3, 4, 5],
            "MTWRF": [2, 3, 4, 5, 6],
            "SU": [1],
            "SA": [7],
        ]
        if let b = bundles[u] { return b }

        var set = Set<Int>()
        var i = u.startIndex
        while i < u.endIndex {
            let c = u[i]
            switch c {
            case "M": set.insert(2); i = u.index(after: i)
            case "W": set.insert(4); i = u.index(after: i)
            case "F": set.insert(6); i = u.index(after: i)
            case "S":
                let next = u.index(after: i)
                if next < u.endIndex, u[next] == "U" { set.insert(1); i = u.index(after: next) }
                else if next < u.endIndex, u[next] == "A" { i = u.index(after: next) }
                else { set.insert(7); i = next }
            case "T":
                let next = u.index(after: i)
                if next < u.endIndex, u[next] == "H" { set.insert(5); i = u.index(after: next) }
                else if next < u.endIndex, u[next] == "U" { set.insert(3); i = u.index(after: next) }
                else { set.insert(3); i = next }
            case "R": set.insert(5); i = u.index(after: i)
            default: i = u.index(after: i)
            }
        }
        return set.isEmpty ? nil : set
    }

    // MARK: - Times

    private static let timeRangePattern = try! NSRegularExpression(
        pattern: #"(\d{1,2}(?::\d{2})?\s*[AP]M)\s*(?:-|–|—|to)\s*(\d{1,2}(?::\d{2})?\s*[AP]M)"#,
        options: .caseInsensitive
    )
    private static let timeRange24Pattern = try! NSRegularExpression(
        pattern: #"(?<!\d)([01]?\d|2[0-3]):([0-5]\d)\s*(?:-|–|—|to)\s*([01]?\d|2[0-3]):([0-5]\d)(?!\s*[AP]M)"#,
        options: .caseInsensitive
    )
    private static let amPmGluePattern = try! NSRegularExpression(
        pattern: #"(\d{1,2}(?::\d{2})?)([AP]M)\b"#,
        options: .caseInsensitive
    )

    private static func normalizeTimeLine(_ line: String) -> String {
        let m = NSMutableString(string: line)
        amPmGluePattern.replaceMatches(in: m, options: [], range: NSRange(location: 0, length: m.length), withTemplate: "$1 $2")
        return m as String
    }

    private static func matchTimeRange(in line: String) -> (startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)? {
        let norm = normalizeTimeLine(line)
        if let m = firstMatch(timeRangePattern, norm), m.numberOfRanges >= 3,
           let r0 = Range(m.range(at: 1), in: norm),
           let r1 = Range(m.range(at: 2), in: norm),
           let t0 = parseClock(String(norm[r0])),
           let t1 = parseClock(String(norm[r1]))
        {
            return (t0.hour, t0.minute, t1.hour, t1.minute)
        }
        if let m = firstMatch(timeRange24Pattern, norm), m.numberOfRanges >= 5,
           let rH0 = Range(m.range(at: 1), in: norm),
           let rM0 = Range(m.range(at: 2), in: norm),
           let rH1 = Range(m.range(at: 3), in: norm),
           let rM1 = Range(m.range(at: 4), in: norm),
           let h0 = Int(norm[rH0]), let m0 = Int(norm[rM0]),
           let h1 = Int(norm[rH1]), let m1 = Int(norm[rM1])
        {
            return (h0, m0, h1, m1)
        }
        return nil
    }

    private static func timeRangeSpan(in line: String) -> Range<String.Index>? {
        let norm = line
        if let m = firstMatch(timeRangePattern, norm), let r = Range(m.range(at: 0), in: norm) {
            return r
        }
        if let m = firstMatch(timeRange24Pattern, norm), let r = Range(m.range(at: 0), in: norm) {
            return r
        }
        return nil
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

    private static func firstMatch(_ re: NSRegularExpression, _ s: String) -> NSTextCheckingResult? {
        re.firstMatch(in: s, options: [], range: NSRange(s.startIndex ..< s.endIndex, in: s))
    }

    // MARK: - Text cleanup

    private static func stripScheduleNoise(_ raw: String) -> String {
        var t = raw
        t = t.replacingOccurrences(of: #"Type:\s*\S+"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"Location:\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: #"Building:\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: #"Room:\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: #"\b(MWF|TTH|TUTH|TR|MW|WF|MF|MTWRF|MTWR)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(
            of: #"\b(Mon(?:day)?|Tue(?:s(?:day)?)?|Wed(?:nesday)?|Thu(?:rs(?:day)?)?|Fri(?:day)?|Sat(?:urday)?|Sun(?:day)?)\b"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        t = t.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndPunctuation)
    }

    private static func looksLikeDaysOnly(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndPunctuation)
        if t.isEmpty { return true }
        if extractDays(t).isEmpty == false, stripScheduleNoise(t).count < 3 { return true }
        return false
    }

    private static func looksLikeTimeOnly(_ s: String) -> Bool {
        matchTimeRange(in: s) != nil && stripScheduleNoise(s).count < 3
    }

    private static func looksLikePlace(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 2, t.count <= 48 else { return false }
        if matchTimeRange(in: t) != nil { return false }
        if looksLikeCourseHeading(t) { return false }
        if t.contains("|") { return false }
        if t.lowercased().hasPrefix("instructor") { return false }
        if t.lowercased().hasPrefix("crn") { return false }
        return true
    }

    private static func looksLikeCourseHeading(_ s: String) -> Bool {
        s.range(
            of: #"^[A-Z]{2,10}\s+\d{3,4}\s+\S+"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
}

private extension CharacterSet {
    static let whitespacesAndPunctuation = CharacterSet.whitespacesAndNewlines
        .union(.punctuationCharacters)
}
