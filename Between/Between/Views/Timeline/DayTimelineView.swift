import SwiftUI

struct DayTimelineView: View {
    let entries: [TodayPresenter.TimelineEntry]
    var onClassFriendsTap: ((CourseSection) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your classes", subtitle: "Tap classmates to see who's in your section")

            if entries.isEmpty {
                Text("No more classes today — you're done!")
                    .font(BetweenFont.secondary())
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { Divider().padding(.leading, 52) }
                        timelineRow(entry)
                    }
                }
            }
        }
        .surfaceCard()
    }

    @ViewBuilder
    private func timelineRow(_ entry: TodayPresenter.TimelineEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            timeColumn(for: entry)
            contentColumn(for: entry)
        }
        .padding(.vertical, 12)
    }

    private func timeColumn(for entry: TodayPresenter.TimelineEntry) -> some View {
        let (start, end) = timeRange(for: entry)
        return VStack(alignment: .trailing, spacing: 2) {
            Text(compactTime(start))
                .font(BetweenFont.captionMedium().monospacedDigit())
            Text(compactTime(end))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(width: 48, alignment: .trailing)
    }

    @ViewBuilder
    private func contentColumn(for entry: TodayPresenter.TimelineEntry) -> some View {
        switch entry {
        case .classBlock(let item):
            classRow(item)
        case .freeWithFriends:
            EmptyView()
        case .soloBreak:
            HStack(spacing: 8) {
                Image(systemName: "cup.and.saucer")
                    .foregroundStyle(.secondary)
                Text("Open block — no class")
                    .font(BetweenFont.secondary())
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func classRow(_ item: TodayPlanItem) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let section = item.section {
                    Text(section.courseCode)
                        .font(BetweenFont.cardTitle())
                    Text(section.courseName)
                        .font(BetweenFont.caption())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text("Sec \(section.sectionLabel) · \(section.location)")
                        .font(BetweenFont.caption())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let section = item.section {
                Button { onClassFriendsTap?(section) } label: {
                    Image(systemName: "person.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BetweenTheme.accent)
                        .frame(width: 40, height: 40)
                        .background(BetweenTheme.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .accessibilityLabel("See classmates")
            }
        }
    }

    private func timeRange(for entry: TodayPresenter.TimelineEntry) -> (Int, Int) {
        switch entry {
        case .classBlock(let item): return (item.startMinutes, item.endMinutes)
        case .freeWithFriends(let start, let end, _): return (start, end)
        case .soloBreak(let start, let end): return (start, end)
        }
    }

    private func compactTime(_ minutes: Int) -> String {
        ScheduleEngine.formatTime12Hour(minutes)
            .replacingOccurrences(of: " AM", with: "a")
            .replacingOccurrences(of: " PM", with: "p")
    }
}

#Preview {
    DayTimelineView(entries: [])
        .padding()
}
