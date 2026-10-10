import SwiftUI

/// Schedule tab: stacked colored blocks with a left time gutter (no dot timeline).
struct MockupScheduleStack: View {
    let plan: [TodayPlanItem]
    let connectionsFor: (CourseSection) -> [ClassConnection]
    let onClassTap: (CourseSection) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(plan) { item in
                scheduleRow(item)
            }
        }
    }

    private func scheduleRow(_ item: TodayPlanItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(timeColumn(for: item))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 54, alignment: .trailing)
                .padding(.top, 14)

            block(for: item)
                .frame(maxWidth: .infinity)
        }
    }

    private func timeColumn(for item: TodayPlanItem) -> String {
        let start = ScheduleEngine.formatTime12Hour(item.startMinutes)
        let end = ScheduleEngine.formatTime12Hour(item.endMinutes)
        return "\(start)\n\(end)"
    }

    @ViewBuilder
    private func block(for item: TodayPlanItem) -> some View {
        switch item.kind {
        case .classBlock:
            classBlock(item)
        case .freeBlock:
            freeBlock(item)
        }
    }

    private func classBlock(_ item: TodayPlanItem) -> some View {
        let section = item.section
        let colors = SparqTheme.scheduleClassColors(for: section?.courseCode ?? "")
        let connections = section.map(connectionsFor) ?? []

        return Button {
            if let section { onClassTap(section) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(section?.courseName ?? "Class")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let section {
                    Text("Sec \(section.sectionLabel) · \(section.location)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(item.timeRangeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !connections.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(connections.prefix(4)) { connection in
                            FriendAvatarView(name: connection.friendName, friendId: connection.id, size: 26)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(minHeight: blockHeight(for: item))
            .background(colors.fill)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func freeBlock(_ item: TodayPlanItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Free")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SparqTheme.free)
            Text(item.timeRangeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !item.friendOverlaps.isEmpty {
                HStack(spacing: -8) {
                    ForEach(item.friendOverlaps.prefix(3)) { overlap in
                        FriendAvatarView(name: overlap.friendName, friendId: overlap.friendId, size: 28, showsFreeRing: true)
                    }
                }
                Text("\(item.friendOverlaps.count) friends free")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(ScheduleSuggestion.forFreeBlock(item), id: \.rawValue) { suggestion in
                    HStack(spacing: 4) {
                        Image(systemName: suggestion.icon)
                            .font(.caption2)
                        Text(suggestion.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.9))
                    .foregroundStyle(SparqTheme.free)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(minHeight: max(blockHeight(for: item), 120))
        .background(SparqTheme.freeSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func blockHeight(for item: TodayPlanItem) -> CGFloat {
        let scaled = CGFloat(item.durationMinutes) * 1.1
        return min(max(scaled, 78), 148)
    }
}

struct MockupDailyInsight: View {
    let freeMinutes: Int
    let overlapHint: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(SparqTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily insight")
                    .font(.subheadline.weight(.semibold))
                Text("You have \(formatMinutes(freeMinutes)) free today.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let overlapHint {
                    Text(overlapHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SparqTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0, m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
