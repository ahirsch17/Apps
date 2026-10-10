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
            return "Nothing logged yet this week. A brisk 10-minute walk is a good start."
        }

        let gap = max(1, Int((expectedPoints - weekPoints).rounded(.up)))
        return "About \(gap) pts to match today's pace."
    }
}
