import Foundation

/// Production HTTP backend. Implements the same contract as `LocalBackendService`.
/// Deploy an API matching `APIRoute` paths, then set `BackendConfiguration.mode = .remote(...)`.
actor RemoteBackendService: BetweenBackendServicing {
    private let client: BetweenAPIClient
    private var cachedDashboard: DashboardData?
    private var cachedEvents: EventsData?

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

    func loginWithSSO(email: String) async throws -> AuthSession {
        let response: LoginResponseBody = try await client.post(
            .sso,
            body: SSORequestBody(email: email)
        )
        cachedDashboard = response.dashboard.asDashboardData()
        return response.session
    }

    func activateNewUser(email: String, code: String) async throws -> AuthSession {
        let response: LoginResponseBody = try await client.post(
            .activate,
            body: ActivateRequestBody(email: email, code: code)
        )
        cachedDashboard = response.dashboard.asDashboardData()
        return response.session
    }

    func submitConsent(session: AuthSession) async throws {
        struct Response: Decodable { let ok: Bool }
        let _: Response = try await client.post(
            .consent,
            body: ConsentRequestBody(accepted: true, ferpaAcknowledged: true, privacyVersion: "2026-07"),
            token: session.token
        )
    }

    func searchSections(query: String) async -> [CourseSection] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let sections: [CourseSection] = (try? await client.get(
            .sectionsSearch,
            query: [URLQueryItem(name: "q", value: query)]
        )) ?? []
        return sections
    }

    func refreshDashboard(session: AuthSession) async throws -> DashboardData {
        let dto: DashboardDTO = try await client.get(.dashboard, token: session.token)
        let dashboard = dto.asDashboardData()
        cachedDashboard = dashboard
        return dashboard
    }

    func sendFriendRequest(session: AuthSession, to studentId: String) async throws {
        struct Body: Encodable { let toStudentId: String }
        let _: OkResponse = try await client.post(.friendRequest, body: Body(toStudentId: studentId), token: session.token)
    }

    func acceptFriendRequest(session: AuthSession, requestId: String) async throws {
        let _: AcceptResponse = try await client.post(.acceptFriendRequest(requestId), body: EmptyBody(), token: session.token)
    }

    func setPresence(session: AuthSession, status: PresenceStatus, activity: String) async throws {
        struct Body: Encodable { let status: String; let activity: String }
        let _: PresenceRecord = try await client.patch(
            .presence,
            body: Body(status: status.rawValue, activity: activity),
            token: session.token
        )
    }

    func setActivityMode(session: AuthSession, mode: ActivityMode) async throws {
        struct Body: Encodable { let mode: String }
        let response: ModeResponseBody = try await client.patch(
            .activityMode,
            body: Body(mode: mode.rawValue),
            token: session.token
        )
        cachedEvents = response.events.asEventsData()
    }

    func fetchEvents(session: AuthSession) async throws -> EventsData {
        let dto: EventsDataDTO = try await client.get(.events, token: session.token)
        let data = dto.asEventsData()
        cachedEvents = data
        return data
    }

    func markEventInterested(session: AuthSession, eventId: String) async throws {
        let dto: EventsDataDTO = try await client.post(
            .eventInterested(eventId),
            body: EmptyBody(),
            token: session.token
        )
        cachedEvents = dto.asEventsData()
    }

    func markLookingForPartner(session: AuthSession, eventId: String, note: String, experience: String) async throws {
        struct Body: Encodable { let note: String; let experience: String }
        let response: PartnerResponseBody = try await client.post(
            .eventPartner(eventId),
            body: Body(note: note, experience: experience),
            token: session.token
        )
        cachedEvents = response.events.asEventsData()
    }

    func updateInterests(session: AuthSession, interestIds: [String]) async throws {
        struct Body: Encodable { let interestIds: [String] }
        let dto: EventsDataDTO = try await client.patch(
            .interests,
            body: Body(interestIds: interestIds),
            token: session.token
        )
        cachedEvents = dto.asEventsData()
    }

    func updateShareFreeTime(session: AuthSession, friendId: String, allowed: Bool) async throws {
        struct Body: Encodable { let friendId: String; let allowed: Bool }
        struct Response: Decodable { let ok: Bool; let shareFreeTimeWith: [String] }
        let _: Response = try await client.patch(
            .shareFreeTime,
            body: Body(friendId: friendId, allowed: allowed),
            token: session.token
        )
    }

    func uploadCourseHashes(session: AuthSession, hashes: [String]) async throws -> CourseHashSyncResult {
        struct Body: Encodable { let hashedCourseIds: [String] }
        struct Response: Decodable {
            let matches: [CourseHashMatch]
            let note: String?
        }
        let response: Response = try await client.post(
            .courseHashes,
            body: Body(hashedCourseIds: hashes),
            token: session.token
        )
        return CourseHashSyncResult(matches: response.matches)
    }

    func createPlan(session: AuthSession, type: String, title: String, location: String) async throws -> Plan {
        struct Body: Encodable { let type: String; let title: String; let location: String }
        return try await client.post(.plans, body: Body(type: type, title: title, location: location), token: session.token)
    }

    func sendNudge(session: AuthSession, to friendId: String, message: String) async throws {
        struct Body: Encodable { let toFriendId: String; let message: String }
        let _: OkResponse = try await client.post(.nudge, body: Body(toFriendId: friendId, message: message), token: session.token)
    }

    func connectPresenceStream(session: AuthSession) async -> AsyncStream<PresenceRecord> {
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
private struct OkResponse: Decodable { let ok: Bool }
private struct AcceptResponse: Decodable {
    let ok: Bool
    let dashboard: DashboardDTO?
}
