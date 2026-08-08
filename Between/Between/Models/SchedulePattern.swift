import Foundation

/// Detects and represents recurring schedule patterns
enum SchedulePattern: Equatable, Hashable {
    case mwf  // Monday/Wednesday/Friday
    case tr   // Tuesday/Thursday
    case mw   // Monday/Wednesday
    case daily // Every weekday
    case weekly(Int) // Specific weekday (1=Monday, 5=Friday)
    
    var displayName: String {
        switch self {
        case .mwf: return "M/W/F"
        case .tr: return "T/R"
        case .mw: return "M/W"
        case .daily: return "Daily"
        case .weekly(let day):
            let names = ["", "Mon", "Tue", "Wed", "Thu", "Fri"]
            return day >= 1 && day <= 5 ? names[day] : ""
        }
    }
    
    var fullName: String {
        switch self {
        case .mwf: return "Every Monday, Wednesday, Friday"
        case .tr: return "Every Tuesday, Thursday"
        case .mw: return "Every Monday, Wednesday"
        case .daily: return "Every weekday"
        case .weekly(let day):
            let names = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
            return "Every \(names[day])"
        }
    }
    
    var emoji: String {
        switch self {
        case .mwf: return "📅"
        case .tr: return "📆"
        case .mw: return "📋"
        case .daily: return "🔄"
        case .weekly: return "📌"
        }
    }
    
    func occursOn(weekday: Int) -> Bool {
        switch self {
        case .mwf: return weekday == 2 || weekday == 4 || weekday == 6 // Mon=2, Wed=4, Fri=6
        case .tr: return weekday == 3 || weekday == 5 // Tue=3, Thu=5
        case .mw: return weekday == 2 || weekday == 4
        case .daily: return weekday >= 2 && weekday <= 6
        case .weekly(let day): return weekday == day + 1 // Adjusted for Calendar
        }
    }
}

struct RecurringWindow: Identifiable {
    let id: String
    let pattern: SchedulePattern
    let startMinutes: Int
    let endMinutes: Int
    let friendIds: [String]
    let friendNames: [String]
    let contextLabel: String
    
    var timeLabel: String {
        ScheduleEngine.formatRange(start: startMinutes, end: endMinutes)
    }
    
    var durationMinutes: Int {
        endMinutes - startMinutes
    }
    
    var friendNamesLine: String {
        let firstNames = friendNames.map { FriendColorPalette.firstName($0) }
        switch firstNames.count {
        case 0: return ""
        case 1: return firstNames[0]
        case 2: return "\(firstNames[0]) & \(firstNames[1])"
        case 3: return "\(firstNames[0]), \(firstNames[1]) & \(firstNames[2])"
        default:
            return "\(firstNames[0]), \(firstNames[1]) +\(firstNames.count - 2) more"
        }
    }
    
    var suggestedActivity: String {
        switch durationMinutes {
        case 0..<45: return "Quick coffee"
        case 45..<75: return "Grab lunch"
        case 75..<150: return "Study session"
        default: return "Hang out"
        }
    }
}

/// Detects recurring patterns in schedule overlaps
struct SchedulePatternDetector {
    static func detectRecurringWindows(
        from plan: [TodayPlanItem],
        starredIds: Set<String>
    ) -> [RecurringWindow] {
        var windows: [String: RecurringWindow] = [:]
        
        for item in plan where item.kind == .freeBlock {
            for overlap in item.qualifyingOverlaps() {
                guard starredIds.contains(overlap.friendId) else { continue }
                guard let interval = overlap.intervals.max(by: { $0.end - $0.start < $1.end - $1.start }) else { continue }
                
                let key = "\(interval.start)-\(interval.end)"
                if var existing = windows[key] {
                    if !existing.friendIds.contains(overlap.friendId) {
                        existing = RecurringWindow(
                            id: existing.id,
                            pattern: existing.pattern,
                            startMinutes: existing.startMinutes,
                            endMinutes: existing.endMinutes,
                            friendIds: existing.friendIds + [overlap.friendId],
                            friendNames: existing.friendNames + [overlap.friendName],
                            contextLabel: existing.contextLabel
                        )
                        windows[key] = existing
                    }
                } else {
                    let context = contextLabel(start: interval.start, end: interval.end)
                    windows[key] = RecurringWindow(
                        id: key,
                        pattern: detectPattern(from: item),
                        startMinutes: interval.start,
                        endMinutes: interval.end,
                        friendIds: [overlap.friendId],
                        friendNames: [overlap.friendName],
                        contextLabel: context
                    )
                }
            }
        }
        
        return windows.values.sorted { $0.startMinutes < $1.startMinutes }
    }
    
    private static func detectPattern(from item: TodayPlanItem) -> SchedulePattern {
        let demoDay = BackendConfiguration.weekdayName()
        
        if demoDay.contains("Monday") || demoDay.contains("Wednesday") || demoDay.contains("Friday") {
            return .mwf
        } else if demoDay.contains("Tuesday") || demoDay.contains("Thursday") {
            return .tr
        }
        
        return .daily
    }
    
    private static func contextLabel(start: Int, end: Int) -> String {
        let mid = (start + end) / 2
        let duration = end - start
        
        if mid >= 11 * 60 + 30 && mid <= 13 * 60 + 30 {
            return duration >= 60 ? "Lunch" : "Quick bite"
        }
        if mid >= 15 * 60 && mid >= 17 * 60 {
            return "After classes"
        }
        if duration >= 90 {
            return "Study block"
        }
        if duration >= 45 {
            return "Break"
        }
        return "Quick meetup"
    }
}
