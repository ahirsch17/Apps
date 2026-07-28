import Foundation

/// In-process backend backed by bundled `seed_data.json`. Drop-in replacement for `RemoteBackendService`.
actor LocalBackendService: BetweenBackendServicing {
    private var database: SeedDatabase
    private var friendRequests: [FriendRequest]
    private var friendships: [Friendship]
    private var presenceByStudentId: [String: PresenceRecord]
    private var plans: [Plan]
    private var studentProfiles: [StudentProfile]
    private var eventParticipations: [EventParticipation]
    private var partnerProfiles: [PartnerSeekingProfile]
    private var activeModeByStudentId: [String: (mode: ActivityMode, expiresAt: Date)] = [:]

    init(database: SeedDatabase) {
        self.database = database
        self.friendRequests = database.friendRequests
        self.friendships = database.friendships
        self.presenceByStudentId = Dictionary(uniqueKeysWithValues: database.presence.map { ($0.studentId, $0) })
        self.plans = database.plans
        self.studentProfiles = database.studentProfiles
        self.eventParticipations = database.eventParticipations
        self.partnerProfiles = database.partnerProfiles
    }

    static func live() throws -> LocalBackendService {
        LocalBackendService(database: try SeedDataLoader.loadFromBundle())
    }

    func fetchLoginCandidates() async -> [Student] {
        Array(database.students.prefix(12))
    }

    func login(email: String, password: String?) async throws -> AuthSession {
        guard let me = database.students.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw BackendError.userNotFound
        }
        if let password, !password.isEmpty, password != "demo123" {
            throw BackendError.server(message: "Incorrect password. Demo password is demo123.")
        }
        return AuthSession(userId: me.id, email: me.email, token: "local-\(me.id)")
    }

    func loginWithSSO(email: String) async throws -> AuthSession {
        guard email.lowercased().hasSuffix("@vt.edu") else {
            throw BackendError.server(message: "SSO requires a @vt.edu email.")
        }
        return try await login(email: email, password: nil)
    }

    func submitConsent(session: AuthSession) async throws {
        _ = session
    }

    func activateNewUser(email: String, code: String) async throws -> AuthSession {
        guard code == "482910" else {
            throw BackendError.server(message: "Invalid activation code. Demo code is 482910.")
        }
        guard let me = database.students.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw BackendError.userNotFound
        }
        return AuthSession(userId: me.id, email: me.email, token: "local-\(me.id)")
    }

    func searchSections(query: String) async -> [CourseSection] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        return database.sections.filter { section in
            section.courseCode.lowercased().contains(trimmed)
                || section.courseName.lowercased().contains(trimmed)
                || section.sectionId.lowercased().contains(trimmed)
                || section.sectionLabel.lowercased().contains(trimmed)
        }
        .sorted { $0.courseCode < $1.courseCode }
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

    func setActivityMode(session: AuthSession, mode: ActivityMode) async throws {
        let expires = Date().addingTimeInterval(mode.defaultDuration)
        activeModeByStudentId[session.userId] = (mode, expires)
        try await setPresence(
            session: session,
            status: mode.presenceStatus,
            activity: mode.label
        )
    }

    func fetchEvents(session: AuthSession) async throws -> EventsData {
        try eventsData(for: session.userId)
    }

    func markEventInterested(session: AuthSession, eventId: String) async throws {
        guard database.students.contains(where: { $0.id == session.userId }),
              database.campusEvents.contains(where: { $0.id == eventId }) else {
            throw BackendError.invalidRequest
        }
        eventParticipations.removeAll { $0.eventId == eventId && $0.studentId == session.userId }
        eventParticipations.append(
            EventParticipation(eventId: eventId, studentId: session.userId, kind: .interested)
        )
    }

    func markLookingForPartner(session: AuthSession, eventId: String, note: String, experience: String) async throws {
        guard let me = database.students.first(where: { $0.id == session.userId }),
              let event = database.campusEvents.first(where: { $0.id == eventId }),
              event.matchingKind != .none else {
            throw BackendError.invalidRequest
        }
        eventParticipations.removeAll { $0.eventId == eventId && $0.studentId == session.userId }
        eventParticipations.append(
            EventParticipation(eventId: eventId, studentId: session.userId, kind: .lookingForPartner)
        )
        partnerProfiles.removeAll { $0.eventId == eventId && $0.studentId == session.userId }
        partnerProfiles.append(
            PartnerSeekingProfile(
                studentId: session.userId,
                eventId: eventId,
                displayName: me.name.components(separatedBy: " ").first ?? me.name,
                year: me.year,
                experienceNote: experience,
                lookingNote: note,
                socialHandle: nil
            )
        )
    }

    func updateInterests(session: AuthSession, interestIds: [String]) async throws {
        if let idx = studentProfiles.firstIndex(where: { $0.studentId == session.userId }) {
            studentProfiles[idx].interestIds = interestIds
            studentProfiles[idx].onboardingComplete = true
        } else {
            studentProfiles.append(
                StudentProfile(studentId: session.userId, interestIds: interestIds, onboardingComplete: true)
            )
        }
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

    private func eventsData(for studentId: String) throws -> EventsData {
        guard database.students.contains(where: { $0.id == studentId }) else {
            throw BackendError.userNotFound
        }
        let profile = studentProfiles.first(where: { $0.studentId == studentId })
        let modeEntry = activeModeByStudentId[studentId]
        let schoolEvents = database.campusEvents.filter { $0.schoolId == profileSchoolId(for: studentId) }
        let schoolInterests = database.interests.filter { $0.schoolId == profileSchoolId(for: studentId) }

        return EventsBuilder.build(
            events: schoolEvents,
            interests: schoolInterests,
            participations: eventParticipations,
            partnerProfiles: partnerProfiles,
            students: database.students,
            viewerId: studentId,
            myInterestIds: profile?.interestIds ?? [],
            activeMode: modeEntry?.mode,
            modeExpiresAt: modeEntry?.expiresAt,
            onboardingComplete: profile?.onboardingComplete ?? false
        )
    }

    private func profileSchoolId(for studentId: String) -> String {
        database.students.first(where: { $0.id == studentId })?.schoolId ?? "vt"
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
