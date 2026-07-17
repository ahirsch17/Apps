import Foundation

struct WeekPeriod: Equatable {
    let start: Date
    let end: Date
    let dayCount: Int
    let isFirstPartialWeek: Bool

    func targetForWeek(fullTarget: Int) -> Int {
        if dayCount >= 7 { return fullTarget }
        return Int((Double(fullTarget) * Double(dayCount) / 7.0).rounded())
    }

    func dayIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let dateDay = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startDay, to: dateDay).day ?? 0
        return min(max(days + 1, 1), dayCount)
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let d = calendar.startOfDay(for: date)
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        return d >= s && d <= e
    }

    static func current(onboardingDate: Date, now: Date = Date(), calendar: Calendar = .current) -> WeekPeriod {
        let onboardingStart = calendar.startOfDay(for: onboardingDate)
        let firstSaturday = endOfFirstSaturday(from: onboardingStart, calendar: calendar)
        let nowDay = calendar.startOfDay(for: now)

        if nowDay <= calendar.startOfDay(for: firstSaturday) {
            let days = daysFromDateToSaturday(from: onboardingStart, calendar: calendar)
            return WeekPeriod(
                start: onboardingStart,
                end: calendar.startOfDay(for: firstSaturday),
                dayCount: days,
                isFirstPartialWeek: days < 7
            )
        }

        let sunday = startOfWeekSunday(containing: nowDay, calendar: calendar)
        let saturday = calendar.date(byAdding: .day, value: 6, to: sunday) ?? nowDay
        return WeekPeriod(
            start: sunday,
            end: saturday,
            dayCount: 7,
            isFirstPartialWeek: false
        )
    }

    static func daysFromDateToSaturday(from date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 7 { return 1 }
        return 7 - weekday + 1
    }

    static func endOfFirstSaturday(from onboarding: Date, calendar: Calendar) -> Date {
        let days = daysFromDateToSaturday(from: onboarding, calendar: calendar)
        return calendar.date(byAdding: .day, value: days - 1, to: onboarding) ?? onboarding
    }

    static func startOfWeekSunday(containing date: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromSunday = weekday - 1
        return calendar.date(byAdding: .day, value: -daysFromSunday, to: date) ?? date
    }

    func datesInPeriod(calendar: Calendar = .current) -> [Date] {
        (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// First midnight of the Sunday that begins the recurring Sun→Sat cycles (after this period’s closing Saturday).
    func startOfNextSundaySUNSATCycle(calendar: Calendar = .current) -> Date {
        let satStart = calendar.startOfDay(for: end)
        return calendar.date(byAdding: .day, value: 1, to: satStart) ?? end
    }

    func formattedSundayStartingNextSevenDayCycle(calendar: Calendar = .current) -> String {
        startOfNextSundaySUNSATCycle(calendar: calendar)
            .formatted(date: .complete, time: .omitted)
    }
}
