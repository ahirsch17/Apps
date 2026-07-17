import Foundation

enum BadgeCycle {
    static func tilesRequired(badgeIndex: Int) -> Int {
        switch badgeIndex % 3 {
        case 0: return 5
        case 1: return 5
        default: return 6
        }
    }

    static func badgeTitle(earnedCount: Int) -> String {
        switch earnedCount {
        case 0: return "First steps"
        case 1: return "Building rhythm"
        case 2: return "Steady engine"
        default: return "Long haul"
        }
    }
}

struct MilestoneBadge: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let earned: Bool
}

enum GamificationEngine {
    /// Days that met or beat the prorated daily target (fair consistency metric).
    static func greenDayCount(
        period: WeekPeriod,
        periodTarget: Int,
        pointsByDay: [Date: Double],
        weekNumber: Int = 1,
        calendar: Calendar = .current
    ) -> Int {
        let dates = period.datesInPeriod(calendar: calendar)
        guard !dates.isEmpty else { return 0 }
        let dayTarget = Double(periodTarget) / Double(dates.count)
        let greenFraction = 0.85

        return dates.reduce(into: 0) { count, date in
            let dayStart = calendar.startOfDay(for: date)
            let pts = pointsByDay[dayStart] ?? 0
            if pts >= dayTarget * greenFraction {
                count += 1
            }
        }
    }

    static func weekCompletionPercent(earned: Double, target: Int) -> Int {
        guard target > 0 else { return 0 }
        return min(Int((earned / Double(target) * 100).rounded()), 999)
    }

    static func milestones(
        badgesEarned: Int,
        consecutiveWeeksMet: Int,
        bestWeekStreak: Int,
        lifetimePoints: Double,
        weeksCompleted: Int
    ) -> [MilestoneBadge] {
        [
            MilestoneBadge(
                id: "first_goal",
                title: "First ring",
                subtitle: "Completed a weekly goal",
                systemImage: "circle.circle",
                earned: weeksCompleted >= 1
            ),
            MilestoneBadge(
                id: "streak_2",
                title: "Two in a row",
                subtitle: "Back-to-back goal weeks",
                systemImage: "flame",
                earned: bestWeekStreak >= 2
            ),
            MilestoneBadge(
                id: "streak_4",
                title: "Month of momentum",
                subtitle: "4-week goal streak",
                systemImage: "flame.fill",
                earned: bestWeekStreak >= 4
            ),
            MilestoneBadge(
                id: "pts_200",
                title: "200 club",
                subtitle: "200+ lifetime points",
                systemImage: "star.fill",
                earned: lifetimePoints >= 200
            ),
        ]
    }

    static func recapSummary(
        weekNumber: Int,
        earned: Double,
        target: Int,
        met: Bool,
        nextWeeklyTarget: Int?,
        wasRecalibrated: Bool
    ) -> String {
        let pct = weekCompletionPercent(earned: earned, target: target)
        if met {
            var line = "Week \(weekNumber): \(pct)% of goal. Well done."
            if wasRecalibrated, let next = nextWeeklyTarget {
                line += " Next week: \(next) pts."
            } else if let next = nextWeeklyTarget {
                line += " Next week: \(next) pts."
            }
            return line
        }
        return "Week \(weekNumber): \(pct)% of goal. Same target next week. Keep building."
    }

    static func makeSharePayload(
        displayName: String,
        weekNumber: Int,
        earned: Double,
        target: Int,
        streak: Int,
        dateRange: String,
        periodEnd: Date,
        issuedAt: Date = Date()
    ) -> StokeSharePayload {
        let earnedInt = Int(earned.rounded())
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let periodEndDay = Calendar.current.startOfDay(for: periodEnd)
        return StokeSharePayload(
            displayName: trimmedName.isEmpty ? "You" : trimmedName,
            weekNumber: weekNumber,
            earned: earnedInt,
            target: target,
            percent: weekCompletionPercent(earned: earned, target: target),
            streak: streak,
            dateRange: dateRange,
            periodEndDay: periodEndDay,
            issuedAt: issuedAt
        )
    }
}
