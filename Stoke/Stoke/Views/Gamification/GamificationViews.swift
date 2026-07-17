import SwiftUI

struct BadgeCabinetView: View {
    let badgesEarned: Int
    let currentBadgeIndex: Int
    let tilesCompleted: Int
    let tilesRequired: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Badge \(currentBadgeIndex)")
                        .font(.headline)
                    Text(BadgeCycle.badgeTitle(earnedCount: badgesEarned))
                        .font(.caption)
                        .foregroundStyle(StokeTheme.inkMuted)
                }
                Spacer()
                Text("\(tilesCompleted)/\(tilesRequired)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(StokeTheme.terracottaDeep)
            }

            HStack(spacing: 8) {
                ForEach(0..<tilesRequired, id: \.self) { index in
                    tile(index: index)
                }
            }

            if badgesEarned > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "seal.fill")
                        .foregroundStyle(StokeTheme.sage)
                    Text("\(badgesEarned) badge\(badgesEarned == 1 ? "" : "s") earned")
                        .font(.caption)
                        .foregroundStyle(StokeTheme.inkMuted)
                }
            }
        }
    }

    @ViewBuilder
    private func tile(index: Int) -> some View {
        let filled = index < tilesCompleted
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(filled ? StokeTheme.terracotta.opacity(0.85) : StokeTheme.paceTrack.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .overlay {
                if filled {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(StokeTheme.inkMuted)
                }
            }
    }
}

struct MilestoneBadgesRow: View {
    let milestones: [MilestoneBadge]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(milestones) { badge in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(badge.earned ? StokeTheme.sage.opacity(0.25) : StokeTheme.paceTrack.opacity(0.6))
                                .frame(width: 44, height: 44)
                            Image(systemName: badge.systemImage)
                                .font(.body)
                                .foregroundStyle(badge.earned ? StokeTheme.sage : StokeTheme.inkMuted.opacity(0.45))
                        }
                        Text(badge.title)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(badge.earned ? StokeTheme.ink : StokeTheme.inkMuted)
                            .multilineTextAlignment(.center)
                            .frame(width: 72)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

struct WeekRecapCardView: View {
    let recap: WeekRecapRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Week \(recap.weekNumber) recap")
                    .font(.headline)
                Spacer()
                Text(recap.metTarget ? "Complete" : "Incomplete")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(recap.metTarget ? StokeTheme.sage : StokeTheme.inkMuted)
            }

            Text(recap.summary)
                .font(.subheadline)
                .foregroundStyle(StokeTheme.ink)

            HStack(spacing: 16) {
                Label("\(Int(recap.pointsEarned.rounded())) pts", systemImage: "circle.fill")
            }
            .font(.caption)
            .foregroundStyle(StokeTheme.inkMuted)
        }
        .padding(.vertical, 4)
    }
}

struct StreakSummaryView: View {
    let consecutiveWeeks: Int
    let bestStreak: Int

    var body: some View {
        HStack(spacing: 0) {
            statBlock(value: "\(consecutiveWeeks)", label: "Goal streak", icon: "flame.fill")
            Divider().frame(height: 36)
            statBlock(value: "\(bestStreak)", label: "Best streak", icon: "trophy.fill")
        }
        .padding(.vertical, 4)
    }

    private func statBlock(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(StokeTheme.terracotta)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(StokeTheme.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
