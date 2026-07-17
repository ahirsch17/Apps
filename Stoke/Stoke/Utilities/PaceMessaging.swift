import Foundation

enum PaceMessaging {
    /// `expectedPoints` comes from `PaceCurve` (smooth intraday).
    static func status(
        weekPoints: Double,
        expectedPoints: Double,
        periodTarget: Int
    ) -> String {
        if weekPoints >= Double(periodTarget) {
            return "Goal reached. Nice work."
        }

        if weekPoints >= expectedPoints - 2 {
            return "On track."
        }

        if weekPoints <= 0 {
            return "Start when you are ready. Rest days count toward the week too."
        }

        let gap = max(1, Int((expectedPoints - weekPoints).rounded(.up)))
        return "About \(gap) pts to match today's pace."
    }

    static func newWeekMessage(metTarget: Bool) -> String {
        metTarget ? "Goal met last week. Keep going." : "Same goal this week. You can do it."
    }
}
