import Foundation

/// Turns messy portal instructor lines into calendar-note text: name plus email when present.
enum ScheduleNoteFormatting {
    private static let emailPattern = try! NSRegularExpression(
        pattern: #"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#,
        options: .caseInsensitive
    )
    private static let markdownMailto = try! NSRegularExpression(
        pattern: #"\[([^\]]+)\]\(mailto:([^)]+)\)"#,
        options: .caseInsensitive
    )

    /// `Knoeckel, Sarah — name@school.edu` (no raw `mailto:` wrappers).
    static func instructorDisplay(from raw: String) -> String? {
        var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.lowercased().hasPrefix("instructor:") {
            t = String(t.dropFirst("Instructor:".count)).trimmingCharacters(in: .whitespaces)
        }
        guard t.isEmpty == false else { return nil }
        if t.lowercased().hasPrefix("crn") { return nil }

        let email = extractEmail(t)
        t = stripMailtoMarkup(t)
        t = t.replacingOccurrences(of: "(Primary)", with: "", options: .caseInsensitive)
        t = t.replacingOccurrences(of: "(Secondary)", with: "", options: .caseInsensitive)
        t = t.replacingOccurrences(of: "()", with: "")
        t = t.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.contains(","), t.contains("|") == false else { return nil }

        let bits = t.split(separator: ",", maxSplits: 1)
        guard bits.count == 2 else { return nil }
        let last = bits[0].trimmingCharacters(in: .whitespaces)
        let rest = bits[1].trimmingCharacters(in: .whitespaces)
        guard last.isEmpty == false, rest.isEmpty == false else { return nil }
        let first = rest.split { $0 == " " || $0 == "(" }.first.map(String.init) ?? rest
        let name = "\(last), \(first)"
        if let email, name.localizedCaseInsensitiveContains(email) == false {
            return "\(name) — \(email)"
        }
        return name
    }

    static func extractEmail(_ raw: String) -> String? {
        if let m = markdownMailto.firstMatch(in: raw, options: [], range: NSRange(raw.startIndex ..< raw.endIndex, in: raw)),
           m.numberOfRanges >= 3,
           let r = Range(m.range(at: 2), in: raw)
        {
            let addr = String(raw[r]).trimmingCharacters(in: .whitespaces)
            if addr.contains("@") { return addr }
        }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        guard let m = emailPattern.firstMatch(in: raw, options: [], range: range),
              let r = Range(m.range, in: raw)
        else { return nil }
        return String(raw[r])
    }

    static func calendarNotes(for event: EditableScheduleEvent) -> String {
        var lines = event.notes
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        if let kind = event.sessionKind?.trimmingCharacters(in: .whitespaces),
           kind.isEmpty == false,
           lines.contains(where: { $0.caseInsensitiveCompare(kind) == .orderedSame }) == false
        {
            lines.insert(kind, at: 0)
        }
        return lines.joined(separator: "\n")
    }

    private static func stripMailtoMarkup(_ s: String) -> String {
        var out = s
        if let m = markdownMailto.firstMatch(in: out, options: [], range: NSRange(out.startIndex ..< out.endIndex, in: out)),
           m.numberOfRanges >= 2,
           let full = Range(m.range(at: 0), in: out),
           let name = Range(m.range(at: 1), in: out)
        {
            out.replaceSubrange(full, with: String(out[name]))
        }
        let wrappers = [#"\(mailto:[^)]*\)"#, #"mailto:[^\s)]+"#]
        for pattern in wrappers {
            while let range = out.range(of: pattern, options: .regularExpression) {
                out.removeSubrange(range)
            }
        }
        return out.replacingOccurrences(of: "  ", with: " ")
    }
}
