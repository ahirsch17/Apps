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
    #else
    static var mode: BackendMode = .remote(baseURL: URL(string: "https://api.between.app")!)
    #endif

    static var remoteBaseURL: URL? {
        if case .remote(let url) = mode { return url }
        return nil
    }
}
