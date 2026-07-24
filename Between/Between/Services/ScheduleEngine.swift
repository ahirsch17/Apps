import Foundation

enum ScheduleEngine {
    /// Campus day window — avoids 6am–11pm empty blocks in the UI.
    static let startMinutes = 8 * 60
    static let endMinutes = 18 * 60
    static let minFreeBlockMinutes = 30
    static let minOverlapMinutes = 25
    /// Hide empty free blocks longer than this; overlaps always show.
    static let maxEmptyFreeBlockMinutes = 90

    private enum TimelineBlock {
        case free(start: Int, end: Int)
        case busy(start: Int, end: Int, section: CourseSection)
    }

    private static let dayMap: [String: Int] = [
        "Sun": 0, "Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6
    ]

    static func formatRange(start: Int, end: Int) -> String {
        return "\(formatTime12Hour(start)) – \(formatTime12Hour(end))"
    }

    static func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        if m == 0 { return h == 1 ? "1 hr" : "\(h) hr" }
        return "\(h) hr \(m) min"
    }

    static func buildTodayPlan(
        mySections: [CourseSection],
        friendSectionsById: [String: [CourseSection]],
        friendNamesById: [String: String],
        now: Date = Date()
    ) -> [TodayPlanItem] {
        let dayIdx = BackendConfiguration.demoWeekdayIndex ?? todayIndex(from: now)
        let nowMinutes = BackendConfiguration.demoNowMinutes
            ?? (Calendar.current.component(.hour, from: now) * 60
                + Calendar.current.component(.minute, from: now))

        let busy = busyIntervals(on: dayIdx, sections: mySections)
        let free = freeIntervals(on: dayIdx, sections: mySections)

        var timeline: [TodayPlanItem] = []

        var freeIndex = 0
        var busyIndex = 0

        while freeIndex < free.count || busyIndex < busy.count {
            let nextFree = freeIndex < free.count ? free[freeIndex] : nil
            let nextBusy = busyIndex < busy.count ? busy[busyIndex] : nil

            guard let block = nextTimelineBlock(free: nextFree, busy: nextBusy) else { break }

            switch block {
            case let .free(start, end):
                let overlaps = friendOverlaps(
                    start: start, end: end, dayIdx: dayIdx,
                    friendSectionsById: friendSectionsById,
                    friendNamesById: friendNamesById
                )
                if overlaps.isEmpty {
                    let duration = end - start
                    if duration >= minFreeBlockMinutes && duration <= maxEmptyFreeBlockMinutes {
                        appendIfFuture(
                            TodayPlanItem(
                                id: "free-\(start)-\(end)",
                                kind: .freeBlock,
                                startMinutes: start,
                                endMinutes: end,
                                section: nil,
                                friendOverlaps: []
                            ),
                            nowMinutes: nowMinutes,
                            into: &timeline
                        )
                    }
                } else {
                    for overlap in overlaps {
                        guard let best = overlap.intervals
                            .filter({ $0.end - $0.start >= minOverlapMinutes })
                            .max(by: { ($0.end - $0.start) < ($1.end - $1.start) })
                        else { continue }

                        let clipped = FriendOverlap(
                            id: "\(overlap.friendId)-\(best.start)",
                            friendId: overlap.friendId,
                            friendName: overlap.friendName,
                            intervals: [best],
                            totalMinutes: best.end - best.start
                        )
                        appendIfFuture(
                            TodayPlanItem(
                                id: "overlap-\(overlap.friendId)-\(best.start)",
                                kind: .freeBlock,
                                startMinutes: best.start,
                                endMinutes: best.end,
                                section: nil,
                                friendOverlaps: [clipped]
                            ),
                            nowMinutes: nowMinutes,
                            into: &timeline
                        )
                    }
                }
                freeIndex += 1

            case let .busy(start, end, section):
                appendIfFuture(
                    TodayPlanItem(
                        id: "class-\(section.sectionId)",
                        kind: .classBlock,
                        startMinutes: start,
                        endMinutes: end,
                        section: section,
                        friendOverlaps: []
                    ),
                    nowMinutes: nowMinutes,
                    into: &timeline
                )
                busyIndex += 1
            }
        }

        return timeline.sorted { $0.startMinutes < $1.startMinutes }
    }

    // MARK: - Private helpers

    private static func todayIndex(from date: Date) -> Int {
        Calendar.current.component(.weekday, from: date) - 1
    }

    private static func minutes(from time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return hour * 60 + minute
    }

    static func formatTime12Hour(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        let h12 = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        let ampm = hours < 12 ? "AM" : "PM"
        if mins == 0 { return "\(h12) \(ampm)" }
        return String(format: "%d:%02d %@", h12, mins, ampm)
    }

    private static func sectionsForDay(_ dayIdx: Int, in allSections: [CourseSection]) -> [CourseSection] {
        allSections.filter { section in
            section.meetingDays.contains { dayMap[$0] == dayIdx }
        }
    }

    private static func busyIntervals(
        on dayIdx: Int,
        sections: [CourseSection]
    ) -> [(start: Int, end: Int, section: CourseSection)] {
        sectionsForDay(dayIdx, in: sections).compactMap { section in
            guard let start = minutes(from: section.startTime),
                  let end = minutes(from: section.endTime) else { return nil }
            let clampedStart = max(start, startMinutes)
            let clampedEnd = min(end, endMinutes)
            guard clampedEnd > clampedStart else { return nil }
            return (start: clampedStart, end: clampedEnd, section: section)
        }
        .sorted { $0.start < $1.start }
    }

    private static func freeIntervals(
        on dayIdx: Int,
        sections: [CourseSection]
    ) -> [(start: Int, end: Int)] {
        let busy = busyIntervals(on: dayIdx, sections: sections).map { (start: $0.start, end: $0.end) }
        var free: [(start: Int, end: Int)] = []
        var previousEnd = startMinutes
        for interval in busy {
            if interval.start > previousEnd {
                free.append((start: previousEnd, end: interval.start))
            }
            previousEnd = max(previousEnd, interval.end)
        }
        if previousEnd < endMinutes {
            free.append((start: previousEnd, end: endMinutes))
        }
        return free
    }

    private static func intersectIntervals(
        _ a: [(start: Int, end: Int)],
        _ b: [(start: Int, end: Int)]
    ) -> [(start: Int, end: Int)] {
        var result: [(start: Int, end: Int)] = []
        let sortedA = a.sorted { $0.start < $1.start }
        let sortedB = b.sorted { $0.start < $1.start }
        var i = 0
        var j = 0
        while i < sortedA.count && j < sortedB.count {
            let left = sortedA[i]
            let right = sortedB[j]
            let start = max(left.start, right.start)
            let end = min(left.end, right.end)
            if end > start { result.append((start: start, end: end)) }
            if left.end < right.end { i += 1 } else { j += 1 }
        }
        return result
    }

    private static func nextTimelineBlock(
        free: (start: Int, end: Int)?,
        busy: (start: Int, end: Int, section: CourseSection)?
    ) -> TimelineBlock? {
        switch (free, busy) {
        case let (freeBlock?, nil): return .free(start: freeBlock.start, end: freeBlock.end)
        case let (nil, classBlock?): return .busy(start: classBlock.start, end: classBlock.end, section: classBlock.section)
        case let (freeBlock?, classBlock?):
            return freeBlock.start <= classBlock.start
                ? .free(start: freeBlock.start, end: freeBlock.end)
                : .busy(start: classBlock.start, end: classBlock.end, section: classBlock.section)
        case (nil, nil): return nil
        }
    }

    private static func appendIfFuture(
        _ item: TodayPlanItem,
        nowMinutes: Int,
        into timeline: inout [TodayPlanItem]
    ) {
        guard item.endMinutes > nowMinutes else { return }
        if item.startMinutes < nowMinutes {
            timeline.append(
                TodayPlanItem(
                    id: item.id,
                    kind: item.kind,
                    startMinutes: nowMinutes,
                    endMinutes: item.endMinutes,
                    section: item.section,
                    friendOverlaps: clipOverlaps(item.friendOverlaps, nowMinutes: nowMinutes)
                )
            )
        } else {
            timeline.append(item)
        }
    }

    private static func clipOverlaps(_ overlaps: [FriendOverlap], nowMinutes: Int) -> [FriendOverlap] {
        overlaps.compactMap { overlap in
            let intervals = overlap.intervals.compactMap { interval -> (start: Int, end: Int)? in
                let start = max(interval.start, nowMinutes)
                guard interval.end > start, interval.end - start >= minOverlapMinutes else { return nil }
                return (start: start, end: interval.end)
            }
            guard !intervals.isEmpty else { return nil }
            let total = intervals.reduce(0) { $0 + ($1.end - $1.start) }
            return FriendOverlap(
                id: overlap.id,
                friendId: overlap.friendId,
                friendName: overlap.friendName,
                intervals: intervals,
                totalMinutes: total
            )
        }
    }

    private static func friendOverlaps(
        start: Int,
        end: Int,
        dayIdx: Int,
        friendSectionsById: [String: [CourseSection]],
        friendNamesById: [String: String]
    ) -> [FriendOverlap] {
        let userFree = [(start: start, end: end)]
        var overlaps: [FriendOverlap] = []

        for (friendId, sections) in friendSectionsById {
            let friendFree = freeIntervals(on: dayIdx, sections: sections)
            let intervals = intersectIntervals(userFree, friendFree)
            let qualifying = intervals.filter { $0.end - $0.start >= minOverlapMinutes }
            guard !qualifying.isEmpty else { continue }
            let totalMinutes = qualifying.reduce(0) { $0 + ($1.end - $1.start) }
            overlaps.append(
                FriendOverlap(
                    id: "\(friendId)-\(start)",
                    friendId: friendId,
                    friendName: friendNamesById[friendId] ?? "Friend",
                    intervals: qualifying,
                    totalMinutes: totalMinutes
                )
            )
        }

        return overlaps.sorted {
            if $0.totalMinutes != $1.totalMinutes { return $0.totalMinutes > $1.totalMinutes }
            return $0.friendName < $1.friendName
        }
    }
}
