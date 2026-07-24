import Foundation

/// Single switch for demo vs production backend.
///
/// To go live: set `mode = .remote(...)` and deploy an API that implements `BetweenBackendServicing` routes.
enum BackendMode: Equatable {
    case localSeed
    case remote(baseURL: URL)
}

enum BackendConfiguration {
    /// Change this one reference when the deployed API is ready.
    #if DEBUG
    static var mode: BackendMode = .localSeed
    /// Demo always shows Wednesday with a mid-morning "now" so overlaps look realistic.
    static var demoWeekdayIndex: Int? = 3
    static var demoNowMinutes: Int? = 10 * 60 + 15
    #else
    static var mode: BackendMode = .remote(baseURL: URL(string: "https://api.between.app")!)
    static var demoWeekdayIndex: Int? = nil
    static var demoNowMinutes: Int? = nil
    #endif

    static func demoWeekdayName(now: Date = Date()) -> String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let idx = demoWeekdayIndex ?? (Calendar.current.component(.weekday, from: now) - 1)
        return names[idx]
    }

    static var remoteBaseURL: URL? {
        if case .remote(let url) = mode { return url }
        return nil
    }
}
