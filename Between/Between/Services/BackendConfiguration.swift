import Foundation

/// Single switch for demo vs production backend.
///
/// **Layering (no people/courses in engines):**
/// - *Data:* `seed_data.json`, `simulated_device_contacts.json`, `local_demo_config.json` (local only)
/// - *Transport:* `LocalBackendService` / `RemoteBackendService` implementing `BetweenBackendServicing`
/// - *Domain:* `DashboardBuilder`, `ScheduleEngine`, `ContactSuggestionMatcher`, `CourseHashService` — pure functions over inputs
/// - *UI:* `AppViewModel` + views; they only call the protocol and render DTOs
///
/// Swap `mode` to `.remote` when the API owns auth, storage, and contact matching.
enum BackendMode: Equatable {
    case localSeed
    case remote(baseURL: URL)
}

enum BackendConfiguration {
    /// Change this one reference when the deployed API is ready.
    #if DEBUG
    static var mode: BackendMode = .localSeed
    #else
    static var mode: BackendMode = .remote(baseURL: URL(string: "https://api.between.app")!)
    #endif

    private static let demoClockKey = "between.useDemoScheduleClock"

    /// Pitch-only: frozen Wednesday 10:15 AM so registrar overlaps look good in recordings.
    /// Off by default — real installs use the device clock.
    static var usesDemoScheduleClock: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: demoClockKey)
        #else
        false
        #endif
    }

    static func setUsesDemoScheduleClock(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: demoClockKey)
    }

    private static let pitchDemoWeekdayIndex = 3 // Wednesday
    private static let pitchDemoNowMinutes = 10 * 60 + 15

    static func weekdayIndex(from date: Date = Date()) -> Int {
        if usesDemoScheduleClock { return pitchDemoWeekdayIndex }
        return Calendar.current.component(.weekday, from: date) - 1
    }

    static func nowMinutes(from date: Date = Date()) -> Int {
        if usesDemoScheduleClock { return pitchDemoNowMinutes }
        let calendar = Calendar.current
        return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    static func weekdayName(from date: Date = Date()) -> String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let idx = weekdayIndex(from: date)
        guard idx >= 0, idx < names.count else { return names[0] }
        return names[idx]
    }

    static func formattedToday(from date: Date = Date()) -> String {
        if usesDemoScheduleClock {
            return "\(weekdayName(from: date)) · demo day"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    static var remoteBaseURL: URL? {
        if case .remote(let url) = mode { return url }
        return nil
    }
}
