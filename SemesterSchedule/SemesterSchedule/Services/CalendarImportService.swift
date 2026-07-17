import EventKit
import Foundation

enum CalendarImportService {
    static func requestAccess(eventStore: EKEventStore = EKEventStore()) async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    /// Saves recurring weekly events until `semesterEnd` (end of day). Returns count saved.
    static func save(
        _ events: [EditableScheduleEvent],
        eventStore: EKEventStore = EKEventStore(),
        calendar: EKCalendar? = nil
    ) throws -> Int {
        let cal = calendar ?? eventStore.defaultCalendarForNewEvents
        guard let targetCal = cal else {
            throw NSError(
                domain: "SemesterSchedule",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No default calendar is set. Open the Calendar app once, add an account if needed, then try again."]
            )
        }

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        var saved = 0

        for ev in events where ev.isSelected {
            guard let firstStart = ev.firstOccurrenceStart(calendar: gregorian) else { continue }
            let duration = ev.durationSeconds(calendar: gregorian)
            let firstEnd = firstStart.addingTimeInterval(duration)

            let ek = EKEvent(eventStore: eventStore)
            ek.calendar = targetCal
            ek.title = ev.title
            ek.location = ev.location
            ek.notes = ev.notes
            ek.startDate = firstStart
            ek.endDate = firstEnd

            let days: [EKRecurrenceDayOfWeek] = ev.weekdays.compactMap { wd in
                guard let w = EKWeekday(rawValue: wd) else { return nil }
                return EKRecurrenceDayOfWeek(w)
            }
            guard days.isEmpty == false else { continue }

            let endDay = gregorian.startOfDay(for: ev.semesterEnd).addingTimeInterval(24 * 3600 - 1)
            let endRule = EKRecurrenceEnd(end: endDay)
            let rule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: days,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: endRule
            )
            ek.recurrenceRules = [rule]

            try eventStore.save(ek, span: .futureEvents)
            saved += 1
        }

        return saved
    }
}
