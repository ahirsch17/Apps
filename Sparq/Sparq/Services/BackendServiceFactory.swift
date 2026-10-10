import Foundation

enum BackendServiceFactory {
    static func make() throws -> any SparqBackendServicing {
        switch BackendConfiguration.mode {
        case .localSeed:
            return try LocalBackendService.live()
        case .remote(let baseURL):
            return RemoteBackendService(baseURL: baseURL)
        }
    }
}
