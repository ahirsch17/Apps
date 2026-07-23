import Foundation

enum ScheduleEngine {
    static let startMinutes = 6 * 60
    static let endMinutes = 23 * 60
    static let minFreeBlockMinutes = 30
    static let minOverlapMinutes = 25

    private typealias TimeRange = (start: Int, end: Int)
    private typealias ClassBlock = (start: Int, end: Int, section: CourseSection)

    private enum TimelineBlock {
        case free(TimeRange)
        case busy(ClassBlock)
    }

    private static let dayMap: [String: Int] = [
        "Sun": 0, "Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6
    ]

    static func todayIndex(from date: Date = Date()) -> Int {
        Calendar.current.component(.weekday, from: date) - 1
    }

    static func minutes(from time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return hour * 60 + minute
    }

    static func formatTime12Hour(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        let h12 = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        let ampm = hours < 12 ? "AM" : "PM"
        if mins == 0 {
            return "\(h12):00 \(ampm)"
        }
        return String(format: "%d:%02d %@", h12, mins, ampm)
    }

    static func formatRange(start: Int, end: Int) -> String {
        if end - start >= 16 * 60 {
            return "Most of the day"
        }
        return "\(formatTime12Hour(start)) – \(formatTime12Hour(end))"
    }

    static func sectionsForDay(_ dayIdx: Int, in allSections: [CourseSection]) -> [CourseSection] {
        allSections.filter { section in
            section.meetingDays.contains { dayMap[$0] == dayIdx }
        }
    }

    static func busyIntervals(on dayIdx: Int, sections: [CourseSection]) -> [ClassBlock] {
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

    static func freeIntervals(on dayIdx: Int, sections: [CourseSection]) -> [TimeRange] {
        let busy = busyIntervals(on: dayIdx, sections: sections).map { (start: $0.start, end: $0.end) }
        var free: [TimeRange] = []
        var previousEnd = startMinutes
        for (start, end) in busy {
            if start > previousEnd {
                free.append((start: previousEnd, end: start))
            }
            previousEnd = max(previousEnd, end)
        }
        if previousEnd < endMinutes {
            free.append((start: previousEnd, end: endMinutes))
        }
        return free
    }

    static func intersectIntervals(_ a: [TimeRange], _ b: [TimeRange]) -> [TimeRange] {
        var result: [TimeRange] = []
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

        func appendIfFuture(_ item: TodayPlanItem) {
            guard item.endMinutes > nowMinutes else { return }
            var adjusted = item
            if adjusted.startMinutes < nowMinutes {
                adjusted = TodayPlanItem(
                    id: adjusted.id,
                    kind: adjusted.kind,
                    startMinutes: nowMinutes,
                    endMinutes: adjusted.endMinutes,
                    section: adjusted.section,
                    friendOverlaps: adjusted.friendOverlaps
                )
            }
            timeline.append(adjusted)
        }

        while freeIndex < free.count || busyIndex < busy.count {
            let nextFree = freeIndex < free.count ? free[freeIndex] : nil
            let nextBusy = busyIndex < busy.count ? busy[busyIndex] : nil

            guard let block = nextTimelineBlock(free: nextFree, busy: nextBusy) else { break }

            switch block {
            case let .free(freeBlock):
                let overlaps = friendOverlaps(
                    for: freeBlock,
                    dayIdx: dayIdx,
                    friendSectionsById: friendSectionsById,
                    friendNamesById: friendNamesById
                )
                appendIfFuture(
                    TodayPlanItem(
                        id: "free-\(freeBlock.start)-\(freeBlock.end)",
                        kind: .freeBlock,
                        startMinutes: freeBlock.start,
                        endMinutes: freeBlock.end,
                        section: nil,
                        friendOverlaps: overlaps
                    )
                )
                freeIndex += 1

            case let .busy(classBlock):
                appendIfFuture(
                    TodayPlanItem(
                        id: "class-\(classBlock.section.sectionId)",
                        kind: .classBlock,
                        startMinutes: classBlock.start,
                        endMinutes: classBlock.end,
                        section: classBlock.section,
                        friendOverlaps: []
                    )
                )
                busyIndex += 1
            }
        }

        return timeline
    }

    private static func nextTimelineBlock(free: TimeRange?, busy: ClassBlock?) -> TimelineBlock? {
        switch (free, busy) {
        case let (freeBlock?, nil):
            return .free(freeBlock)
        case let (nil, classBlock?):
            return .busy(classBlock)
        case let (freeBlock?, classBlock?):
            return freeBlock.start <= classBlock.start ? .free(freeBlock) : .busy(classBlock)
        case (nil, nil):
            return nil
        }
    }

    private static func friendOverlaps(
        for freeBlock: TimeRange,
        dayIdx: Int,
        friendSectionsById: [String: [CourseSection]],
        friendNamesById: [String: String]
    ) -> [FriendOverlap] {
        let userFree: [TimeRange] = [freeBlock]
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
                    id: "\(friendId)-\(freeBlock.start)",
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
