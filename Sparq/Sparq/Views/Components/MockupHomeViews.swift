import SwiftUI

// MARK: - Week strip (Mon Apr 28 + calendar icon)

struct MockupWeekStrip: View {
    @Binding var selectedDay: Date
    private let calendar = Calendar.current

    private var weekDays: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: selectedDay)?.start ?? selectedDay
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(weekDays, id: \.self) { day in
                        dayButton(day)
                    }
                }
            }

            Button {} label: {
                Image(systemName: "calendar")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SparqTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(SparqTheme.accentSoft)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func dayButton(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        return Button { selectedDay = day } label: {
            if isSelected {
                VStack(spacing: 2) {
                    Text(shortWeekday(day))
                        .font(.caption2.weight(.semibold))
                    Text("\(calendar.component(.day, from: day))")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(SparqTheme.accent)
                .clipShape(Capsule())
            } else {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(.plain)
    }

    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Glance card

struct MockupGlanceCard: View {
    let freeTimeLabel: String
    let gapCount: Int
    let friendsFree: [FriendCard]
    let onFindSomething: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today at a glance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SparqTheme.accent)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.trailing, 88)

                if friendsFree.isEmpty {
                    Text("Friends show up here when they're free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: -8) {
                        ForEach(friendsFree.prefix(3)) { friend in
                            FriendAvatarView(name: friend.name, friendId: friend.id, size: 30, showsFreeRing: true)
                        }
                    }
                    Text("\(friendsFree.count) friend\(friendsFree.count == 1 ? "" : "s") free")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Button(action: onFindSomething) {
                    Text("Find something to do")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(SparqTheme.accent)
                .clipShape(Capsule())
            }
            .padding(18)

            glanceIllustration
                .padding(.top, 36)
                .padding(.trailing, 12)
        }
        .background(SparqTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var subtitle: String {
        guard gapCount > 0 else { return "Your classes fill most of the day." }
        let gaps = gapCount == 1 ? "1 gap" : "\(gapCount) gaps"
        return "You have \(freeTimeLabel) free between classes across \(gaps)."
    }

    private var glanceIllustration: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 78, height: 78)
            Image(systemName: "figure.volleyball")
                .font(.system(size: 34))
                .foregroundStyle(SparqTheme.accent)
        }
    }
}

// MARK: - Home timeline (dot + text, not cards)

struct MockupHomeTimeline: View {
    let items: [TodayPlanItem]
    let connectionsFor: (CourseSection) -> [ClassConnection]
    let onClassTap: (CourseSection) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                homeRow(item, isLast: index == items.count - 1)
            }
        }
    }

    private func homeRow(_ item: TodayPlanItem, isLast: Bool) -> some View {
        let nodeColor = item.kind == .classBlock ? SparqTheme.accent : SparqTheme.free
        let connections = item.section.map(connectionsFor) ?? []

        return HStack(alignment: .top, spacing: 10) {
            Text(ScheduleEngine.formatTime12Hour(item.startMinutes))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
                .padding(.top, 2)

            VStack(spacing: 0) {
                Circle()
                    .fill(nodeColor)
                    .frame(width: 10, height: 10)
                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 2)
                        .frame(minHeight: 36)
                        .padding(.top, 4)
                }
            }
            .frame(width: 10)

            rowContent(item, connections: connections)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isLast ? 0 : 18)
        }
    }

    @ViewBuilder
    private func rowContent(_ item: TodayPlanItem, connections: [ClassConnection]) -> some View {
        switch item.kind {
        case .classBlock:
            Button {
                if let section = item.section { onClassTap(section) }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.section?.courseName ?? "Class")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        if let section = item.section {
                            Text("Sec \(section.sectionLabel) · \(section.location)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    if !connections.isEmpty {
                        homeAvatarStack(connections)
                    }
                }
            }
            .buttonStyle(.plain)
        case .freeBlock:
            Text("Free (\(formatDuration(item.durationMinutes)))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SparqTheme.free)
                .padding(.top, 2)
        }
    }

    private func homeAvatarStack(_ connections: [ClassConnection]) -> some View {
        HStack(spacing: -8) {
            ForEach(connections.prefix(3)) { connection in
                FriendAvatarView(name: connection.friendName, friendId: connection.id, size: 26)
            }
            if connections.count > 3 {
                Text("+\(connections.count - 3)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0, m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Who's in your classes

struct MockupWhoInClassesSection: View {
    let sections: [CourseSection]
    let connectionsFor: (CourseSection) -> [ClassConnection]
    let onTap: (CourseSection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who's in your classes")
                .font(.headline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sections) { section in
                        whoCard(section)
                    }
                }
            }
        }
    }

    private func whoCard(_ section: CourseSection) -> some View {
        let connections = connectionsFor(section)
        return Button { onTap(section) } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(section.courseCode)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SparqTheme.accent)
                HStack(spacing: -8) {
                    ForEach(connections.prefix(4)) { connection in
                        FriendAvatarView(name: connection.friendName, friendId: connection.id, size: 30)
                    }
                    if connections.count > 4 {
                        Text("+\(connections.count - 4)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 6)
                    }
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}
