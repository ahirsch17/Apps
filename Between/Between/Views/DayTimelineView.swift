import SwiftUI

struct DayTimelineView: View {
    let items: [TodayPlanItem]
    let starredFriendIds: Set<String>
    let friends: [FriendCard]

    private var starredFriends: [FriendCard] {
        friends.filter { starredFriendIds.contains($0.id) }
    }

    private var nextStarredOverlap: (segment: FriendTimelineSegment, block: TodayPlanItem)? {
        for item in items where item.isHighlightableFreeBlock {
            for segment in item.segments(for: starredFriendIds) {
                return (segment, item)
            }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if starredFriends.isEmpty {
                hintRow(
                    icon: "star",
                    text: "Star close friends on the Friends tab to see overlap here."
                )
            } else {
                legend
            }

            if let next = nextStarredOverlap {
                nextChip(segment: next.segment)
            }

            if items.isEmpty {
                Text("Nothing left on today's schedule.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    timelineRow(item)
                }
            }
        }
        .glassCard()
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Today")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            InfoTipButton(
                title: "Your day",
                message: "Colored bars show when you and a starred friend both have 25+ minutes free. Only friends you've added — and allowed — can see your availability. Class matches appear below."
            )
        }
    }

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(starredFriends) { friend in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(FriendColorPalette.color(for: friend.id))
                            .frame(width: 10, height: 10)
                        Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                            .font(.caption.weight(.medium))
                    }
                }
            }
        }
        .accessibilityLabel("Starred friends legend")
    }

    private func nextChip(segment: FriendTimelineSegment) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(FriendColorPalette.color(for: segment.friendId))
                .frame(width: 10, height: 10)
            Text("\(segment.durationMinutes)m with \(segment.friendName.components(separatedBy: " ").first ?? segment.friendName) · \(ScheduleEngine.formatRange(start: segment.startMinutes, end: segment.endMinutes))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FriendColorPalette.color(for: segment.friendId))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(FriendColorPalette.color(for: segment.friendId).opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func timelineRow(_ item: TodayPlanItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(compactTime(item.startMinutes))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                bar(for: item)
                Text(rowLabel(item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: item))
    }

    @ViewBuilder
    private func bar(for item: TodayPlanItem) -> some View {
        let height: CGFloat = item.kind == .classBlock ? 14 : 22

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(baseFill(for: item))
                    .frame(height: height)

                if item.isHighlightableFreeBlock {
                    let segments = item.segments(for: starredFriendIds)
                    ForEach(segments) { segment in
                        segmentBar(segment, in: item, totalWidth: geo.size.width, height: height)
                    }
                }
            }
        }
        .frame(height: height)
    }

    private func segmentBar(_ segment: FriendTimelineSegment, in item: TodayPlanItem, totalWidth: CGFloat, height: CGFloat) -> some View {
        let blockDuration = CGFloat(item.durationMinutes)
        let offsetRatio = CGFloat(segment.startMinutes - item.startMinutes) / blockDuration
        let widthRatio = CGFloat(segment.durationMinutes) / blockDuration
        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(FriendColorPalette.color(for: segment.friendId))
            .frame(width: max(totalWidth * widthRatio, 8), height: height - 4)
            .offset(x: totalWidth * offsetRatio)
    }

    private func baseFill(for item: TodayPlanItem) -> Color {
        switch item.kind {
        case .classBlock:
            return BetweenTheme.neonBlue.opacity(0.55)
        case .freeBlock:
            return item.isHighlightableFreeBlock
                ? Color.primary.opacity(0.08)
                : Color.primary.opacity(0.04)
        }
    }

    private func rowLabel(_ item: TodayPlanItem) -> String {
        switch item.kind {
        case .classBlock:
            if let section = item.section {
                return "\(section.courseCode) · \(section.location)"
            }
            return "Class"
        case .freeBlock:
            let segments = item.segments(for: starredFriendIds)
            if segments.isEmpty {
                return item.durationMinutes >= ScheduleEngine.minFreeBlockMinutes ? "Free" : "Short break"
            }
            return segments.map { "\($0.durationMinutes)m \($0.friendName.components(separatedBy: " ").first ?? $0.friendName)" }.joined(separator: " · ")
        }
    }

    private func compactTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        let ampm = h < 12 ? "a" : "p"
        return m == 0 ? "\(h12)\(ampm)" : "\(h12):\(String(format: "%02d", m))\(ampm)"
    }

    private func hintRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(BetweenTheme.neonAmber)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func accessibilityLabel(for item: TodayPlanItem) -> String {
        "\(rowLabel(item)), \(item.timeRangeLabel)"
    }
}

#Preview {
    DayTimelineView(items: [], starredFriendIds: [], friends: [])
        .padding()
}
