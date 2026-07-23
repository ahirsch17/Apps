import Foundation

/// In-process backend backed by bundled `seed_data.json`. Drop-in replacement for `RemoteBackendService`.
actor LocalBackendService: BetweenBackendServicing {
    private var database: SeedDatabase
    private var friendRequests: [FriendRequest]
    private var friendships: [Friendship]
    private var presenceByStudentId: [String: PresenceRecord]
    private var plans: [Plan]

    init(database: SeedDatabase) {
        self.database = database
        self.friendRequests = database.friendRequests
        self.friendships = database.friendships
        self.presenceByStudentId = Dictionary(uniqueKeysWithValues: database.presence.map { ($0.studentId, $0) })
        self.plans = database.plans
    }

    static func live() throws -> LocalBackendService {
        LocalBackendService(database: try SeedDataLoader.loadFromBundle())
    }

    func fetchLoginCandidates() async -> [Student] {
        Array(database.students.prefix(12))
    }

    func login(email: String, password: String?) async throws -> AuthSession {
        _ = password
        guard let me = database.students.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw BackendError.userNotFound
        }
        return AuthSession(userId: me.id, email: me.email, token: "local-\(me.id)")
    }

    func refreshDashboard(session: AuthSession) async throws -> DashboardData {
        try dashboard(for: session.userId)
    }

    func sendFriendRequest(session: AuthSession, to studentId: String) async throws {
        let from = session.userId
        guard from != studentId else { throw BackendError.invalidRequest }

        let alreadyFriends = friendships.contains {
            ($0.studentA == from && $0.studentB == studentId) || ($0.studentA == studentId && $0.studentB == from)
        }
        if alreadyFriends { return }

        let pendingAlready = friendRequests.contains {
            (($0.fromStudentId == from && $0.toStudentId == studentId) || ($0.fromStudentId == studentId && $0.toStudentId == from))
            && $0.status == "pending"
        }
        if pendingAlready { return }

        friendRequests.append(
            FriendRequest(
                id: "req-\(UUID().uuidString.prefix(8))",
                fromStudentId: from,
                toStudentId: studentId,
                status: "pending",
                createdAt: Date()
            )
        )
    }

    func acceptFriendRequest(session: AuthSession, requestId: String) async throws {
        guard let idx = friendRequests.firstIndex(where: {
            $0.id == requestId && $0.toStudentId == session.userId && $0.status == "pending"
        }) else {
            throw BackendError.invalidRequest
        }
        let req = friendRequests[idx]
        friendRequests[idx].status = "accepted"
        friendships.append(Friendship(studentA: req.fromStudentId, studentB: req.toStudentId, status: "accepted"))
    }

    func setPresence(session: AuthSession, status: PresenceStatus, activity: String) async throws {
        guard var presence = presenceByStudentId[session.userId] else {
            throw BackendError.userNotFound
        }
        presence.status = status
        presence.activity = activity
        presence.lastUpdated = Date()
        presenceByStudentId[session.userId] = presence
    }

    func createPlan(session: AuthSession, type: String, title: String, location: String) async throws -> Plan {
        let plan = Plan(
            id: "plan-\(UUID().uuidString.prefix(8))",
            creatorId: session.userId,
            type: type,
            title: title,
            location: location,
            startTime: Date().addingTimeInterval(15 * 60),
            visibility: "friends"
        )
        plans.append(plan)
        return plan
    }

    func sendNudge(session: AuthSession, to friendId: String, message: String) async throws {
        guard database.students.contains(where: { $0.id == session.userId }),
              database.students.contains(where: { $0.id == friendId }) else {
            throw BackendError.userNotFound
        }
        _ = message
    }

    func connectPresenceStream(session: AuthSession) async -> AsyncStream<PresenceRecord> {
        _ = session
        return AsyncStream { continuation in
            let task = Task.detached { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(4))
                    guard let self else { continue }
                    if let updated = await self.randomPresenceUpdate() {
                        continuation.yield(updated)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func dashboard(for studentId: String) throws -> DashboardData {
        guard let me = database.students.first(where: { $0.id == studentId }) else {
            throw BackendError.userNotFound
        }
        return DashboardBuilder.build(
            DashboardBuilder.Input(
                me: me,
                students: database.students,
                sections: database.sections,
                enrollments: database.enrollments,
                friendships: friendships,
                friendRequests: friendRequests,
                presenceByStudentId: presenceByStudentId,
                plans: plans,
                syncTime: Date()
            )
        )
    }

    private func randomPresenceUpdate() -> PresenceRecord? {
        guard let key = presenceByStudentId.keys.randomElement(), var presence = presenceByStudentId[key] else { return nil }
        presence.status = PresenceStatus.allCases.randomElement() ?? .freeNow
        presence.activity = ["Coffee", "On the way", "Study", "Gym", "In class"].randomElement() ?? "Free"
        presence.location = ["Newman Library", "Squires", "McBryde", "Drillfield"].randomElement() ?? "Campus"
        presence.lastUpdated = Date()
        presenceByStudentId[key] = presence
        return presence
    }
}
