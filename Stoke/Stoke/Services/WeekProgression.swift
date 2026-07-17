import Foundation

enum WeekProgression {
    private static let hardCap = 210
    private static let plateauThreshold = 150
    private static let barelyThreshold = 1.05
    private static let solidThreshold = 1.25
    private static let easyWeeksThreshold = 1.30

    /// Week 1 (or prorated first period): starting goal was likely miscalibrated.
    private static let weekOneBlowoutRatio = 1.55
    /// Any week: earned nearly 2× the bar → one-time catch-up, not +8%.
    private static let singleWeekExtremeRatio = 1.90
    /// Share of actual earned used when recalibrating (same factor as two-week path).
    private static let recalibrationEarnedFraction = 0.85

    static func nextTarget(
        current: Int,
        earned: Double,
        periodTarget: Int,
        dayCount: Int,
        weekNumber: Int,
        previousWeekEarned: Double?,
        previousWeekTarget: Int?,
        previousWeekMet: Bool?
    ) -> (target: Int, wasRecalibrated: Bool) {
        guard earned >= Double(periodTarget) else {
            return (current, false)
        }

        let ratio = earned / Double(periodTarget)

        // Two consecutive strong weeks → smooth upward reset.
        if let prevEarned = previousWeekEarned,
           let prevTarget = previousWeekTarget,
           let prevMet = previousWeekMet,
           prevMet,
           ratio >= easyWeeksThreshold,
           prevEarned >= Double(prevTarget) * easyWeeksThreshold
        {
            let average = (normalizedFullWeekEarned(earned: earned, dayCount: dayCount)
                + normalizedFullWeekEarned(earned: prevEarned, dayCount: 7)) / 2.0
            let recalibrated = Int((average * recalibrationEarnedFraction).rounded())
            let bumped = max(current, min(recalibrated, hardCap))
            return (bumped, true)
        }

        // First completed week blew past a low starting bar (onboarding was off).
        if weekNumber == 1, ratio >= weekOneBlowoutRatio {
            return recalibratedTarget(fromEarned: earned, dayCount: dayCount, floor: current)
        }

        // Rare any-week blowout (e.g. 80 vs 37 later) — catch up once, still below what they did.
        if ratio >= singleWeekExtremeRatio {
            return recalibratedTarget(fromEarned: earned, dayCount: dayCount, floor: current)
        }

        let increment: Double
        if current >= plateauThreshold {
            increment = ratio < barelyThreshold ? 1.02 : 1.03
        } else if ratio < barelyThreshold {
            increment = 1.04
        } else if ratio < solidThreshold {
            increment = 1.06
        } else {
            increment = 1.08
        }

        let next = Int((Double(current) * increment).rounded())
        return (min(next, hardCap), false)
    }

    /// Scale short first periods up to a 7-day equivalent before setting the next full-week goal.
    private static func normalizedFullWeekEarned(earned: Double, dayCount: Int) -> Double {
        guard dayCount > 0, dayCount < 7 else { return earned }
        return earned * 7.0 / Double(dayCount)
    }

    private static func recalibratedTarget(
        fromEarned earned: Double,
        dayCount: Int,
        floor current: Int
    ) -> (target: Int, wasRecalibrated: Bool) {
        let fullWeekBasis = normalizedFullWeekEarned(earned: earned, dayCount: dayCount)
        let recalibrated = Int((fullWeekBasis * recalibrationEarnedFraction).rounded())
        let bumped = max(current, min(recalibrated, hardCap))
        return (bumped, true)
    }
}
