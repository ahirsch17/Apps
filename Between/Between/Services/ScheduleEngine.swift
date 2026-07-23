import Foundation

enum ScheduleEngine {
    static let startMinutes = 6 * 60
    static let endMinutes = 23 * 60
    static let minFreeBlockMinutes = 30
    static let minOverlapMinutes = 25

    private enum TimelineBlock {
        case free(start: Int, end: Int)
        case busy(start: Int, end: Int, section: CourseSection)
    }

    private static let dayMap: [String: Int] = [
        "Sun": 0, "Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6
    ]

    static func formatRange(start: Int, end: Int) -> String {
        if end - start >= 16 * 60 {
            return "Most of the day"
        }
        return "\(formatTime12Hour(start)) – \(formatTime12Hour(end))"
    }

    static func buildTodayPlan(
        mySections: [CourseSection],
        friendSectionsById: [String: [CourseSection]],
        friendNamesById: [String: String],
        now: Date = Date()
    ) -> [TodayPlanItem] {
        let dayIdx = todayIndex(from: now)
        let nowMinutes = Calendar.current.component(.hour, from: now) * 60
            + Calendar.current.component(.minute, from: now)

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
                    start: start,
                    end: end,
                    dayIdx: dayIdx,
                    friendSectionsById: friendSectionsById,
                    friendNamesById: friendNamesById
                )
                appendIfFuture(
                    TodayPlanItem(
                        id: "free-\(start)-\(end)",
                        kind: .freeBlock,
                        startMinutes: start,
                        endMinutes: end,
                        section: nil,
                        friendOverlaps: overlaps
                    ),
                    nowMinutes: nowMinutes,
                    into: &timeline
                )
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

        return timeline
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

    private static func formatTime12Hour(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        let h12 = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        let ampm = hours < 12 ? "AM" : "PM"
        if mins == 0 {
            return "\(h12):00 \(ampm)"
        }
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
            if end > start {
                result.append((start: start, end: end))
            }
            if left.end < right.end {
                i += 1
            } else {
                j += 1
            }
        }
        return result
    }

    private static func nextTimelineBlock(
        free: (start: Int, end: Int)?,
        busy: (start: Int, end: Int, section: CourseSection)?
    ) -> TimelineBlock? {
        switch (free, busy) {
        case let (freeBlock?, nil):
            return .free(start: freeBlock.start, end: freeBlock.end)
        case let (nil, classBlock?):
            return .busy(start: classBlock.start, end: classBlock.end, section: classBlock.section)
        case let (freeBlock?, classBlock?):
            if freeBlock.start <= classBlock.start {
                return .free(start: freeBlock.start, end: freeBlock.end)
            }
            return .busy(start: classBlock.start, end: classBlock.end, section: classBlock.section)
        case (nil, nil):
            return nil
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
                    friendOverlaps: item.friendOverlaps
                )
            )
        } else {
            timeline.append(item)
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
            guard !intervals.isEmpty else { continue }
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
