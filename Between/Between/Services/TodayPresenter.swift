import Foundation

/// Turns schedule math into copy a student would actually read.
enum TodayPresenter {
    struct Snapshot {
        let headline: Headline?
        let friendsFreeNow: [FriendCard]
        let nextClass: NextClass?
        let meetups: [MeetupWindow]
        let timeline: [TimelineEntry]
    }

    struct Headline {
        let title: String
        let subtitle: String?
        let friendId: String?
        let friendName: String?
    }

    struct NextClass {
        let courseCode: String
        let location: String
        let timeLabel: String
        let startsInLabel: String?
        let section: CourseSection
    }

    struct MeetupWindow: Identifiable {
        let id: String
        let startMinutes: Int
        let endMinutes: Int
        let timeLabel: String
        let friendNames: [String]
        let friendIds: [String]
        let contextLabel: String

        var namesLine: String {
            let firstNames = friendNames.map { FriendColorPalette.firstName($0) }
            switch firstNames.count {
            case 0: return ""
            case 1: return firstNames[0]
            case 2: return "\(firstNames[0]) & \(firstNames[1])"
            default:
                return "\(firstNames[0]), \(firstNames[1]) + \(firstNames.count - 2) more"
            }
        }

        var icon: String {
            switch contextLabel {
            case "Good for lunch": return "fork.knife"
            case "Quick break": return "cup.and.saucer.fill"
            case "After classes": return "sun.horizon.fill"
            default: return "person.2.fill"
            }
        }
    }

    enum TimelineEntry: Identifiable {
        case classBlock(TodayPlanItem)
        case freeWithFriends(start: Int, end: Int, friends: [(id: String, name: String)])
        case soloBreak(start: Int, end: Int)

        var id: String {
            switch self {
            case .classBlock(let item): return item.id
            case .freeWithFriends(let start, let end, _): return "free-\(start)-\(end)"
            case .soloBreak(let start, let end): return "break-\(start)-\(end)"
            }
        }

        var startMinutes: Int {
            switch self {
            case .classBlock(let item): return item.startMinutes
            case .freeWithFriends(let start, _, _): return start
            case .soloBreak(let start, _): return start
            }
        }
    }

    static func build(
        plan: [TodayPlanItem],
        friends: [FriendCard],
        starredIds: Set<String>,
        nowMinutes: Int = BackendConfiguration.demoNowMinutes
            ?? (Calendar.current.component(.hour, from: Date()) * 60
                + Calendar.current.component(.minute, from: Date()))
    ) -> Snapshot {
        let freeNow = friends
            .filter { $0.status == .freeNow }
            .sorted { lhs, rhs in
                rank(starredIds, lhs.id) < rank(starredIds, rhs.id)
            }

        let meetups = mergeMeetups(from: plan, nowMinutes: nowMinutes)
        let timeline = buildTimeline(from: plan)
        let nextClass = plan.first(where: { $0.kind == .classBlock }).flatMap { item -> NextClass? in
            guard let section = item.section else { return nil }
            return NextClass(
                courseCode: section.courseCode,
                location: section.location,
                timeLabel: ScheduleEngine.formatRange(start: item.startMinutes, end: item.endMinutes),
                startsInLabel: startsInLabel(from: nowMinutes, to: item.startMinutes),
                section: section
            )
        }

        let headline = buildHeadline(
            plan: plan,
            friends: friends,
            freeNow: freeNow,
            meetups: meetups,
            starredIds: starredIds,
            nowMinutes: nowMinutes
        )

        return Snapshot(
            headline: headline,
            friendsFreeNow: freeNow,
            nextClass: nextClass,
            meetups: meetups,
            timeline: timeline
        )
    }

    // MARK: - Headline

    private static func buildHeadline(
        plan: [TodayPlanItem],
        friends: [FriendCard],
        freeNow: [FriendCard],
        meetups: [MeetupWindow],
        starredIds: Set<String>,
        nowMinutes: Int
    ) -> Headline? {
        if let current = currentOverlap(in: plan, nowMinutes: nowMinutes) {
            let first = current.friendName.components(separatedBy: " ").first ?? current.friendName
            let until = ScheduleEngine.formatTime12Hour(current.endMinutes)
            let extras = current.otherCount
            let subtitle: String? = extras > 0
                ? "+\(extras) more friend\(extras == 1 ? "" : "s") free right now"
                : (freeNow.count > 1 ? "\(freeNow.count - 1) more friends free on campus" : nil)
            return Headline(
                title: "You've got time with \(first) 'til \(until)",
                subtitle: subtitle,
                friendId: current.friendId,
                friendName: current.friendName
            )
        }

        if let first = freeNow.first {
            let name = first.name.components(separatedBy: " ").first ?? first.name
            let place = first.location.isEmpty ? nil : first.location
            return Headline(
                title: "\(name)'s free — say hi?",
                subtitle: place.map { "At \(place)" },
                friendId: first.id,
                friendName: first.name
            )
        }

        if let lunch = meetups.first(where: { $0.startMinutes >= nowMinutes && !$0.friendNames.isEmpty }) {
            return Headline(
                title: "Lunch with \(lunch.namesLine)",
                subtitle: lunch.timeLabel,
                friendId: lunch.friendIds.first,
                friendName: lunch.friendNames.first
            )
        }

        if let next = plan.first(where: { $0.kind == .classBlock }), let section = next.section {
            let time = ScheduleEngine.formatTime12Hour(next.startMinutes)
            return Headline(
                title: "\(section.courseCode) is next",
                subtitle: "\(time) · \(section.location)",
                friendId: nil,
                friendName: nil
            )
        }

        return nil
    }

    private struct LiveOverlap {
        let friendId: String
        let friendName: String
        let endMinutes: Int
        let otherCount: Int
    }

    private static func currentOverlap(in plan: [TodayPlanItem], nowMinutes: Int) -> LiveOverlap? {
        var matches: [(FriendOverlap, Int, Int)] = []
        for item in plan where item.kind == .freeBlock {
            guard item.startMinutes <= nowMinutes, item.endMinutes > nowMinutes else { continue }
            for overlap in item.qualifyingOverlaps() {
                matches.append((overlap, item.startMinutes, item.endMinutes))
            }
        }
        guard let best = matches.max(by: { ($0.2 - nowMinutes) < ($1.2 - nowMinutes) }) else {
            return nil
        }
        let uniqueFriends = Set(matches.map(\.0.friendId))
        return LiveOverlap(
            friendId: best.0.friendId,
            friendName: best.0.friendName,
            endMinutes: best.2,
            otherCount: max(0, uniqueFriends.count - 1)
        )
    }

    // MARK: - Meetups

    private static func mergeMeetups(from plan: [TodayPlanItem], nowMinutes: Int) -> [MeetupWindow] {
        struct Window {
            var start: Int
            var end: Int
            var friends: [String: String] = [:]
        }

        var windows: [String: Window] = [:]
        for item in plan where item.kind == .freeBlock {
            for overlap in item.qualifyingOverlaps() {
                guard let interval = overlap.intervals
                    .filter({ $0.end - $0.start >= ScheduleEngine.minOverlapMinutes })
                    .max(by: { ($0.end - $0.start) < ($1.end - $1.start) })
                else { continue }
                guard interval.end > nowMinutes else { continue }

                let key = "\(interval.start)-\(interval.end)"
                var window = windows[key] ?? Window(start: interval.start, end: interval.end)
                window.friends[overlap.friendId] = overlap.friendName
                windows[key] = window
            }
        }

        return windows.values
            .sorted { $0.start < $1.start }
            .map { window in
                let sorted = window.friends.sorted { $0.value < $1.value }
                let context = contextLabel(start: window.start, end: window.end)
                return MeetupWindow(
                    id: "\(window.start)-\(window.end)",
                    startMinutes: window.start,
                    endMinutes: window.end,
                    timeLabel: ScheduleEngine.formatRange(start: window.start, end: window.end),
                    friendNames: sorted.map(\.value),
                    friendIds: sorted.map(\.key),
                    contextLabel: context
                )
            }
    }

    private static func contextLabel(start: Int, end: Int) -> String {
        let mid = (start + end) / 2
        if mid >= 11 * 60 + 15 && mid <= 14 * 60 { return "Good for lunch" }
        if end - start <= 50 { return "Quick break" }
        if mid >= 16 * 60 { return "After classes" }
        return "Between classes"
    }

    // MARK: - Timeline

    private static func buildTimeline(from plan: [TodayPlanItem]) -> [TimelineEntry] {
        var entries: [TimelineEntry] = []

        for item in plan.sorted(by: { $0.startMinutes < $1.startMinutes }) {
            switch item.kind {
            case .classBlock:
                entries.append(.classBlock(item))

            case .freeBlock:
                let overlaps = item.qualifyingOverlaps()
                if overlaps.isEmpty {
                    if item.durationMinutes >= ScheduleEngine.minFreeBlockMinutes,
                       item.durationMinutes <= ScheduleEngine.maxEmptyFreeBlockMinutes {
                        entries.append(.soloBreak(start: item.startMinutes, end: item.endMinutes))
                    }
                }
            }
        }
        return entries.sorted { $0.startMinutes < $1.startMinutes }
    }

    // MARK: - Helpers

    private static func rank(_ starred: Set<String>, _ id: String) -> Int {
        starred.contains(id) ? 0 : 1
    }

    private static func startsInLabel(from now: Int, to start: Int) -> String? {
        let delta = start - now
        guard delta > 0 else { return nil }
        if delta < 60 { return "Starts in ~\(delta) min" }
        let hours = delta / 60
        let mins = delta % 60
        if mins == 0 { return hours == 1 ? "Starts in ~1 hour" : "Starts in ~\(hours) hours" }
        return "Starts in ~\(hours)h \(mins)m"
    }
}
