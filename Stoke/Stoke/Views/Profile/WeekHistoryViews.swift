import SwiftData
import SwiftUI

struct WeekHistoryRowView: View {
    let dateRange: String
    let weekTitle: String
    let isShortWeek: Bool
    let target: Int
    let earned: Double
    let inProgress: Bool
    let met: Bool?

    var body: some View {
        let earnedInt = Int(earned.rounded())
        let pct = GamificationEngine.weekCompletionPercent(earned: earned, target: target)

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateRange)
                        .font(.headline)
                        .foregroundStyle(StokeTheme.ink)

                    HStack(spacing: 6) {
                        Text(weekTitle)
                            .font(.subheadline)
                            .foregroundStyle(StokeTheme.inkMuted)

                        if isShortWeek {
                            Text("Short week")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(StokeTheme.parchment)
                                .foregroundStyle(StokeTheme.terracottaDeep)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer(minLength: 8)

                statusLabel
            }

            Text("\(earnedInt) / \(target) pts · \(pct)%")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(StokeTheme.ink)

            ProgressView(value: min(earned / Double(max(target, 1)), 1.0))
                .tint(met == true ? StokeTheme.sage : StokeTheme.terracotta)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var statusLabel: some View {
        Group {
            if inProgress {
                Text("In progress")
                    .foregroundStyle(StokeTheme.terracotta)
            } else if met == true {
                Text("Complete")
                    .foregroundStyle(StokeTheme.sage)
            } else {
                Text("Incomplete")
                    .foregroundStyle(StokeTheme.inkMuted)
            }
        }
        .font(.caption.weight(.semibold))
    }
}

struct WeekHistoryDetailSheet: View {
    let item: WeekHistoryDetailItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerBlock
                    statsBlock
                    if let summary = item.summary {
                        detailSection(title: "Summary") {
                            Text(summary)
                                .font(.subheadline)
                                .foregroundStyle(StokeTheme.ink)
                        }
                    }
                    if let nextTarget = item.nextWeeklyTarget, item.metTarget == true {
                        detailSection(title: "Next week") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(nextTarget) pts")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(StokeTheme.terracottaDeep)
                                if item.wasRecalibrated {
                                    Text("Goal recalibrated based on how much you earned.")
                                        .font(.caption)
                                        .foregroundStyle(StokeTheme.inkMuted)
                                } else {
                                    Text("Small bump for hitting this week’s goal.")
                                        .font(.caption)
                                        .foregroundStyle(StokeTheme.inkMuted)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(StokeTheme.cream)
            .navigationTitle("Week details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.dateRange)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(StokeTheme.ink)

            HStack(spacing: 8) {
                Text(item.weekTitle)
                    .font(.subheadline)
                    .foregroundStyle(StokeTheme.inkMuted)
                if item.isShortWeek {
                    Text("Short week")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(StokeTheme.parchment)
                        .foregroundStyle(StokeTheme.terracottaDeep)
                        .clipShape(Capsule())
                }
            }

            Text(item.statusText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(item.statusColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .stokeCard()
    }

    private var statsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                statTile(
                    title: "Points",
                    value: "\(Int(item.earned.rounded())) / \(item.target)"
                )
                statTile(
                    title: "Of goal",
                    value: "\(item.percent)%"
                )
            }
            ProgressView(value: min(item.earned / Double(max(item.target, 1)), 1.0))
                .tint(item.metTarget == true ? StokeTheme.sage : StokeTheme.terracotta)
        }
        .stokeCard()
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(StokeTheme.inkMuted)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(StokeTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(StokeTheme.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .stokeCard()
    }
}

struct WeekHistoryDetailItem: Identifiable {
    let id: String
    let dateRange: String
    let weekTitle: String
    let isShortWeek: Bool
    let target: Int
    let earned: Double
    let inProgress: Bool
    let metTarget: Bool?
    let summary: String?
    let nextWeeklyTarget: Int?
    let wasRecalibrated: Bool

    var percent: Int {
        GamificationEngine.weekCompletionPercent(earned: earned, target: target)
    }

    var statusText: String {
        if inProgress { return "In progress" }
        if metTarget == true { return "Complete" }
        return "Incomplete"
    }

    var statusColor: Color {
        if inProgress { return StokeTheme.terracotta }
        if metTarget == true { return StokeTheme.sage }
        return StokeTheme.inkMuted
    }

    @MainActor
    static func current(programStore: ProgramStore) -> WeekHistoryDetailItem {
        let period = programStore.currentPeriod
        let earned = programStore.weekPoints
        let target = programStore.periodTarget
        let pct = GamificationEngine.weekCompletionPercent(earned: earned, target: target)

        return WeekHistoryDetailItem(
            id: "current",
            dateRange: WeekHistoryFormatting.dateRange(start: period.start, end: period.end),
            weekTitle: WeekHistoryFormatting.weekTitle(
                weekNumber: programStore.weekNumber,
                attempt: 1,
                showAttempt: false
            ),
            isShortWeek: period.dayCount < 7,
            target: target,
            earned: earned,
            inProgress: true,
            metTarget: nil,
            summary: "Week in progress: \(pct)% of goal so far.",
            nextWeeklyTarget: nil,
            wasRecalibrated: false
        )
    }

    static func archived(
        record: WeekHistoryRecord,
        recaps: [WeekRecapRecord],
        attempt: Int,
        showAttempt: Bool
    ) -> WeekHistoryDetailItem {
        let recap = WeekHistoryFormatting.recap(for: record.endDate, in: recaps)
        let summary = recap?.summary ?? GamificationEngine.recapSummary(
            weekNumber: record.weekNumber,
            earned: record.pointsEarned,
            target: record.periodTarget,
            met: record.metTarget,
            nextWeeklyTarget: recap?.nextWeeklyTarget,
            wasRecalibrated: record.wasRecalibrated
        )

        return WeekHistoryDetailItem(
            id: "archived-\(record.endDate.timeIntervalSince1970)",
            dateRange: WeekHistoryFormatting.dateRange(start: record.startDate, end: record.endDate),
            weekTitle: WeekHistoryFormatting.weekTitle(
                weekNumber: record.weekNumber,
                attempt: attempt,
                showAttempt: showAttempt
            ),
            isShortWeek: record.dayCount < 7,
            target: record.periodTarget,
            earned: record.pointsEarned,
            inProgress: false,
            metTarget: record.metTarget,
            summary: summary,
            nextWeeklyTarget: recap?.nextWeeklyTarget,
            wasRecalibrated: record.wasRecalibrated
        )
    }
}
