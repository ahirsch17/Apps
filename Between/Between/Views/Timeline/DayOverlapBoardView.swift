import SwiftUI
import Charts

/// Central overlap board: 8am–7pm horizontal axis, up to 4 favorite-friend rows,
/// colored overlap blocks, class blocks blocking all rows, live now indicator.
struct DayOverlapBoardView: View {
    let todayPlan: [TodayPlanItem]
    let starredIds: Set<String>

    @Environment(\.colorScheme) private var colorScheme

    private let labelWidth: CGFloat = 54
    private let rowHeight: CGFloat = 34
    private let rowSpacing: CGFloat = 8

    private var board: OverlapTimelineModel.Board {
        OverlapTimelineModel.build(from: todayPlan, starredIds: starredIds)
    }

    private var nowMinutes: Int {
        BackendConfiguration.demoNowMinutes
            ?? (Calendar.current.component(.hour, from: Date()) * 60
                + Calendar.current.component(.minute, from: Date()))
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.07), radius: 14, y: 5)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's overlap")
                    .font(.headline.weight(.semibold))
                Text("8am – 7pm · shared free time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if nowMinutes >= board.dayRange.lowerBound, nowMinutes <= board.dayRange.upperBound {
                Text(ScheduleEngine.formatTime12Hour(nowMinutes))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(BetweenTheme.accentAction)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(BetweenTheme.accentActionSoft)
                    .clipShape(Capsule())
            }
        }
    }

    private var timelineGrid: some View {
        let gridHeight = CGFloat(board.friendRows.count) * rowHeight
            + CGFloat(max(0, board.friendRows.count - 1)) * rowSpacing

        return VStack(spacing: 0) {
            timeAxis
                .padding(.leading, labelWidth + 8)
                .padding(.bottom, 6)

            ZStack(alignment: .topLeading) {
                VStack(spacing: rowSpacing) {
                    ForEach(board.friendRows) { row in
                        friendRow(row)
                    }
                }

                nowIndicator(totalHeight: gridHeight)
                    .padding(.leading, labelWidth + 8)
            }
        }
    }

    private var timeAxis: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .topLeading) {
                ForEach(OverlapTimelineModel.hourMarkers, id: \.self) { minutes in
                    let x = OverlapTimelineModel.xOffset(
                        for: minutes,
                        totalWidth: width,
                        range: board.dayRange
                    )
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 1, height: 4)
                        Text(shortHour(minutes / 60))
                            .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .position(x: x, y: 10)
                }
            }
        }
        .frame(height: 22)
    }

    private func friendRow(_ row: OverlapTimelineModel.FriendRow) -> some View {
        HStack(spacing: 8) {
            Text(row.firstName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: labelWidth, alignment: .trailing)
                .foregroundStyle(row.color)

            timelineTrack(row: row)
        }
    }

    private func timelineTrack(row: OverlapTimelineModel.FriendRow) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(BetweenTheme.surfaceMuted(colorScheme).opacity(0.55))

                ForEach(board.classBlocks) { block in
                    classBlockView(block, width: width)
                }

                ForEach(row.overlapBlocks) { block in
                    overlapBlockView(block, color: row.color, width: width)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(height: rowHeight)
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
                    .frame(width: w - 4)
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
                    .frame(width: w - 4)
            }
        }
        .frame(width: max(w, 8), height: rowHeight - 8)
        .offset(x: x + 1)
    }

    private func nowIndicator(totalHeight: CGFloat) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            if nowMinutes >= board.dayRange.lowerBound, nowMinutes <= board.dayRange.upperBound {
                let x = OverlapTimelineModel.xOffset(for: nowMinutes, totalWidth: width, range: board.dayRange)
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(BetweenTheme.accentAction)
                        .frame(width: 2, height: totalHeight + 4)
                        .shadow(color: BetweenTheme.accentAction.opacity(0.5), radius: 3)
                    Circle()
                        .fill(BetweenTheme.accentAction)
                        .frame(width: 8, height: 8)
                        .offset(y: -4)
                }
                .offset(x: x - 1)
            }
        }
        .frame(height: totalHeight)
        .allowsHitTesting(false)
    }

    private var overlapSummaryChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overlap minutes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Chart(board.friendRows) { row in
                BarMark(
                    x: .value("Minutes", row.totalOverlapMinutes),
                    y: .value("Friend", row.firstName)
                )
                .foregroundStyle(row.color.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .frame(height: CGFloat(board.friendRows.count) * 28 + 16)
        }
        .padding(.top, 4)
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
