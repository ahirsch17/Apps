import Foundation

enum WeekHistoryFormatting {
    /// e.g. `May 29–31`, `Mar 2–8`, `Dec 28 '25 – Jan 3 '26`
    static func dateRange(start: Date, end: Date, calendar: Calendar = .current) -> String {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)

        if startDay == endDay {
            return compactDate(startDay, calendar: calendar)
        }

        let startYear = calendar.component(.year, from: startDay)
        let endYear = calendar.component(.year, from: endDay)
        let startMonth = calendar.component(.month, from: startDay)
        let endMonth = calendar.component(.month, from: endDay)

        if startYear == endYear, startMonth == endMonth {
            let month = startDay.formatted(.dateTime.month(.abbreviated))
            let dayStart = calendar.component(.day, from: startDay)
            let dayEnd = calendar.component(.day, from: endDay)
            let yearSuffix = yearSuffixIfNeeded(for: endDay, calendar: calendar)
            return "\(month) \(dayStart)-\(dayEnd)\(yearSuffix)"
        }

        return "\(compactDate(startDay, calendar: calendar)) - \(compactDate(endDay, calendar: calendar))"
    }

    static func weekTitle(weekNumber: Int, attempt: Int, showAttempt: Bool) -> String {
        if showAttempt, attempt > 1 {
            return "Week \(weekNumber) (attempt \(attempt))"
        }
        return "Week \(weekNumber)"
    }

    /// Chronological attempt index per archived week (1-based), keyed by period end day.
    static func attemptNumbers(for records: [WeekHistoryRecord], calendar: Calendar = .current) -> [Date: Int] {
        var attemptByWeek: [Int: Int] = [:]
        var result: [Date: Int] = [:]
        let chronological = records.sorted {
            calendar.startOfDay(for: $0.endDate) < calendar.startOfDay(for: $1.endDate)
        }

        for record in chronological {
            attemptByWeek[record.weekNumber, default: 0] += 1
            let endDay = calendar.startOfDay(for: record.endDate)
            result[endDay] = attemptByWeek[record.weekNumber] ?? 1
        }

        return result
    }

    static func showsAttemptLabel(for weekNumber: Int, records: [WeekHistoryRecord]) -> Bool {
        records.filter { $0.weekNumber == weekNumber }.count > 1
    }

    static func recap(
        for endDate: Date,
        in recaps: [WeekRecapRecord],
        calendar: Calendar = .current
    ) -> WeekRecapRecord? {
        let endDay = calendar.startOfDay(for: endDate)
        return recaps.first { calendar.startOfDay(for: $0.endDate) == endDay }
    }

    private static func compactDate(_ date: Date, calendar: Calendar) -> String {
        let year = calendar.component(.year, from: date)
        let thisYear = calendar.component(.year, from: Date())
        if year != thisYear {
            return date.formatted(.dateTime.month(.abbreviated).day().year(.twoDigits))
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private static func yearSuffixIfNeeded(for date: Date, calendar: Calendar) -> String {
        let year = calendar.component(.year, from: date)
        let thisYear = calendar.component(.year, from: Date())
        guard year != thisYear else { return "" }
        return " '\(String(year).suffix(2))"
    }
}
