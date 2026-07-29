import CoreGraphics
import Foundation

/// Data for the day overlap board: 8am–7pm, top starred friends, class + overlap blocks.
enum OverlapTimelineModel {
    static let dayStartMinutes = 8 * 60
    static let dayEndMinutes = 19 * 60
    static let maxFriendRows = 4
    static let minOverlapMinutes = ScheduleEngine.minOverlapMinutes

    struct TimeBlock: Identifiable, Hashable, Sendable {
        let id: String
        let startMinutes: Int
        let endMinutes: Int
        let label: String?

        var durationMinutes: Int { endMinutes - startMinutes }

        func clamped(to range: ClosedRange<Int>) -> TimeBlock? {
            let start = max(startMinutes, range.lowerBound)
            let end = min(endMinutes, range.upperBound)
            guard end > start else { return nil }
            return TimeBlock(id: id, startMinutes: start, endMinutes: end, label: label)
        }
    }

    struct FriendRow: Identifiable, Sendable {
        let id: String
        let name: String
        let colorIndex: Int
        let overlapBlocks: [TimeBlock]
        let totalOverlapMinutes: Int

        var firstName: String {
            FriendColorPalette.firstName(name)
        }
    }

    struct Board: Sendable {
        let friendRows: [FriendRow]
        let classBlocks: [TimeBlock]
        let dayRange: ClosedRange<Int>

        var isEmpty: Bool { friendRows.isEmpty && classBlocks.isEmpty }
    }

    static func build(
        from todayPlan: [TodayPlanItem],
        starredIds: Set<String>
    ) -> Board {
        let dayRange = dayStartMinutes...dayEndMinutes

        let classBlocks = todayPlan
            .filter { $0.kind == .classBlock }
            .compactMap { item -> TimeBlock? in
                TimeBlock(
                    id: item.id,
                    startMinutes: item.startMinutes,
                    endMinutes: item.endMinutes,
                    label: item.section?.courseCode
                ).clamped(to: dayRange)
            }

        var minutesByFriend: [String: (name: String, minutes: Int, intervals: [(start: Int, end: Int)])] = [:]

        for item in todayPlan where item.kind == .freeBlock {
            let overlaps = starredIds.isEmpty
                ? item.qualifyingOverlaps()
                : item.starredOverlaps(starredIds: starredIds)

            for overlap in overlaps {
                for interval in overlap.intervals where interval.end - interval.start >= minOverlapMinutes {
                    var entry = minutesByFriend[overlap.friendId]
                        ?? (name: overlap.friendName, minutes: 0, intervals: [])
                    let duration = interval.end - interval.start
                    entry.minutes += duration
                    entry.intervals.append((interval.start, interval.end))
                    minutesByFriend[overlap.friendId] = entry
                }
            }
        }

        let sorted = minutesByFriend
            .sorted { $0.value.minutes > $1.value.minutes }
            .prefix(maxFriendRows)

        let friendRows: [FriendRow] = sorted.enumerated().map { index, pair in
            let merged = mergeIntervals(pair.value.intervals)
            let blocks = merged.compactMap { interval -> TimeBlock? in
                TimeBlock(
                    id: "\(pair.key)-\(interval.start)",
                    startMinutes: interval.start,
                    endMinutes: interval.end,
                    label: nil
                ).clamped(to: dayRange)
            }
            return FriendRow(
                id: pair.key,
                name: pair.value.name,
                colorIndex: index,
                overlapBlocks: blocks,
                totalOverlapMinutes: pair.value.minutes
            )
        }

        return Board(friendRows: friendRows, classBlocks: classBlocks, dayRange: dayRange)
    }

    // MARK: - Layout helpers

    static func fraction(for minutes: Int, in range: ClosedRange<Int>) -> CGFloat {
        let span = CGFloat(range.upperBound - range.lowerBound)
        guard span > 0 else { return 0 }
        return CGFloat(minutes - range.lowerBound) / span
    }

    static func width(for start: Int, end: Int, totalWidth: CGFloat, range: ClosedRange<Int>) -> CGFloat {
        let span = CGFloat(range.upperBound - range.lowerBound)
        guard span > 0 else { return 0 }
        return CGFloat(end - start) / span * totalWidth
    }

    static func xOffset(for minutes: Int, totalWidth: CGFloat, range: ClosedRange<Int>) -> CGFloat {
        fraction(for: minutes, in: range) * totalWidth
    }

    static var hourMarkers: [Int] {
        stride(from: dayStartMinutes, through: dayEndMinutes, by: 120).map { $0 }
    }

    private static func mergeIntervals(_ intervals: [(start: Int, end: Int)]) -> [(start: Int, end: Int)] {
        guard !intervals.isEmpty else { return [] }
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [(start: Int, end: Int)] = [sorted[0]]
        for interval in sorted.dropFirst() {
            var last = merged.removeLast()
            if interval.start <= last.end {
                last.end = max(last.end, interval.end)
                merged.append(last)
            } else {
                merged.append(last)
                merged.append(interval)
            }
        }
        return merged
    }
}
