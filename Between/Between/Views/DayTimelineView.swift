import SwiftUI

struct DayTimelineView: View {
    let items: [TodayPlanItem]
    let starredFriendIds: Set<String>
    let friends: [FriendCard]
    var onClassFriendsTap: ((CourseSection) -> Void)?

    private var starredFriends: [FriendCard] {
        friends.filter { starredFriendIds.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your schedule")
                    .font(.headline)
                Spacer()
                InfoTipButton(
                    title: "Free time overlap",
                    message: "Green and colored segments show 25+ minutes when you and a starred friend are both free. Tap the people icon on a class to see friends in that course."
                )
            }

            if starredFriends.isEmpty {
                Text("Star close friends in your network (top right) to highlight overlap here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 12) {
                    ForEach(starredFriends) { friend in
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(FriendColorPalette.color(for: friend.id))
                                .frame(width: 12, height: 12)
                            Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                                .font(.caption.weight(.medium))
                        }
                    }
                }
            }

            if items.isEmpty {
                Text("Nothing left on today's schedule.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider().padding(.leading, 52)
                        }
                        timelineRow(item)
                    }
                }
            }
        }
        .surfaceCard()
    }

    @ViewBuilder
    private func timelineRow(_ item: TodayPlanItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(compactTime(item.startMinutes))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                bar(for: item)
                HStack {
                    Text(rowLabel(item))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                    if item.kind == .classBlock, let section = item.section {
                        Button {
                            onClassFriendsTap?(section)
                        } label: {
                            Image(systemName: "person.2")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BetweenTheme.neonBlue)
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("Friends in \(section.courseCode)")
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: item))
    }

    @ViewBuilder
    private func bar(for item: TodayPlanItem) -> some View {
        let height: CGFloat = item.kind == .classBlock ? 12 : 28

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(baseFill(for: item))
                    .frame(height: height)

                if item.isHighlightableFreeBlock {
                    ForEach(item.segments(for: starredFriendIds)) { segment in
                        segmentBar(segment, in: item, totalWidth: geo.size.width, height: height)
                    }
                }
            }
        }
        .frame(height: height)
    }

    private func segmentBar(_ segment: FriendTimelineSegment, in item: TodayPlanItem, totalWidth: CGFloat, height: CGFloat) -> some View {
        let blockDuration = max(CGFloat(item.durationMinutes), 1)
        let offsetRatio = CGFloat(segment.startMinutes - item.startMinutes) / blockDuration
        let widthRatio = CGFloat(segment.durationMinutes) / blockDuration
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(FriendColorPalette.color(for: segment.friendId))
            .frame(width: max(totalWidth * widthRatio, 10), height: height - 2)
            .offset(x: totalWidth * offsetRatio)
    }

    private func baseFill(for item: TodayPlanItem) -> Color {
        switch item.kind {
        case .classBlock:
            return BetweenTheme.neonBlue.opacity(0.35)
        case .freeBlock:
            return item.isHighlightableFreeBlock
                ? BetweenTheme.neonMint.opacity(0.18)
                : Color.primary.opacity(0.06)
        }
    }

    private func rowLabel(_ item: TodayPlanItem) -> String {
        switch item.kind {
        case .classBlock:
            if let section = item.section {
                return "\(section.courseCode) · Sec \(section.sectionLabel) · \(section.location)"
            }
            return "Class"
        case .freeBlock:
            let segments = item.segments(for: starredFriendIds)
            if segments.isEmpty {
                return item.durationMinutes >= ScheduleEngine.minFreeBlockMinutes
                    ? "Free · \(item.durationMinutes) min"
                    : "Short break"
            }
            return "Free with " + segments.map {
                "\($0.friendName.components(separatedBy: " ").first ?? $0.friendName) (\($0.durationMinutes)m)"
            }.joined(separator: ", ")
        }
    }

    private func compactTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        let ampm = h < 12 ? "a" : "p"
        return m == 0 ? "\(h12)\(ampm)" : "\(h12):\(String(format: "%02d", m))\(ampm)"
    }

    private func accessibilityLabel(for item: TodayPlanItem) -> String {
        "\(rowLabel(item)), \(item.timeRangeLabel)"
    }
}

#Preview {
    DayTimelineView(items: [], starredFriendIds: [], friends: [])
        .padding()
}
