import Foundation

/// One row from a Virginia Tech–style tabular SIS paste (12 logical columns).
struct VTTabularParsedRow {
    var crn: String
    var courseCode: String
    var modality: String
    var title: String
    var gradeOption: String
    var creditHoursInt: Int
    var timeStart: (hour: Int, minute: Int)?
    var timeEnd: (hour: Int, minute: Int)?
    /// Calendar weekdays 1…7 (Sunday…Saturday); empty when Days = TBA.
    var weekdayNumbers: Set<Int>
    var locationToken: String
    var instructor: String
    var partOfTerm: String
    var exam: String
}

enum VTTabularScheduleParser {
    private static let tableFooterLinePattern = try! NSRegularExpression(pattern: #"^(?i)total\b"#, options: [])
    private static let crnLineStartPattern = try! NSRegularExpression(pattern: #"^\d{4,5}\b"#, options: [])
    private static let amPmGlue = try! NSRegularExpression(pattern: #"(\d{1,2}:\d{2})([AP]M)"#, options: .caseInsensitive)

    private static let modalitiesOrdered: [String] = [
        "Online with Synchronous Mtgs.",
        "Online: Asynchronous",
        "Face-to-Face Instruction",
    ]

    /// Tab-separated 12 columns, or a single-line space version matched by `vtSpaceRowPattern`.
    static func parse(_ text: String) -> [VTTabularParsedRow]? {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let records = flattenRecords(lines)
        var rows: [VTTabularParsedRow] = []
        for rec in records {
            if let r = parseTabSeparatedRow(rec) ?? parseSpaceDelimitedRow(rec) {
                rows.append(r)
            }
        }
        return rows.isEmpty ? nil : rows
    }

    /// True when the paste looks like the VT table (header words + modality column).
    static func looksLikeVtTabularPaste(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("modality"), lower.contains("grade opt"), lower.contains("part of term") {
            return true
        }
        if lower.contains("online: asynchronous"), lower.contains("face-to-face instruction") {
            return true
        }
        return false
    }

    static func toEditableScheduleEvents(
        _ rows: [VTTabularParsedRow],
        semesterStart: Date,
        semesterEnd: Date
    ) -> [EditableScheduleEvent] {
        rows.map { row in
            let (sh, sm, eh, em) = placeholderTimes(for: row)
            let locDisplay: String = {
                let t = row.locationToken.trimmingCharacters(in: .whitespaces)
                if t.uppercased() == "ONLINE" { return "Online" }
                return t
            }()
            let kind: String = row.modality.lowercased().hasPrefix("face-to-face") ? "Class" : "Online"
            return EditableScheduleEvent(
                title: row.title,
                location: locDisplay,
                notes: "CRN \(row.crn)\n\(row.courseCode)\n\(row.modality)",
                semesterStart: semesterStart,
                semesterEnd: semesterEnd,
                weekdays: row.weekdayNumbers,
                startHour: sh,
                startMinute: sm,
                endHour: eh,
                endMinute: em,
                sessionKind: kind
            )
        }
    }

    private static func placeholderTimes(for row: VTTabularParsedRow) -> (Int, Int, Int, Int) {
        if let s = row.timeStart, let e = row.timeEnd {
            return (s.hour, s.minute, e.hour, e.minute)
        }
        return (9, 0, 10, 0)
    }

    private static func flattenRecords(_ lines: [String]) -> [String] {
        var records: [String] = []
        var buffer: [String] = []

        func flush() {
            guard buffer.isEmpty == false else { return }
            records.append(buffer.joined(separator: " "))
            buffer.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if firstMatch(tableFooterLinePattern, line) != nil {
                flush()
                continue
            }
            if firstMatch(crnLineStartPattern, line) != nil {
                flush()
                buffer.append(line)
            } else if buffer.isEmpty == false {
                buffer.append(line)
            }
        }
        flush()
        return records
    }

    private static func firstMatch(_ re: NSRegularExpression, _ s: String) -> NSTextCheckingResult? {
        let range = NSRange(s.startIndex ..< s.endIndex, in: s)
        return re.firstMatch(in: s, options: [], range: range)
    }

    private static func parseTabSeparatedRow(_ record: String) -> VTTabularParsedRow? {
        guard record.contains("\t") else { return nil }
        let cols = record.split(separator: "\t", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard cols.count >= 12 else { return nil }
        return buildRow(
            crn: cols[0],
            courseCode: cols[1],
            modality: cols[2],
            title: cols[3],
            gradeOption: cols[4],
            creditHours: cols[5],
            time: cols[6],
            days: cols[7],
            location: cols[8],
            instructor: cols[9],
            partOfTerm: cols[10],
            exam: cols[11]
        )
    }

    /// Space-delimited single line (after email flattening).
    private static let vtSpaceRowPattern = try! NSRegularExpression(
        pattern: #"""
^(\d{5})\s+
([A-Z]{2,10}\s+\d{4})\s+
(Online with Synchronous Mtgs\.|Online: Asynchronous|Face-to-Face Instruction)\s+
(.+?)\s+
(A\s*-\s*F|Pass/Fail)\s+
(\d+(?:\.\d+)?)\s+
(TBA|\d{1,2}:\d{2}\s*[AP]M\s*-\s*\d{1,2}:\d{2}\s*[AP]M)\s+
(TBA|[MTWRFSU]+)\s+
(ONLINE|[A-Za-z0-9]+\s+\d+)\s+
(.+?)\s+
([E1])\s+
([0-9A-Z]{3})$
"""#,
        options: [.caseInsensitive]
    )

    private static func parseSpaceDelimitedRow(_ record: String) -> VTTabularParsedRow? {
        let ns = record as NSString
        guard let m = vtSpaceRowPattern.firstMatch(in: record, options: [], range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 13
        else { return nil }

        func cap(_ i: Int) -> String {
            guard let r = Range(m.range(at: i), in: record) else { return "" }
            return String(record[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return buildRow(
            crn: cap(1),
            courseCode: cap(2),
            modality: cap(3),
            title: cap(4),
            gradeOption: cap(5),
            creditHours: cap(6),
            time: cap(7),
            days: cap(8),
            location: cap(9),
            instructor: cap(10),
            partOfTerm: cap(11),
            exam: cap(12)
        )
    }

    private static func buildRow(
        crn: String,
        courseCode: String,
        modality: String,
        title: String,
        gradeOption: String,
        creditHours: String,
        time: String,
        days: String,
        location: String,
        instructor: String,
        partOfTerm: String,
        exam: String
    ) -> VTTabularParsedRow? {
        guard crn.allSatisfy(\.isNumber), crn.count >= 4 else { return nil }
        let creditVal = Double(creditHours.replacingOccurrences(of: ",", with: ".")) ?? 0
        let creditHoursInt = Int(creditVal + 0.001)

        let timeNorm = time.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
        let timeParts: (start: (hour: Int, minute: Int)?, end: (hour: Int, minute: Int)?) = {
            if timeNorm.uppercased() == "TBA" { return (nil, nil) }
            let parts = timeNorm.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2,
                  let s = parseTimeToken(parts[0]),
                  let e = parseTimeToken(parts[1])
            else { return (nil, nil) }
            return (s, e)
        }()

        let wds = parseVtDays(days)

        return VTTabularParsedRow(
            crn: crn,
            courseCode: courseCode,
            modality: modality,
            title: title,
            gradeOption: gradeOption,
            creditHoursInt: creditHoursInt,
            timeStart: timeParts.start,
            timeEnd: timeParts.end,
            weekdayNumbers: wds,
            locationToken: location,
            instructor: instructor,
            partOfTerm: partOfTerm,
            exam: exam
        )
    }

    private static func parseTimeToken(_ s: String) -> (hour: Int, minute: Int)? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "h:mm a"
        let m = NSMutableString(string: s.trimmingCharacters(in: .whitespaces))
        amPmGlue.replaceMatches(in: m, options: [], range: NSRange(location: 0, length: m.length), withTemplate: "$1 $2")
        let t = m as String
        guard let d = f.date(from: t) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return (cal.component(.hour, from: d), cal.component(.minute, from: d))
    }

    private static func parseVtDays(_ raw: String) -> Set<Int> {
        let u = raw.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: ",", with: "")
        if u == "TBA" { return [] }

        let bundles: [String: Set<Int>] = [
            "MWF": [2, 4, 6],
            "MW": [2, 4],
            "WF": [4, 6],
            "MF": [2, 6],
            "TR": [3, 5],
            "MWTH": [2, 4, 5],
            "MTWR": [2, 3, 4, 5],
            "MTWRF": [2, 3, 4, 5, 6],
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
            case "U": i = u.index(after: i)
            default: i = u.index(after: i)
            }
        }
        return set
    }
}
