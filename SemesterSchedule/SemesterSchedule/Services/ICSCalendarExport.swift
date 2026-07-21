import Foundation

/// Builds a standard `.ics` calendar file (Apple Calendar + Google Calendar import).
enum ICSCalendarExport {
    /// RFC 5545 calendar document for the given blueprints.
    static func calendarString(
        from blueprints: [CalendarEventBlueprint],
        calendarName: String = "School Schedule",
        timeZone: TimeZone = .current,
        productId: String = "-//HirschEngineering//SemesterSchedule//EN"
    ) -> String {
        var lines: [String] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:\(productId)",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            "X-WR-CALNAME:\(escapeText(calendarName))",
        ]

        let tzid = timeZone.identifier
        for (idx, bp) in blueprints.enumerated() {
            lines.append(contentsOf: veventLines(bp, index: idx, tzid: tzid, timeZone: timeZone))
        }

        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    static func writeTemporaryFile(
        from blueprints: [CalendarEventBlueprint],
        fileName: String = "SchoolSchedule.ics",
        timeZone: TimeZone = .current
    ) throws -> URL {
        let body = calendarString(from: blueprints, timeZone: timeZone)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try body.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func veventLines(
        _ bp: CalendarEventBlueprint,
        index: Int,
        tzid: String,
        timeZone: TimeZone
    ) -> [String] {
        let byDays = bp.weekdays.compactMap(CalendarEventPlanner.icsByDayToken(forCalendarWeekday:))
        let until = formatUTCDateTime(bp.recurrenceEnd)
        let uid = "semesterschedule-\(index)-\(stableHash(bp))@hirschengineering.dev"
        var lines: [String] = [
            "BEGIN:VEVENT",
            "UID:\(uid)",
            "DTSTAMP:\(formatUTCDateTime(Date()))",
            "DTSTART;TZID=\(tzid):\(formatLocalDateTime(bp.firstStart, timeZone: timeZone))",
            "DTEND;TZID=\(tzid):\(formatLocalDateTime(bp.firstEnd, timeZone: timeZone))",
            "SUMMARY:\(escapeText(bp.title))",
        ]
        if bp.location.isEmpty == false {
            lines.append("LOCATION:\(escapeText(bp.location))")
        }
        if bp.notes.isEmpty == false {
            lines.append("DESCRIPTION:\(escapeText(bp.notes))")
        }
        if byDays.isEmpty == false {
            lines.append("RRULE:FREQ=WEEKLY;BYDAY=\(byDays.joined(separator: ","));UNTIL=\(until)")
        }
        if bp.alarmMinutesBefore > 0 {
            lines.append("BEGIN:VALARM")
            lines.append("ACTION:DISPLAY")
            lines.append("DESCRIPTION:Class reminder")
            lines.append("TRIGGER:-PT\(bp.alarmMinutesBefore)M")
            lines.append("END:VALARM")
        }
        lines.append("END:VEVENT")
        return lines
    }

    private static func formatLocalDateTime(_ date: Date, timeZone: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        f.dateFormat = "yyyyMMdd'T'HHmmss"
        return f.string(from: date)
    }

    private static func formatUTCDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return f.string(from: date)
    }

    private static func escapeText(_ s: String) -> String {
        s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
    }

    private static func stableHash(_ bp: CalendarEventBlueprint) -> String {
        let raw = "\(bp.title)|\(bp.weekdays)|\(bp.firstStart.timeIntervalSince1970)|\(bp.location)"
        var hash: UInt64 = 5381
        for b in raw.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(b)
        }
        return String(hash, radix: 16)
    }
}
