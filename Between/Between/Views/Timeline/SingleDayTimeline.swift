import SwiftUI

/// Single timeline showing YOUR schedule with friend overlap indicators
/// Shows classes as solid blocks, free time highlighted when friends overlap
struct SingleDayTimeline: View {
    let todayPlan: [TodayPlanItem]
    let starredIds: Set<String>
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentTime = Date()
    
    private var nowMinutes: Int {
        BackendConfiguration.demoNowMinutes ?? (Calendar.current.component(.hour, from: currentTime) * 60 + Calendar.current.component(.minute, from: currentTime))
    }
    
    // Dynamic range: from current time (rounded down to nearest 30min) to 7pm
    private var timeRange: ClosedRange<Int> {
        let startHour = max(8, nowMinutes / 60)
        let roundedStart = (startHour * 60)
        let endTime = 19 * 60 // 7pm
        return roundedStart...endTime
    }
    
    private var timeRangeLabel: String {
        let startHour = timeRange.lowerBound / 60
        let startLabel = formatHour(startHour)
        return "\(startLabel) to 7pm"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Your day",
                subtitle: timeRangeLabel
            )
            
            HStack(alignment: .top, spacing: 16) {
                // Time labels on the left
                timeLabels
                
                // Your schedule bar
                timelineBar
            }
            .padding(20)
            .background(BetweenTheme.surfaceMuted(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .onAppear {
            startAutoRefresh()
        }
    }
    
    private var timeLabels: some View {
        let totalMinutes = timeRange.upperBound - timeRange.lowerBound
        let hourCount = (timeRange.upperBound - timeRange.lowerBound) / 60
        
        return VStack(spacing: 0) {
            ForEach(0...hourCount, id: \.self) { index in
                let hour = (timeRange.lowerBound / 60) + index
                if hour <= 19 {
                    Text(formatHour(hour))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(height: CGFloat(60.0 / CGFloat(hourCount) * 400.0), alignment: .top)
                }
            }
        }
        .frame(width: 50, alignment: .trailing)
    }
    
    private var timelineBar: some View {
        let totalMinutes = timeRange.upperBound - timeRange.lowerBound
        
        return ZStack(alignment: .top) {
            // Background track
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BetweenTheme.surface(colorScheme))
                .frame(height: 400)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 4, y: 2)
            
            // Current time indicator with glow
            if nowMinutes >= timeRange.lowerBound && nowMinutes <= timeRange.upperBound {
                let offset = CGFloat(nowMinutes - timeRange.lowerBound) / CGFloat(totalMinutes) * 400
                ZStack {
                    Rectangle()
                        .fill(BetweenTheme.accent.opacity(0.2))
                        .frame(height: 8)
                        .blur(radius: 4)
                    Rectangle()
                        .fill(BetweenTheme.accent)
                        .frame(height: 2)
                }
                .frame(maxWidth: .infinity)
                .offset(y: offset)
                .animation(.easeInOut(duration: 1), value: offset)
            }
            
            // Schedule blocks
            ForEach(todayPlan.filter { blockInRange($0) }) { item in
                scheduleBlock(item, totalMinutes: totalMinutes)
            }
        }
        .frame(height: 400)
    }
    
    private func blockInRange(_ item: TodayPlanItem) -> Bool {
        item.endMinutes > timeRange.lowerBound && item.startMinutes < timeRange.upperBound
    }
    
    private func scheduleBlock(_ item: TodayPlanItem, totalMinutes: Int) -> some View {
        let clampedStart = max(item.startMinutes, timeRange.lowerBound)
        let clampedEnd = min(item.endMinutes, timeRange.upperBound)
        let offsetMinutes = clampedStart - timeRange.lowerBound
        let durationMinutes = clampedEnd - clampedStart
        
        let yOffset = CGFloat(offsetMinutes) / CGFloat(totalMinutes) * 400
        let height = CGFloat(durationMinutes) / CGFloat(totalMinutes) * 400
        
        if item.kind == .classBlock {
            // Class block - solid coral
            return AnyView(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [BetweenTheme.busy, BetweenTheme.busy.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: max(height, 8))
                    .offset(y: yOffset)
                    .shadow(color: BetweenTheme.busy.opacity(0.3), radius: 3, y: 2)
                    .overlay {
                        if let section = item.section, height > 40 {
                            VStack(spacing: 4) {
                                Text(section.courseCode)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                Text(ScheduleEngine.formatTime12Hour(item.startMinutes))
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                Text(section.location)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                                    .opacity(0.9)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: height)
            )
        } else {
            // Free time block
            let friendOverlaps = item.friendOverlaps.filter { starredIds.contains($0.friendId) }
            let hasOverlap = !friendOverlaps.isEmpty
            let overlapCount = friendOverlaps.count
            
            return AnyView(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        hasOverlap
                            ? LinearGradient(
                                colors: [BetweenTheme.free, BetweenTheme.free.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(height: max(height, 8))
                    .offset(y: yOffset)
                    .overlay {
                        if hasOverlap, height > 30 {
                            VStack(spacing: 2) {
                                Image(systemName: overlapCount > 1 ? "person.2.fill" : "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(BetweenTheme.free.opacity(0.8))
                                if height > 50 {
                                    Text("\(overlapCount) free")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(BetweenTheme.free.opacity(0.9))
                                }
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: height)
            )
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 12 { return "12pm" }
        if hour > 12 { return "\(hour - 12)pm" }
        return "\(hour)am"
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
    SingleDayTimeline(
        todayPlan: [],
        starredIds: []
    )
    .padding()
}
