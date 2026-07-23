import Foundation

/// Contract between the iOS app and any backend (local seed file or deployed API).
/// UI and ViewModels depend only on this protocol — swap implementations via `BackendConfiguration`.
protocol BetweenBackendServicing: Sendable {
    func fetchLoginCandidates() async -> [Student]
    func login(email: String, password: String?) async throws -> AuthSession
    func activateNewUser(email: String, code: String) async throws -> AuthSession
    func searchSections(query: String) async -> [CourseSection]
    func refreshDashboard(session: AuthSession) async throws -> DashboardData
    func sendFriendRequest(session: AuthSession, to studentId: String) async throws
    func acceptFriendRequest(session: AuthSession, requestId: String) async throws
    func setPresence(session: AuthSession, status: PresenceStatus, activity: String) async throws
    func createPlan(session: AuthSession, type: String, title: String, location: String) async throws -> Plan
    func sendNudge(session: AuthSession, to friendId: String, message: String) async throws
    func connectPresenceStream(session: AuthSession) async -> AsyncStream<PresenceRecord>
}

struct AuthSession: Codable, Hashable, Sendable {
    let userId: String
    let email: String
    let token: String
}

enum BackendError: Error, LocalizedError {
    case missingSeedData
    case userNotFound
    case invalidRequest
    case unauthorized
    case network(underlying: Error)
    case server(message: String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .missingSeedData: return "Demo data file is missing from the app bundle."
        case .userNotFound: return "No account found for that email."
        case .invalidRequest: return "That request is no longer valid."
        case .unauthorized: return "Please sign in again."
        case .network(let underlying): return underlying.localizedDescription
        case .server(let message): return message
        case .notImplemented: return "This action is not available yet on the remote server."
        }
    }
}
