import SwiftUI

enum ScheduleSuggestion: String, CaseIterable {
    case study = "Study"
    case lunch = "Lunch"
    case workout = "Workout"
    case hangout = "Hangout"
    case catchUp = "Catch up"

    var icon: String {
        switch self {
        case .study: return "book.fill"
        case .lunch: return "fork.knife"
        case .workout: return "figure.run"
        case .hangout: return "person.2.fill"
        case .catchUp: return "bubble.left.and.bubble.right.fill"
        }
    }

    static func forFreeBlock(_ item: TodayPlanItem) -> [ScheduleSuggestion] {
        let hour = item.startMinutes / 60
        var options: [ScheduleSuggestion] = [.study, .hangout]
        if hour >= 11, hour <= 14 { options.insert(.lunch, at: 0) }
        if hour >= 16 { options.append(.workout) }
        if !item.friendOverlaps.isEmpty { options.insert(.catchUp, at: 0) }
        return Array(options.prefix(4))
    }
}

struct ScheduleTimelineRow<Content: View>: View {
    let hourLabel: String
    let nodeColor: Color
    let isLast: Bool
    let content: Content

    init(
        hourLabel: String,
        nodeColor: Color,
        isLast: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.hourLabel = hourLabel
        self.nodeColor = nodeColor
        self.isLast = isLast
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(hourLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
                .padding(.top, 14)

            VStack(spacing: 0) {
                Circle()
                    .fill(nodeColor)
                    .frame(width: 10, height: 10)

                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.22))
                        .frame(width: 2)
                        .frame(minHeight: 48)
                        .padding(.top, 4)
                }
            }
            .frame(width: 10)

            content
                .padding(.bottom, isLast ? 0 : 16)
        }
    }
}

struct ScheduleClassBlock: View {
    let item: TodayPlanItem
    var connections: [ClassConnection] = []
    var isPast: Bool = false
    var showsChevron: Bool = false
    var onTap: (() -> Void)?

    private var section: CourseSection? { item.section }
    private var colors: (fill: Color, accent: Color) {
        SparqTheme.scheduleClassColors(for: section?.courseCode ?? "")
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section?.courseName ?? "Class")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let section {
                        Text("Sec \(section.sectionLabel) · \(section.location)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.timeRangeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if !connections.isEmpty {
                    classAvatarStack
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                } else if isPast {
                    Text("Done")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(colors.fill.opacity(isPast ? 0.55 : 1))
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var classAvatarStack: some View {
        HStack(spacing: -8) {
            ForEach(connections.prefix(3)) { connection in
                FriendAvatarView(name: connection.friendName, friendId: connection.id, size: 28)
            }
            if connections.count > 3 {
                Text("+\(connections.count - 3)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

struct ScheduleFreeBlock: View {
    let item: TodayPlanItem
    var isPast: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SparqTheme.free)
                Text(item.timeRangeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !item.friendOverlaps.isEmpty {
                    Text("\(item.friendOverlaps.count) friend\(item.friendOverlaps.count == 1 ? "" : "s") also free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ScheduleSuggestion.forFreeBlock(item), id: \.rawValue) { suggestion in
                        HStack(spacing: 5) {
                            Image(systemName: suggestion.icon)
                                .font(.caption2)
                            Text(suggestion.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(isPast ? 0.5 : 0.85))
                        .foregroundStyle(SparqTheme.free)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(SparqTheme.freeSoft.opacity(isPast ? 0.45 : 1))
        .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cardRadius, style: .continuous))
    }
}

struct ScheduleDailyInsightCard: View {
    let freeMinutes: Int
    let bestWindowLabel: String?
    let hasFriends: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Daily insight", systemImage: "lightbulb.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SparqTheme.accent)
            Text("You have \(formatMinutes(freeMinutes)) free today.")
                .font(.subheadline.weight(.semibold))
            if let bestWindowLabel, !bestWindowLabel.isEmpty {
                Text("Most friends overlap \(bestWindowLabel). Good time to meet up.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if hasFriends {
                Text("Star friends to see when your free windows line up.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SparqTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cardRadius, style: .continuous))
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0, m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
