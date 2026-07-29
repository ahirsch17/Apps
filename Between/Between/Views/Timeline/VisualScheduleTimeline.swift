import SwiftUI

/// A visual, side-by-side timeline showing multiple people's schedules
/// Auto-scrolls to show "now until end of day" with smooth rescaling
struct VisualScheduleTimeline: View {
    let friends: [FriendCard]
    let todayPlan: [TodayPlanItem]
    let starredIds: Set<String>
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentTime = Date()
    
    // Current time in minutes (8am = 480, 7pm = 1140)
    // Uses currentTime state to trigger refresh every 30min
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
    
    private var displayedFriends: [FriendCard] {
        // Only show starred friends who have meaningful overlap (>=25min) with your free time
        let minOverlapMinutes = 25
        
        return friends
            .filter { friend in
                guard starredIds.contains(friend.id) else { return false }
                
                // Check if this friend has any meaningful overlap with your free blocks
                let hasOverlap = todayPlan.contains { planItem in
                    guard planItem.kind == .freeBlock else { return false }
                    return planItem.friendOverlaps.contains { overlap in
                        overlap.friendId == friend.id && overlap.longestIntervalMinutes >= minOverlapMinutes
                    }
                }
                return hasOverlap
            }
            .prefix(4)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Today's schedules",
                subtitle: timeRangeLabel
            )
            
            if displayedFriends.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 20) {
                        // Your schedule
                        scheduleColumn(
                            name: "You",
                            plan: todayPlan,
                            friendId: nil,
                            isYou: true
                        )
                        
                        // Friend schedules
                        ForEach(displayedFriends) { friend in
                            scheduleColumn(
                                name: FriendColorPalette.firstName(friend.name),
                                plan: friendPlan(for: friend.id),
                                friendId: friend.id,
                                isYou: false
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(BetweenTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .onAppear {
            startAutoRefresh()
        }
    }
    
    private func startAutoRefresh() {
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            Task { @MainActor in
                currentTime = Date()
            }
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
            Text("Star friends with 25+ min shared windows to see them here")
                .font(BetweenFont.caption())
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(BetweenTheme.surfaceMuted(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var timeRangeLabel: String {
        let startHour = timeRange.lowerBound / 60
        let startLabel = formatHour(startHour)
        return "\(startLabel) to 7pm"
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 12 { return "12pm" }
        if hour > 12 { return "\(hour - 12)pm" }
        return "\(hour)am"
    }
    
    private func scheduleColumn(name: String, plan: [TodayPlanItem], friendId: String?, isYou: Bool) -> some View {
        VStack(spacing: 8) {
            // Header
            VStack(spacing: 4) {
                if let id = friendId {
                    FriendAvatarView(name: name, friendId: id, size: 32)
                } else {
                    Circle()
                        .fill(BetweenTheme.accent.gradient)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("Me")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                }
                Text(name)
                    .font(BetweenFont.captionMedium())
                    .lineLimit(1)
            }
            .frame(height: 60)
            
            // Schedule bars
            timelineBar(plan: plan, isYou: isYou)
        }
        .frame(width: 100)
    }
    
    private func timelineBar(plan: [TodayPlanItem], isYou: Bool) -> some View {
        let totalMinutes = timeRange.upperBound - timeRange.lowerBound
        
        return ZStack(alignment: .top) {
            // Background track with subtle gradient
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BetweenTheme.surface(colorScheme),
                            BetweenTheme.surface(colorScheme).opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
                .offset(y: offset)
                .animation(.easeInOut(duration: 1), value: offset)
            }
            
            // Schedule blocks
            ForEach(plan.filter { blockInRange($0) }) { item in
                scheduleBlock(item, totalMinutes: totalMinutes, isYou: isYou)
            }
        }
        .frame(width: 80, height: 400)
    }
    
    private func blockInRange(_ item: TodayPlanItem) -> Bool {
        item.endMinutes > timeRange.lowerBound && item.startMinutes < timeRange.upperBound
    }
    
    private func scheduleBlock(_ item: TodayPlanItem, totalMinutes: Int, isYou: Bool) -> some View {
        let clampedStart = max(item.startMinutes, timeRange.lowerBound)
        let clampedEnd = min(item.endMinutes, timeRange.upperBound)
        let offsetMinutes = clampedStart - timeRange.lowerBound
        let durationMinutes = clampedEnd - clampedStart
        
        let yOffset = CGFloat(offsetMinutes) / CGFloat(totalMinutes) * 400
        let height = CGFloat(durationMinutes) / CGFloat(totalMinutes) * 400
        
        if item.kind == .classBlock {
            return AnyView(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [BetweenTheme.busy, BetweenTheme.busy.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: max(height, 4))
                    .offset(y: yOffset)
                    .shadow(color: BetweenTheme.busy.opacity(0.3), radius: 2, y: 1)
                    .overlay {
                        if let section = item.section, height > 30 {
                            VStack(spacing: 2) {
                                Text(section.courseCode)
                                    .font(.system(size: 9, weight: .bold))
                                    .lineLimit(1)
                                Text(ScheduleEngine.formatTime12Hour(item.startMinutes))
                                    .font(.system(size: 8))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: height)
            )
        } else {
            let hasFriendOverlap = !item.friendOverlaps.isEmpty
            return AnyView(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        hasFriendOverlap
                            ? LinearGradient(
                                colors: [BetweenTheme.free.opacity(0.6), BetweenTheme.free.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [BetweenTheme.free.opacity(0.2), BetweenTheme.free.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(height: max(height, 4))
                    .offset(y: yOffset)
                    .overlay {
                        if hasFriendOverlap, height > 20 {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(BetweenTheme.free)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: height)
            )
        }
    }
    
    private func friendPlan(for friendId: String) -> [TodayPlanItem] {
        // For demo purposes, return the same plan structure
        // In production, this would fetch the friend's actual schedule from overlap data
        todayPlan.map { item in
            // Offset friend schedules slightly for variety
            let offset = Int(friendId.hashValue % 120) - 60
            return TodayPlanItem(
                id: "\(friendId)-\(item.id)",
                kind: item.kind,
                startMinutes: item.startMinutes + offset,
                endMinutes: item.endMinutes + offset,
                section: item.section,
                friendOverlaps: []
            )
        }
    }
}

#Preview {
    VisualScheduleTimeline(
        friends: [],
        todayPlan: [],
        starredIds: []
    )
    .padding()
}
