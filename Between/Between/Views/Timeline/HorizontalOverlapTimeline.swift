import SwiftUI

/// Horizontal timeline showing your classes and friend free-time overlaps
/// Each friend is a row, colored blocks show when they're free during YOUR free time
struct HorizontalOverlapTimeline: View {
    let todayPlan: [TodayPlanItem]
    let starredIds: Set<String>
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentTime = Date()
    
    private var nowMinutes: Int {
        BackendConfiguration.demoNowMinutes ?? (Calendar.current.component(.hour, from: currentTime) * 60 + Calendar.current.component(.minute, from: currentTime))
    }
    
    // Dynamic range: from current time to 7pm
    private var timeRange: ClosedRange<Int> {
        let startHour = max(8, nowMinutes / 60)
        let roundedStart = (startHour * 60)
        let endTime = 19 * 60 // 7pm
        return roundedStart...endTime
    }
    
    private var timeRangeLabel: String {
        let startHour = timeRange.lowerBound / 60
        return "\(formatHour(startHour)) to 7pm"
    }
    
    // Get friends who have meaningful overlaps
    private var friendsWithOverlaps: [(friendId: String, friendName: String, overlaps: [TodayPlanItem])] {
        var friendData: [String: (name: String, items: [TodayPlanItem])] = [:]
        
        for item in todayPlan where item.kind == .freeBlock {
            for overlap in item.friendOverlaps where starredIds.contains(overlap.friendId) {
                if overlap.longestIntervalMinutes >= 25 {
                    if friendData[overlap.friendId] == nil {
                        friendData[overlap.friendId] = (name: overlap.friendName, items: [])
                    }
                    friendData[overlap.friendId]?.items.append(item)
                }
            }
        }
        
        return friendData.map { (friendId: $0.key, friendName: $0.value.name, overlaps: $0.value.items) }
            .sorted { $0.friendName < $1.friendName }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Free time overlaps",
                subtitle: timeRangeLabel
            )
            
            if friendsWithOverlaps.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Time header
                    timeHeader
                    
                    // Friend overlap rows (no separate "your classes" row)
                    ForEach(Array(friendsWithOverlaps.enumerated()), id: \.element.friendId) { index, friend in
                        friendRow(friend: friend, colorIndex: index)
                        if index < friendsWithOverlaps.count - 1 {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(16)
                .background(BetweenTheme.surface(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 6, y: 2)
            }
        }
        .onAppear {
            startAutoRefresh()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No overlapping free time right now")
                .font(BetweenFont.secondary())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(BetweenTheme.surfaceMuted(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var timeHeader: some View {
        let totalMinutes = timeRange.upperBound - timeRange.lowerBound
        
        return HStack(spacing: 0) {
            // Left label space
            Color.clear
                .frame(width: 80)
            
            // Time markers
            GeometryReader { geometry in
                let width = geometry.size.width
                ForEach(0...11, id: \.self) { index in
                    let hour = (timeRange.lowerBound / 60) + index
                    if hour <= 19 {
                        let position = CGFloat(index) / 11 * width
                        Text(formatHourShort(hour))
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
                            .position(x: position, y: 10)
                    }
                }
            }
            .frame(height: 20)
        }
    }
    
    private var yourClassesRow: some View {
        let totalMinutes = timeRange.upperBound - timeRange.lowerBound
        
        return HStack(spacing: 0) {
            // Label
            Text("Your classes")
                .font(BetweenFont.captionMedium())
                .frame(width: 80, alignment: .leading)
            
            // Timeline
            GeometryReader { geometry in
                let width = geometry.size.width
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(BetweenTheme.surfaceMuted(colorScheme).opacity(0.3))
                        .frame(height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    // Current time indicator
                    if nowMinutes >= timeRange.lowerBound && nowMinutes <= timeRange.upperBound {
                        let offset = CGFloat(nowMinutes - timeRange.lowerBound) / CGFloat(totalMinutes) * width
                        Rectangle()
                            .fill(BetweenTheme.accent)
                            .frame(width: 2, height: 32)
                            .offset(x: offset)
                    }
                    
                    // Class blocks
                    ForEach(todayPlan.filter { $0.kind == .classBlock && blockInRange($0) }) { item in
                        classBlock(item, totalMinutes: totalMinutes, width: width)
                    }
                }
            }
            .frame(height: 32)
        }
    }
    
    private func friendRow(friend: (friendId: String, friendName: String, overlaps: [TodayPlanItem]), colorIndex: Int) -> some View {
        let totalMinutes = timeRange.upperBound - timeRange.lowerBound
        let color = friendColor(index: colorIndex)
        
        return HStack(spacing: 0) {
            // Label
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(FriendColorPalette.firstName(friend.friendName))
                    .font(BetweenFont.captionMedium())
                    .lineLimit(1)
            }
            .frame(width: 80, alignment: .leading)
            
            // Timeline
            GeometryReader { geometry in
                let width = geometry.size.width
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(BetweenTheme.surfaceMuted(colorScheme).opacity(0.3))
                        .frame(height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    // YOUR class blocks (blocking time for friend row)
                    ForEach(todayPlan.filter { $0.kind == .classBlock && blockInRange($0) }) { item in
                        yourClassBlock(item, totalMinutes: totalMinutes, width: width)
                    }
                    
                    // Current time indicator
                    if nowMinutes >= timeRange.lowerBound && nowMinutes <= timeRange.upperBound {
                        let offset = CGFloat(nowMinutes - timeRange.lowerBound) / CGFloat(totalMinutes) * width
                        Rectangle()
                            .fill(BetweenTheme.accent)
                            .frame(width: 2, height: 28)
                            .offset(x: offset)
                    }
                    
                    // Friend overlap blocks (colored sections where BOTH free)
                    ForEach(friend.overlaps.filter { blockInRange($0) }) { item in
                        overlapBlock(item, friendId: friend.friendId, totalMinutes: totalMinutes, width: width, color: color)
                    }
                }
            }
            .frame(height: 28)
        }
    }
    
    private func yourClassBlock(_ item: TodayPlanItem, totalMinutes: Int, width: CGFloat) -> some View {
        let clampedStart = max(item.startMinutes, timeRange.lowerBound)
        let clampedEnd = min(item.endMinutes, timeRange.upperBound)
        let offsetMinutes = clampedStart - timeRange.lowerBound
        let durationMinutes = clampedEnd - clampedStart
        
        let xOffset = CGFloat(offsetMinutes) / CGFloat(totalMinutes) * width
        let blockWidth = CGFloat(durationMinutes) / CGFloat(totalMinutes) * width
        
        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Color.gray.opacity(0.4))
            .frame(width: max(blockWidth, 4), height: 24)
            .offset(x: xOffset)
            .overlay {
                if let section = item.section, blockWidth > 60 {
                    Text(section.courseCode)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(width: blockWidth - 8)
                        .offset(x: xOffset)
                }
            }
    }
    
    private func classBlock(_ item: TodayPlanItem, totalMinutes: Int, width: CGFloat) -> some View {
        let clampedStart = max(item.startMinutes, timeRange.lowerBound)
        let clampedEnd = min(item.endMinutes, timeRange.upperBound)
        let offsetMinutes = clampedStart - timeRange.lowerBound
        let durationMinutes = clampedEnd - clampedStart
        
        let xOffset = CGFloat(offsetMinutes) / CGFloat(totalMinutes) * width
        let blockWidth = CGFloat(durationMinutes) / CGFloat(totalMinutes) * width
        
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(BetweenTheme.busy)
            .frame(width: max(blockWidth, 4), height: 28)
            .offset(x: xOffset)
            .overlay {
                if let section = item.section, blockWidth > 60 {
                    Text(section.courseCode)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(width: blockWidth - 8)
                        .offset(x: xOffset)
                }
            }
    }
    
    private func overlapBlock(_ item: TodayPlanItem, friendId: String, totalMinutes: Int, width: CGFloat, color: Color) -> some View {
        let friendOverlap = item.friendOverlaps.first { $0.friendId == friendId }
        let bars = friendOverlap.map { overlapBars(for: $0, totalMinutes: totalMinutes, width: width) } ?? []

        return ForEach(bars) { bar in
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color.opacity(0.8))
                .frame(width: max(bar.blockWidth, 4), height: 24)
                .offset(x: bar.xOffset)
        }
    }

    private struct OverlapBarSegment: Identifiable {
        let id: Int
        let xOffset: CGFloat
        let blockWidth: CGFloat
    }

    private func overlapBars(for overlap: FriendOverlap, totalMinutes: Int, width: CGFloat) -> [OverlapBarSegment] {
        overlap.intervals
            .filter { $0.end - $0.start >= 25 }
            .map { interval in
                let clampedStart = max(interval.start, timeRange.lowerBound)
                let clampedEnd = min(interval.end, timeRange.upperBound)
                let offsetMinutes = clampedStart - timeRange.lowerBound
                let durationMinutes = clampedEnd - clampedStart
                let xOffset = CGFloat(offsetMinutes) / CGFloat(totalMinutes) * width
                let blockWidth = CGFloat(durationMinutes) / CGFloat(totalMinutes) * width
                return OverlapBarSegment(id: interval.start, xOffset: xOffset, blockWidth: blockWidth)
            }
    }
    
    private func blockInRange(_ item: TodayPlanItem) -> Bool {
        item.endMinutes > timeRange.lowerBound && item.startMinutes < timeRange.upperBound
    }
    
    private func friendColor(index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.4, green: 0.8, blue: 0.4),  // Green (like Jack)
            Color(red: 0.9, green: 0.6, blue: 0.4),  // Orange (like Brianna)
            Color(red: 0.4, green: 0.6, blue: 0.9),  // Blue (like Philip)
            Color(red: 0.8, green: 0.4, blue: 0.8),  // Purple
            Color(red: 0.9, green: 0.7, blue: 0.3),  // Yellow
        ]
        return colors[index % colors.count]
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 12 { return "12pm" }
        if hour > 12 { return "\(hour - 12)pm" }
        return "\(hour)am"
    }
    
    private func formatHourShort(_ hour: Int) -> String {
        if hour == 12 { return "12p" }
        if hour > 12 { return "\(hour - 12)p" }
        return "\(hour)a"
    }
    
    private func startAutoRefresh() {
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            Task { @MainActor in
                currentTime = Date()
            }
        }
    }
}

#Preview {
    HorizontalOverlapTimeline(
        todayPlan: [],
        starredIds: []
    )
    .padding()
}
