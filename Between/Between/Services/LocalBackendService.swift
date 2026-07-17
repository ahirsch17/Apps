import Foundation

protocol BetweenBackendServicing {
    // API-like calls
    func login(email: String) async throws -> DashboardData
    func fetchLoginCandidates() async -> [Student]
    func refreshDashboard(for studentId: String) async throws -> DashboardData
    func sendFriendRequest(from: String, to: String) async throws
    func acceptFriendRequest(requestId: String, actingUserId: String) async throws

    // websocket-like stream
    func connectPresenceStream() async -> AsyncStream<PresenceRecord>
}

enum BackendError: Error, LocalizedError {
    case missingSeedData
    case userNotFound
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .missingSeedData: return "seed_data.json is missing from app resources."
        case .userNotFound: return "No user found for that email."
        case .invalidRequest: return "Request is no longer valid."
        }
    }
}

actor LocalBackendService: BetweenBackendServicing {
    private var database: SeedDatabase
    private var friendRequests: [FriendRequest]
    private var friendships: [Friendship]
    private var presenceByStudentId: [String: PresenceRecord]
    private let avatarEmojis = ["🙂", "😎", "🤓", "🧠", "🏃", "☕", "📚", "🎧", "✨", "🌟", "🦉", "🔥"]

    init(database: SeedDatabase) {
        self.database = database
        self.friendRequests = database.friendRequests
        self.friendships = database.friendships
        self.presenceByStudentId = Dictionary(uniqueKeysWithValues: database.presence.map { ($0.studentId, $0) })
    }

    static func live() throws -> LocalBackendService {
        guard let url = Bundle.main.url(forResource: "seed_data", withExtension: "json") else {
            throw BackendError.missingSeedData
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let db = try decoder.decode(SeedDatabase.self, from: data)
        return LocalBackendService(database: db)
    }

    func fetchLoginCandidates() async -> [Student] {
        Array(database.students.prefix(12))
    }

    func login(email: String) async throws -> DashboardData {
        guard let me = database.students.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw BackendError.userNotFound
        }
        return buildDashboard(for: me.id, syncTime: Date())
    }

    func refreshDashboard(for studentId: String) async throws -> DashboardData {
        guard database.students.contains(where: { $0.id == studentId }) else {
            throw BackendError.userNotFound
        }
        return buildDashboard(for: studentId, syncTime: Date())
    }

    func sendFriendRequest(from: String, to: String) async throws {
        guard from != to else { throw BackendError.invalidRequest }
        let alreadyFriends = friendships.contains {
            ($0.studentA == from && $0.studentB == to) || ($0.studentA == to && $0.studentB == from)
        }
        if alreadyFriends { return }

        let pendingAlready = friendRequests.contains {
            (($0.fromStudentId == from && $0.toStudentId == to) || ($0.fromStudentId == to && $0.toStudentId == from))
            && $0.status == "pending"
        }
        if pendingAlready { return }

        friendRequests.append(
            FriendRequest(
                id: "req-\(UUID().uuidString.prefix(8))",
                fromStudentId: from,
                toStudentId: to,
                status: "pending",
                createdAt: Date()
            )
        )
    }

    func acceptFriendRequest(requestId: String, actingUserId: String) async throws {
        guard let idx = friendRequests.firstIndex(where: { $0.id == requestId && $0.toStudentId == actingUserId && $0.status == "pending" }) else {
            throw BackendError.invalidRequest
        }
        let req = friendRequests[idx]
        friendRequests[idx].status = "accepted"
        friendships.append(Friendship(studentA: req.fromStudentId, studentB: req.toStudentId, status: "accepted"))
    }

    func connectPresenceStream() async -> AsyncStream<PresenceRecord> {
        AsyncStream { continuation in
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

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func randomPresenceUpdate() -> PresenceRecord? {
        guard let key = presenceByStudentId.keys.randomElement(), var presence = presenceByStudentId[key] else { return nil }
        presence.status = PresenceStatus.allCases.randomElement() ?? .freeNow
        presence.activity = ["Grabbing coffee", "On the way", "Study sprint", "Gym run", "In lecture"].randomElement() ?? "Free"
        presence.location = ["Newman Library", "Squires", "McBryde Hall", "War Memorial Gym", "Drillfield"].randomElement() ?? "Campus"
        presence.lastUpdated = Date()
        presenceByStudentId[key] = presence
        return presence
    }

    private func buildDashboard(for studentId: String, syncTime: Date) -> DashboardData {
        let me = database.students.first(where: { $0.id == studentId })!
        let friendIds = Set(friendships.compactMap { relation -> String? in
            guard relation.status == "accepted" else { return nil }
            if relation.studentA == studentId { return relation.studentB }
            if relation.studentB == studentId { return relation.studentA }
            return nil
        })

        let nearbyFriends: [FriendCard] = database.students
            .filter { friendIds.contains($0.id) }
            .compactMap { student in
                guard let presence = presenceByStudentId[student.id] else { return nil }
                return FriendCard(
                    id: student.id,
                    name: student.name,
                    email: student.email,
                    avatarEmoji: avatarEmoji(for: student),
                    status: presence.status,
                    activity: presence.activity,
                    location: presence.location,
                    distanceLabel: ["2 min walk", "5 min walk", "8 min walk", "12 min walk"].randomElement()!
                )
            }
            .sorted(by: { $0.name < $1.name })

        let mySectionIds = Set(database.enrollments.filter { $0.studentId == studentId }.map(\.sectionId))
        let sectionById = Dictionary(uniqueKeysWithValues: database.sections.map { ($0.sectionId, $0) })
        let mySections = mySectionIds.compactMap { sectionById[$0] }
        let myByCanonical = Dictionary(grouping: mySections, by: \.canonicalCourseId)

        let classConnections: [ClassConnection] = nearbyFriends.compactMap { friend in
            let friendSections = Set(database.enrollments.filter { $0.studentId == friend.id }.map(\.sectionId))
            let overlaps = friendSections.compactMap { sectionById[$0] }.filter { myByCanonical[$0.canonicalCourseId] != nil }
            guard let matched = overlaps.first else { return nil }
            let myMatch = myByCanonical[matched.canonicalCourseId]?.first
            let kind: ClassConnection.Kind = myMatch?.sectionId == matched.sectionId ? .sameSection : .differentSection
            return ClassConnection(
                id: "\(friend.id)-\(matched.canonicalCourseId)",
                courseCode: matched.courseCode,
                courseName: matched.courseName,
                friendName: friend.name,
                kind: kind,
                sectionLabel: kind == .sameSection ? "Section \(matched.sectionLabel)" : "Section \(myMatch?.sectionLabel ?? "--") vs \(matched.sectionLabel)",
                meetingDays: matched.meetingDays
            )
        }

        let incoming = friendRequests.filter { $0.toStudentId == studentId && $0.status == "pending" }
        let outgoing = friendRequests.filter { $0.fromStudentId == studentId && $0.status == "pending" }
        let pendingIncomingRequests = incoming.compactMap { req in database.students.first(where: { $0.id == req.fromStudentId }) }
        let pendingOutgoingRequests = outgoing.compactMap { req in database.students.first(where: { $0.id == req.toStudentId }) }
        let blockedIds = friendIds.union([studentId]).union(Set(pendingOutgoingRequests.map(\.id))).union(Set(pendingIncomingRequests.map(\.id)))
        let suggestedStudents = Array(database.students.filter { !blockedIds.contains($0.id) }.prefix(20))
        let visiblePlans = database.plans.filter { friendIds.contains($0.creatorId) }.sorted(by: { $0.startTime < $1.startTime })

        return DashboardData(
            me: me,
            nearbyFriends: nearbyFriends,
            classConnections: classConnections,
            mySections: mySections.sorted { $0.courseCode < $1.courseCode },
            pendingIncomingRequests: pendingIncomingRequests,
            pendingOutgoingRequests: pendingOutgoingRequests,
            suggestedStudents: suggestedStudents,
            plans: visiblePlans,
            syncTimestamp: syncTime
        )
    }

    private func avatarEmoji(for student: Student) -> String {
        let idx = abs(student.id.hashValue) % avatarEmojis.count
        return avatarEmojis[idx]
    }
}

extension LocalBackendService: LocalBackendServiceAccessor {
    func pendingRequestId(from: String, to: String) async -> String? {
        friendRequests.first(where: { $0.fromStudentId == from && $0.toStudentId == to && $0.status == "pending" })?.id
    }
}
