import SwiftUI

/// Central overlap board: 8am–7pm horizontal axis, up to 4 favorite-friend rows,
/// colored overlap blocks, class blocks blocking all rows, live now indicator.
struct DayOverlapBoardView: View {
    let todayPlan: [TodayPlanItem]
    let starredIds: Set<String>

    @Environment(\.colorScheme) private var colorScheme

    private let labelWidth: CGFloat = 42
    private let rowHeight: CGFloat = 40
    private let rowSpacing: CGFloat = 8
    /// Wider timeline so a few hours fill the screen; scroll for the rest of the day.
    private let pointsPerMinute: CGFloat = 3.4

    private static let rowColors: [Color] = [
        Color(red: 0.35, green: 0.78, blue: 0.55),
        Color(red: 0.95, green: 0.55, blue: 0.35),
        Color(red: 0.40, green: 0.62, blue: 0.95),
        Color(red: 0.75, green: 0.45, blue: 0.88),
    ]

    private var board: OverlapTimelineModel.Board {
        OverlapTimelineModel.build(from: todayPlan, starredIds: starredIds)
    }

    private var nowMinutes: Int {
        BackendConfiguration.nowMinutes()
    }

    private var trackContentWidth: CGFloat {
        CGFloat(board.dayRange.upperBound - board.dayRange.lowerBound) * pointsPerMinute
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            boardContent
        }
    }

    private var boardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if board.friendRows.isEmpty {
                emptyBoard
            } else {
                timelineGrid
                overlapSummaryChart
            }
        }
        .padding(18)
        .background(BetweenTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: BetweenTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BetweenTheme.cornerRadius, style: .continuous)
                .strokeBorder(BetweenTheme.surfaceMuted(colorScheme), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's overlap")
                    .font(.headline.weight(.semibold))
                Text("Swipe for your full day · 8am – 7pm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if nowMinutes >= board.dayRange.lowerBound, nowMinutes <= board.dayRange.upperBound {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Now")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(ScheduleEngine.formatTime12Hour(nowMinutes))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(BetweenTheme.accentAction)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(BetweenTheme.accentActionSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var timelineGrid: some View {
        let gridHeight = CGFloat(board.friendRows.count) * rowHeight
            + CGFloat(max(0, board.friendRows.count - 1)) * rowSpacing

        return HStack(alignment: .top, spacing: 8) {
            VStack(spacing: rowSpacing) {
                Color.clear.frame(height: 28)
                ForEach(board.friendRows) { row in
                    Text(row.firstName)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: labelWidth, height: rowHeight, alignment: .trailing)
                        .foregroundStyle(rowColor(for: row))
                }
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 0) {
                        scrollTimeAxis
                            .padding(.bottom, 6)

                        ZStack(alignment: .topLeading) {
                            VStack(spacing: rowSpacing) {
                                ForEach(board.friendRows) { row in
                                    timelineTrack(row: row, color: rowColor(for: row), width: trackContentWidth)
                                        .frame(height: rowHeight)
                                }
                            }

                            nowIndicator(totalHeight: gridHeight, width: trackContentWidth)

                            Color.clear
                                .frame(width: 1, height: 1)
                                .id("nowScrollAnchor")
                                .offset(
                                    x: OverlapTimelineModel.xOffset(
                                        for: nowMinutes,
                                        totalWidth: trackContentWidth,
                                        range: board.dayRange
                                    )
                                )
                        }
                        .frame(width: trackContentWidth, height: gridHeight)
                    }
                }
                .onAppear {
                    scrollToNow(proxy, animated: false)
                }
            }
        }
    }

    private func scrollToNow(_ proxy: ScrollViewProxy, animated: Bool) {
        guard nowMinutes >= board.dayRange.lowerBound, nowMinutes <= board.dayRange.upperBound else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo("nowScrollAnchor", anchor: .center)
            }
        } else {
            proxy.scrollTo("nowScrollAnchor", anchor: .center)
        }
    }

    private var scrollTimeAxis: some View {
        ZStack(alignment: .topLeading) {
            ForEach(OverlapTimelineModel.hourMarkers, id: \.self) { minutes in
                let x = OverlapTimelineModel.xOffset(
                    for: minutes,
                    totalWidth: trackContentWidth,
                    range: board.dayRange
                )
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 1, height: 4)
                    Text(shortHour(minutes / 60))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .offset(x: x - 12, y: 0)
            }
        }
        .frame(width: trackContentWidth, height: 22, alignment: .topLeading)
    }

    private func timelineTrack(row: OverlapTimelineModel.FriendRow, color: Color, width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(BetweenTheme.surfaceMuted(colorScheme).opacity(0.55))

            ForEach(board.classBlocks) { block in
                classBlockView(block, width: width)
            }

            ForEach(row.overlapBlocks) { block in
                overlapBlockView(block, color: color, width: width)
            }
        }
        .frame(width: width, height: rowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func classBlockView(_ block: OverlapTimelineModel.TimeBlock, width: CGFloat) -> some View {
        let x = OverlapTimelineModel.xOffset(for: block.startMinutes, totalWidth: width, range: board.dayRange)
        let w = OverlapTimelineModel.width(
            for: block.startMinutes,
            end: block.endMinutes,
            totalWidth: width,
            range: board.dayRange
        )

        return ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.22 : 0.12))
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)

            if w > 36, let label = block.label {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 4)
                    .frame(width: max(w - 4, 0))
            }
        }
        .frame(width: max(w, 6), height: rowHeight - 6)
        .offset(x: x)
    }

    private func overlapBlockView(
        _ block: OverlapTimelineModel.TimeBlock,
        color: Color,
        width: CGFloat
    ) -> some View {
        let x = OverlapTimelineModel.xOffset(for: block.startMinutes, totalWidth: width, range: board.dayRange)
        let w = OverlapTimelineModel.width(
            for: block.startMinutes,
            end: block.endMinutes,
            totalWidth: width,
            range: board.dayRange
        )
        let label = w > 52
            ? ScheduleEngine.formatRange(start: block.startMinutes, end: block.endMinutes)
            : nil

        return ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.opacity(0.88))
            if let label {
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 3)
                    .frame(width: max(w - 4, 0))
            }
        }
        .frame(width: max(w, 8), height: rowHeight - 8)
        .offset(x: x + 1)
    }

    private func nowIndicator(totalHeight: CGFloat, width: CGFloat) -> some View {
        Group {
            if nowMinutes >= board.dayRange.lowerBound, nowMinutes <= board.dayRange.upperBound {
                let x = OverlapTimelineModel.xOffset(for: nowMinutes, totalWidth: width, range: board.dayRange)
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(BetweenTheme.accentAction)
                        .frame(width: 2, height: totalHeight + 4)
                    Circle()
                        .fill(BetweenTheme.accentAction)
                        .frame(width: 8, height: 8)
                        .offset(y: -4)
                }
                .offset(x: x - 1)
            }
        }
        .allowsHitTesting(false)
    }

    private var overlapSummaryChart: some View {
        let maxMinutes = board.friendRows.map(\.totalOverlapMinutes).max() ?? 1

        return DisclosureGroup {
            VStack(spacing: 6) {
                ForEach(board.friendRows) { row in
                    HStack(spacing: 8) {
                        Text(row.firstName)
                            .font(.caption2)
                            .frame(width: labelWidth, alignment: .trailing)

                        GeometryReader { geo in
                            let barWidth = geo.size.width * CGFloat(row.totalOverlapMinutes) / CGFloat(maxMinutes)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(rowColor(for: row))
                                .frame(width: max(barWidth, 4), height: 10)
                        }
                        .frame(height: 10)
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Overlap minutes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func rowColor(for row: OverlapTimelineModel.FriendRow) -> Color {
        if row.colorIndex < Self.rowColors.count {
            return Self.rowColors[row.colorIndex]
        }
        return FriendColorPalette.color(for: row.id)
    }

    private var emptyBoard: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.circle")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Star close friends to see overlap rows")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !board.classBlocks.isEmpty {
                Text("\(board.classBlocks.count) class\(board.classBlocks.count == 1 ? "" : "es") on your schedule today")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func shortHour(_ hour: Int) -> String {
        if hour == 12 { return "12p" }
        if hour > 12 { return "\(hour - 12)p" }
        return "\(hour)a"
    }
}

#Preview {
    ScrollView {
        DayOverlapBoardView(todayPlan: [], starredIds: [])
            .padding()
    }
}
