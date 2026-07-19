import Foundation

/// One recurring meeting the user can edit before importing.
struct EditableScheduleEvent: Identifiable, Hashable {
    var id: UUID
    var title: String
    var location: String
    var notes: String
    var semesterStart: Date
    var semesterEnd: Date
    /// `Calendar` weekday: 1 = Sunday … 7 = Saturday
    var weekdays: Set<Int>
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var sessionKind: String?
    var isSelected: Bool
    /// True when the registrar listed TBA / no clock times (async online, etc.).
    var isTBA: Bool

    init(
        id: UUID = UUID(),
        title: String,
        location: String,
        notes: String,
        semesterStart: Date,
        semesterEnd: Date,
        weekdays: Set<Int>,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        sessionKind: String? = nil,
        isSelected: Bool = true,
        isTBA: Bool = false
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.notes = notes
        self.semesterStart = semesterStart
        self.semesterEnd = semesterEnd
        self.weekdays = weekdays
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.sessionKind = sessionKind
        self.isSelected = isSelected
        self.isTBA = isTBA
    }

    func firstOccurrenceStart(calendar: Calendar = .current) -> Date? {
        let cal = calendar
        var best: Date?
        for wd in weekdays.sorted() {
            var comps = DateComponents()
            comps.weekday = wd
            comps.hour = startHour
            comps.minute = startMinute
            comps.second = 0
            if let d = cal.nextDate(
                after: cal.startOfDay(for: semesterStart).addingTimeInterval(-1),
                matching: comps,
                matchingPolicy: .nextTime,
                direction: .forward
            ), d <= semesterEnd {
                if best == nil || d < best! { best = d }
            }
        }
        return best
    }

    func durationSeconds(calendar: Calendar = .current) -> TimeInterval {
        let cal = calendar
        var s = DateComponents()
        s.hour = startHour
        s.minute = startMinute
        var e = DateComponents()
        e.hour = endHour
        e.minute = endMinute
        let base = cal.startOfDay(for: semesterStart)
        guard let start = cal.date(byAdding: s, to: base),
              var end = cal.date(byAdding: e, to: base)
        else { return 3600 }
        // Overnight labs (e.g. 10:00 PM – 1:00 AM) span past midnight.
        if end <= start {
            end = cal.date(byAdding: .day, value: 1, to: end) ?? end.addingTimeInterval(24 * 3600)
        }
        return end.timeIntervalSince(start)
    }

    /// True when the paste did not yield any weekdays (for example a lost mini-calendar row).
    var needsWeekdayPick: Bool { weekdays.isEmpty && isTBA == false }

    /// Rows that can become recurring calendar events.
    var canAddToCalendar: Bool {
        isTBA == false && weekdays.isEmpty == false
    }

    func displaySemesterRange(calendar: Calendar = .current) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = calendar.timeZone
        df.dateStyle = .medium
        df.timeStyle = .none
        return "\(df.string(from: semesterStart)) – \(df.string(from: semesterEnd))"
    }

    func displayTimeRange(calendar: Calendar = .current) -> String {
        if isTBA { return "TBA / no meeting times" }
        let cal = calendar
        let base = cal.startOfDay(for: Date())
        guard let d1 = cal.date(bySettingHour: startHour, minute: startMinute, second: 0, of: base),
              let d2 = cal.date(bySettingHour: endHour, minute: endMinute, second: 0, of: base)
        else { return "" }
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = cal.timeZone
        df.dateFormat = "h:mm a"
        var end = d2
        if end <= d1 {
            end = cal.date(byAdding: .day, value: 1, to: end) ?? end
        }
        return "\(df.string(from: d1))–\(df.string(from: end))"
    }
}
