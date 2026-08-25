import SwiftUI

/// Mon–Fri (or full week) block view of parsed meetings so split labs/lectures are obvious.
struct WeekScheduleView: View {
    let events: [EditableScheduleEvent]
    var onToggle: (UUID) -> Void

    private let hourHeight: CGFloat = 38
    private let gutter: CGFloat = 28

    private var timed: [EditableScheduleEvent] {
        WeekScheduleLayout.timedEvents(in: events)
    }

    private var visibleDays: [Int] {
        WeekScheduleLayout.visibleDays(for: events)
    }

    private var hourRange: ClosedRange<Int> {
        WeekScheduleLayout.hourRange(for: events)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR WEEK")
                .font(ScheduleTheme.sectionFont)
                .foregroundStyle(ScheduleTheme.inkMuted)
                .tracking(1.2)

            Text("Each block is one calendar event. Same class, different day or time — separate blocks.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(ScheduleTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            if timed.isEmpty {
                Text("Pick days on a class below to see it here.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(ScheduleTheme.amber)
                    .padding(.vertical, 12)
            } else {
                grid
            }
        }
    }

    private var grid: some View {
        let hours = Array(hourRange)
        let startMin = hourRange.lowerBound * 60
        let height = CGFloat(hours.count) * hourHeight

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: gutter)
                ForEach(visibleDays, id: \.self) { day in
                    Text(dayLetter(day))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(ScheduleTheme.inkMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)

            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            Text(hourLabel(hour))
                                .font(.system(size: 9, weight: .medium, design: .rounded).monospacedDigit())
                                .foregroundStyle(ScheduleTheme.inkMuted)
                                .frame(width: gutter, height: hourHeight, alignment: .topTrailing)
                                .padding(.trailing, 4)
                        }
                    }

                    ForEach(visibleDays, id: \.self) { day in
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                            .overlay(alignment: .topLeading) {
                                GeometryReader { geo in
                                    let width = geo.size.width
                                    ZStack(alignment: .topLeading) {
                                        VStack(spacing: 0) {
                                            ForEach(hours, id: \.self) { _ in
                                                Rectangle()
                                                    .fill(ScheduleTheme.hairline)
                                                    .frame(height: 1)
                                                    .frame(maxWidth: .infinity, maxHeight: hourHeight, alignment: .top)
                                            }
                                        }

                                        ForEach(placedBlocks(on: day), id: \.id) { block in
                                            let y = CGFloat(block.startMinutes - startMin) / 60 * hourHeight
                                            let h = max(22, CGFloat(block.endMinutes - block.startMinutes) / 60 * hourHeight - 3)
                                            let colW = width / CGFloat(max(1, block.columnCount))
                                            if let event = events.first(where: { $0.id == block.eventID }) {
                                                Button {
                                                    onToggle(event.id)
                                                } label: {
                                                    blockChip(event, hourSpan: block.endMinutes - block.startMinutes)
                                                }
                                                .buttonStyle(.plain)
                                                .frame(width: max(16, colW - 3), height: h, alignment: .top)
                                                .offset(x: colW * CGFloat(block.column) + 1, y: y)
                                                .opacity(event.isSelected ? 1 : 0.38)
                                            }
                                        }
                                    }
                                }
                            }
                    }
                }
                .frame(height: height)
            }
            .frame(height: min(360, height + 8))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ScheduleTheme.surfaceSolid)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ScheduleTheme.hairline, lineWidth: 1)
        )
    }

    private func blockChip(_ event: EditableScheduleEvent, hourSpan: Int) -> some View {
        let accent = ScheduleTheme.accent(for: event.title)
        return VStack(alignment: .leading, spacing: 1) {
            Text(shortTitle(event.title))
                .font(.system(size: hourSpan >= 60 ? 11 : 10, weight: .bold, design: .rounded))
                .lineLimit(hourSpan >= 90 ? 3 : 2)
            if hourSpan >= 50, let kind = event.sessionKind, kind.isEmpty == false {
                Text(kind)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .opacity(0.9)
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(accent)
        )
    }

    private func placedBlocks(on day: Int) -> [WeekScheduleLayout.PlacedBlock] {
        WeekScheduleLayout.placedBlocks(from: events, on: day, clippingTo: hourRange)
    }

    private func dayLetter(_ weekday: Int) -> String {
        let names = ["S", "M", "T", "W", "T", "F", "S"]
        guard weekday >= 1, weekday <= 7 else { return "?" }
        return names[weekday - 1]
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour >= 12 ? "p" : "a"
        return "\(h)\(suffix)"
    }

    private func shortTitle(_ title: String) -> String {
        let head = title.split(separator: "|").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? title
        if head.count <= 22 { return head }
        return String(head.prefix(20)) + "…"
    }
}
