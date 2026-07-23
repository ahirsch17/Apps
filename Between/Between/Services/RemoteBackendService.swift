import Foundation

/// Production HTTP backend. Implements the same contract as `LocalBackendService`.
/// Deploy an API matching `APIRoute` paths, then set `BackendConfiguration.mode = .remote(...)`.
actor RemoteBackendService: BetweenBackendServicing {
    private let client: BetweenAPIClient
    private var cachedDashboard: DashboardData?

    init(baseURL: URL) {
        client = BetweenAPIClient(baseURL: baseURL)
    }

    func fetchLoginCandidates() async -> [Student] {
        let students: [Student] = (try? await client.get(.loginCandidates)) ?? []
        return students
    }

    func login(email: String, password: String?) async throws -> AuthSession {
        let response: LoginResponseBody = try await client.post(
            .login,
            body: LoginRequestBody(email: email, password: password)
        )
        cachedDashboard = response.dashboard.asDashboardData()
        return response.session
    }

    func refreshDashboard(session: AuthSession) async throws -> DashboardData {
        let dto: DashboardDTO = try await client.get(.dashboard, token: session.token)
        let dashboard = dto.asDashboardData()
        cachedDashboard = dashboard
        return dashboard
    }

    func sendFriendRequest(session: AuthSession, to studentId: String) async throws {
        struct Body: Encodable { let toStudentId: String }
        let _: EmptyResponse = try await client.post(.friendRequest, body: Body(toStudentId: studentId), token: session.token)
    }

    func acceptFriendRequest(session: AuthSession, requestId: String) async throws {
        let _: EmptyResponse = try await client.post(.acceptFriendRequest(requestId), body: EmptyBody(), token: session.token)
    }

    func setPresence(session: AuthSession, status: PresenceStatus, activity: String) async throws {
        struct Body: Encodable { let status: String; let activity: String }
        let _: PresenceRecord = try await client.patch(
            .presence,
            body: Body(status: status.rawValue, activity: activity),
            token: session.token
        )
    }

    func createPlan(session: AuthSession, type: String, title: String, location: String) async throws -> Plan {
        struct Body: Encodable { let type: String; let title: String; let location: String }
        return try await client.post(.plans, body: Body(type: type, title: title, location: location), token: session.token)
    }

    func sendNudge(session: AuthSession, to friendId: String, message: String) async throws {
        struct Body: Encodable { let toFriendId: String; let message: String }
        let _: EmptyResponse = try await client.post(.nudge, body: Body(toFriendId: friendId, message: message), token: session.token)
    }

    func connectPresenceStream(session: AuthSession) async -> AsyncStream<PresenceRecord> {
        // Until SSE/WebSocket is deployed, poll dashboard on an interval.
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(5))
                    if let dashboard = try? await refreshDashboard(session: session),
                       let record = dashboard.nearbyFriends.first.flatMap({ _ in
                           PresenceRecord(
                               studentId: session.userId,
                               status: .freeNow,
                               activity: "Update",
                               location: "Campus",
                               lastUpdated: Date()
                           )
                       }) {
                        continuation.yield(record)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private struct EmptyBody: Encodable {}
private struct EmptyResponse: Decodable {}
