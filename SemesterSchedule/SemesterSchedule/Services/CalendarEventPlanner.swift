import Foundation

/// Pure, testable plan for one recurring class meeting (shared by EventKit + ICS).
struct CalendarEventBlueprint: Equatable {
    var title: String
    var location: String
    var notes: String
    var firstStart: Date
    var firstEnd: Date
    /// `Calendar` weekday numbers 1…7 (Sunday…Saturday)
    var weekdays: [Int]
    var recurrenceEnd: Date
    var alarmMinutesBefore: Int
}

enum CalendarEventPlanner {
    static let defaultAlarmMinutes = 15

    /// Builds importable blueprints for selected rows that have weekdays and real meeting times.
    static func blueprints(
        from events: [EditableScheduleEvent],
        timeZone: TimeZone = .current,
        alarmMinutesBefore: Int = defaultAlarmMinutes
    ) -> [CalendarEventBlueprint] {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone

        var out: [CalendarEventBlueprint] = []
        for ev in events where ev.isSelected && ev.canAddToCalendar {
            guard let firstStart = ev.firstOccurrenceStart(calendar: gregorian) else { continue }
            let duration = ev.durationSeconds(calendar: gregorian)
            guard duration > 0 else { continue }
            let firstEnd = firstStart.addingTimeInterval(duration)
            let endDay = gregorian.startOfDay(for: ev.semesterEnd).addingTimeInterval(24 * 3600 - 1)
            out.append(
                CalendarEventBlueprint(
                    title: ev.title,
                    location: ev.location,
                    notes: ev.notes,
                    firstStart: firstStart,
                    firstEnd: firstEnd,
                    weekdays: ev.weekdays.sorted(),
                    recurrenceEnd: endDay,
                    alarmMinutesBefore: alarmMinutesBefore
                )
            )
        }
        return out
    }

    /// ICS weekday tokens for RRULE BYDAY (SU…SA).
    static func icsByDayToken(forCalendarWeekday wd: Int) -> String? {
        switch wd {
        case 1: return "SU"
        case 2: return "MO"
        case 3: return "TU"
        case 4: return "WE"
        case 5: return "TH"
        case 6: return "FR"
        case 7: return "SA"
        default: return nil
        }
    }
}
