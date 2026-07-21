import EventKit
import Foundation

enum CalendarDestination: String, CaseIterable, Identifiable {
    case apple
    case google
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .both: return "Both"
        }
    }

    var detail: String {
        switch self {
        case .apple: return "Saves into a calendar on this iPhone (Apple or a Google account already added in Settings → Calendar)."
        case .google: return "Shares a .ics file you can open in Google Calendar (or any calendar app)."
        case .both: return "Saves on this iPhone and shares a .ics for Google Calendar."
        }
    }

    var usesEventKit: Bool {
        switch self {
        case .apple, .both: return true
        case .google: return false
        }
    }

    var usesICSShare: Bool {
        switch self {
        case .google, .both: return true
        case .apple: return false
        }
    }
}

enum CalendarImportService {
    static func requestAccess(eventStore: EKEventStore = EKEventStore()) async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    /// Writable event calendars (Apple iCloud, Google, Exchange, local, etc.).
    static func writableCalendars(eventStore: EKEventStore) -> [EKCalendar] {
        eventStore.calendars(for: .event)
            .filter(\.allowsContentModifications)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    static func defaultCalendar(eventStore: EKEventStore) -> EKCalendar? {
        eventStore.defaultCalendarForNewEvents
    }

    /// Saves recurring weekly events from blueprints. Returns count saved.
    static func save(
        blueprints: [CalendarEventBlueprint],
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

        var saved = 0
        for bp in blueprints {
            let ek = EKEvent(eventStore: eventStore)
            ek.calendar = targetCal
            ek.title = bp.title
            ek.location = bp.location.isEmpty ? nil : bp.location
            ek.notes = bp.notes.isEmpty ? nil : bp.notes
            ek.startDate = bp.firstStart
            ek.endDate = bp.firstEnd

            let days: [EKRecurrenceDayOfWeek] = bp.weekdays.compactMap { wd in
                guard let w = EKWeekday(rawValue: wd) else { return nil }
                return EKRecurrenceDayOfWeek(w)
            }
            guard days.isEmpty == false else { continue }

            let endRule = EKRecurrenceEnd(end: bp.recurrenceEnd)
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
            if bp.alarmMinutesBefore > 0 {
                ek.addAlarm(EKAlarm(relativeOffset: TimeInterval(-bp.alarmMinutesBefore * 60)))
            }

            try eventStore.save(ek, span: .futureEvents)
            saved += 1
        }

        return saved
    }

    /// Convenience: plan + save selected editable events.
    static func save(
        _ events: [EditableScheduleEvent],
        eventStore: EKEventStore = EKEventStore(),
        calendar: EKCalendar? = nil,
        timeZone: TimeZone = .current
    ) throws -> Int {
        let plans = CalendarEventPlanner.blueprints(from: events, timeZone: timeZone)
        return try save(blueprints: plans, eventStore: eventStore, calendar: calendar)
    }
}
