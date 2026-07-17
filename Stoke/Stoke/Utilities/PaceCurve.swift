import Foundation

enum PaceCurve {
    /// Expected points by now: prorated for a short first week, aligned to calendar days
    /// (same day boundary as earned points from HealthKit).
    static func expectedPointsSoFar(
        period: WeekPeriod,
        periodTarget: Int,
        now: Date,
        calendar: Calendar = .current
    ) -> Double {
        guard periodTarget > 0, period.dayCount > 0 else { return 0 }

        let budgetPerDay = Double(periodTarget) / Double(period.dayCount)
        let daysInOrder = period.datesInPeriod(calendar: calendar)
        guard !daysInOrder.isEmpty else { return 0 }

        var expected = 0.0

        for dayDate in daysInOrder {
            let sod = calendar.startOfDay(for: dayDate)
            guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: sod) else {
                continue
            }

            // Match HealthKit day buckets: progress counts from midnight on each day,
            // including the install day, not from the exact onboarding timestamp.
            let effectiveStart = sod
            let daySeconds = nextMidnight.timeIntervalSince(effectiveStart)
            guard daySeconds > 0 else { continue }

            if now < effectiveStart {
                break
            }

            if now >= nextMidnight {
                expected += budgetPerDay
                continue
            }

            let elapsed = now.timeIntervalSince(effectiveStart)
            let frac = max(0, min(1, elapsed / daySeconds))
            expected += budgetPerDay * frac
            break
        }

        return min(expected, Double(periodTarget))
    }
}
