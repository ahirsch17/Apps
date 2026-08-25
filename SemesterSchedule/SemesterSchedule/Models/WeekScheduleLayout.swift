import Foundation

/// Pure layout for the week preview — testable without SwiftUI.
enum WeekScheduleLayout {
    struct PlacedBlock: Equatable {
        var eventID: UUID
        var weekday: Int
        var startMinutes: Int
        var endMinutes: Int
        var column: Int
        var columnCount: Int

        var id: String { "\(eventID.uuidString)-\(weekday)" }
    }

    static func timedEvents(in events: [EditableScheduleEvent]) -> [EditableScheduleEvent] {
        events.filter { $0.isTBA == false && $0.weekdays.isEmpty == false }
    }

    static func visibleDays(for events: [EditableScheduleEvent]) -> [Int] {
        let used = Set(timedEvents(in: events).flatMap(\.weekdays))
        if used.contains(1) || used.contains(7) { return [1, 2, 3, 4, 5, 6, 7] }
        return [2, 3, 4, 5, 6]
    }

    /// Inclusive hour labels (0…23). Expands to fit every timed meeting.
    static func hourRange(for events: [EditableScheduleEvent]) -> ClosedRange<Int> {
        let timed = timedEvents(in: events)
        guard timed.isEmpty == false else { return 8...16 }

        let starts = timed.map(\.startHour)
        let endHours = timed.map { ev -> Int in
            let s = ev.startHour * 60 + ev.startMinute
            var e = ev.endHour * 60 + ev.endMinute
            if e <= s { e += 24 * 60 }
            return min(23, (e - 1) / 60)
        }
        let lo = max(0, (starts.min() ?? 8) - 1)
        let hi = min(23, (endHours.max() ?? 17) + 1)
        return lo...max(lo + 1, hi)
    }

    static func placedBlocks(
        from events: [EditableScheduleEvent],
        on weekday: Int,
        clippingTo hours: ClosedRange<Int>
    ) -> [PlacedBlock] {
        let clipEnd = (hours.upperBound + 1) * 60
        var blocks: [PlacedBlock] = timedEvents(in: events)
            .filter { $0.weekdays.contains(weekday) }
            .compactMap { ev in
                let start = ev.startHour * 60 + ev.startMinute
                var end = ev.endHour * 60 + ev.endMinute
                if end <= start { end += 24 * 60 }
                end = min(end, clipEnd)
                guard end > start else { return nil }
                return PlacedBlock(
                    eventID: ev.id,
                    weekday: weekday,
                    startMinutes: start,
                    endMinutes: end,
                    column: 0,
                    columnCount: 1
                )
            }

        blocks.sort {
            if $0.startMinutes != $1.startMinutes { return $0.startMinutes < $1.startMinutes }
            return $0.endMinutes > $1.endMinutes
        }

        var active: [(end: Int, col: Int)] = []
        for i in blocks.indices {
            active.removeAll { $0.end <= blocks[i].startMinutes }
            let used = Set(active.map(\.col))
            var col = 0
            while used.contains(col) { col += 1 }
            blocks[i].column = col
            active.append((blocks[i].endMinutes, col))
        }
        let count = (blocks.map(\.column).max() ?? 0) + 1
        for i in blocks.indices { blocks[i].columnCount = count }
        return blocks
    }
}
