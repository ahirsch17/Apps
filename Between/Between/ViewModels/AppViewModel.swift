import Foundation
import SwiftUI
import Combine

enum AuthStep {
    case welcome
    case newUser
    case sso
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var authStep: AuthStep = .welcome
    @Published var loginEmail: String = ""
    @Published var activationCode: String = ""
    @Published var candidates: [Student] = []
    @Published var dashboard: DashboardData?
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var lastSyncText = "Not synced"
    @Published var courseSearchQuery: String = ""
    @Published var courseSearchResults: [CourseSection] = []
    @Published var eventsData: EventsData?
    @Published var showOnboarding = false
    @Published var needsConsent = false
    @Published private(set) var hashBasedClassConnections: [ClassConnection] = []

    let preferences = FriendPreferencesStore()

    private let service: any BetweenBackendServicing
    private var session: AuthSession?
    private var streamTask: Task<Void, Never>?
    private var preferenceCancellable: AnyCancellable?
    private var searchTask: Task<Void, Never>?

    private static let consentKey = "between.consent.accepted"

    init(service: any BetweenBackendServicing) {
        self.service = service
        preferenceCancellable = preferences.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        preferences.onSharePreferenceChanged = { [weak self] friendId, allowed in
            Task { await self?.syncShareFreeTime(friendId: friendId, allowed: allowed) }
        }
    }

    static func make() -> AppViewModel {
        do {
            return AppViewModel(service: try BackendServiceFactory.make())
        } catch {
            fatalError("Failed to create backend service: \(error)")
        }
    }

    var me: Student? { dashboard?.me }
    var nearbyFriends: [FriendCard] { dashboard?.nearbyFriends ?? [] }
    var classConnections: [ClassConnection] {
        hashBasedClassConnections.isEmpty
            ? (dashboard?.classConnections ?? [])
            : hashBasedClassConnections
    }
    var mySections: [CourseSection] { dashboard?.mySections ?? [] }
    var pendingIncoming: [IncomingFriendRequest] { dashboard?.pendingIncoming ?? [] }
    var pendingOutgoing: [Student] { dashboard?.pendingOutgoing ?? [] }
    var suggested: [Student] { dashboard?.suggestedStudents ?? [] }
    var todayPlan: [TodayPlanItem] { dashboard?.todayPlan ?? [] }

    var today: TodayPresenter.Snapshot {
        TodayPresenter.build(
            plan: todayPlan,
            friends: nearbyFriends,
            starredIds: preferences.starredFriendIds
        )
    }
    
    var recurringWindows: [RecurringWindow] {
        SchedulePatternDetector.detectRecurringWindows(
            from: todayPlan,
            starredIds: preferences.starredFriendIds
        )
    }

    var notificationCount: Int {
        pendingIncoming.count
    }

    var starredFriends: [FriendCard] {
        nearbyFriends.filter { preferences.isStarred($0.id) }
    }

    var contactSuggestions: [Student] {
        suggested.filter { $0.suggestedVia == "contacts" }
    }

    func bootstrap() async {
        candidates = await service.fetchLoginCandidates()
        if loginEmail.isEmpty {
            loginEmail = candidates.first(where: { $0.email == "alex.hirsch@vt.edu" })?.email
                ?? candidates.first?.email
                ?? ""
        }
    }

    func loginWithSSO() async {
        guard loginEmail.lowercased().hasSuffix("@vt.edu") else {
            errorMessage = "Sign in requires a @vt.edu email address."
            return
        }
        guard !loginEmail.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let auth = try await service.loginWithSSO(email: loginEmail)
            try await completeSignIn(auth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptConsent() async {
        guard let session, let me = dashboard?.me else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.submitConsent(session: session)
            let consentKey = "\(Self.consentKey).\(me.id)"
            UserDefaults.standard.set(true, forKey: consentKey)
            needsConsent = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func activateNewUser() async {
        guard loginEmail.lowercased().hasSuffix("@vt.edu") else {
            errorMessage = "Activation requires a @vt.edu email address."
            return
        }
        guard !loginEmail.isEmpty, activationCode.count >= 6 else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let auth = try await service.activateNewUser(email: loginEmail, code: activationCode)
            try await completeSignIn(auth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard let session else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let data = try await service.refreshDashboard(session: session)
            applyDashboard(data)
        preferences.bind(userId: data.me.id, friendIds: data.nearbyFriends.map(\.id))
        preferences.applyServerSharePrefs(data.shareFreeTimeWith)
        await syncCourseHashes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchCourses() {
        searchTask?.cancel()
        let query = courseSearchQuery
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            courseSearchResults = await service.searchSections(query: query)
        }
    }

    func connections(for section: CourseSection) -> [ClassConnection] {
        classConnections.filter { $0.courseCode == section.courseCode }
    }

    func toggleStar(_ friend: FriendCard) {
        preferences.toggleStar(friend.id)
        let name = friend.name.components(separatedBy: " ").first ?? friend.name
        showToast(preferences.isStarred(friend.id) ? "Starred \(name)" : "Unstarred \(name)")
    }

    func sendFriendRequest(to student: Student) async {
        guard let session else { return }
        do {
            try await service.sendFriendRequest(session: session, to: student.id)
            showToast("Request sent")
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(_ request: IncomingFriendRequest) async {
        guard let session else { return }
        do {
            try await service.acceptFriendRequest(session: session, requestId: request.requestId)
            showToast("Added \(request.from.name.components(separatedBy: " ").first ?? request.from.name)")
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markFreeNow() async {
        await setActivityMode(.social)
    }

    func setActivityMode(_ mode: ActivityMode) async {
        guard let session else { return }
        do {
            try await service.setActivityMode(session: session, mode: mode)
            showToast(mode.encouragement)
            await loadEvents()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadEvents() async {
        guard let session else { return }
        do {
            eventsData = try await service.fetchEvents(session: session)
            showOnboarding = !(eventsData?.onboardingComplete ?? false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeOnboarding(selected interestIds: [String]) async {
        guard let session else { return }
        do {
            try await service.updateInterests(session: session, interestIds: interestIds)
            showOnboarding = false
            await loadEvents()
            showToast("You're set. We'll show matching events")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markInterested(_ event: CampusEventCard) async {
        guard let session else { return }
        do {
            try await service.markEventInterested(session: session, eventId: event.id)
            showToast("You're on the list")
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markLookingForPartner(_ event: CampusEventCard, note: String, experience: String) async {
        guard let session else { return }
        do {
            try await service.markLookingForPartner(
                session: session, eventId: event.id, note: note, experience: experience
            )
            showToast("Partner profile live — others can find you")
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isEventForMyInterests(_ event: CampusEventCard) -> Bool {
        guard let data = eventsData else { return false }
        guard let interest = data.interests.first(where: { $0.name == event.interestName }) else { return false }
        return data.myInterestIds.contains(interest.id)
    }

    func featuredEvent() -> CampusEventCard? {
        featuredEvents(limit: 1).first
    }

    /// Events surfaced on the home screen: prioritize the ones matching my
    /// interests, then fall back to any events so the section isn't empty.
    func featuredEvents(limit: Int = 3) -> [CampusEventCard] {
        guard let data = eventsData else { return [] }
        let forMe = data.events.filter { isEventForMyInterests($0) }
        let base = forMe.isEmpty ? data.events : forMe
        return Array(base.prefix(limit))
    }
    
    func spontaneousPlanSuggestion() -> SpontaneousPlan? {
        let freeNow = nearbyFriends.filter { $0.status == .freeNow }
        guard let nearestFriend = freeNow.first(where: { preferences.isStarred($0.id) }) else { return nil }
        
        let firstName = nearestFriend.name.components(separatedBy: " ").first ?? nearestFriend.name
        let place = nearestFriend.location.isEmpty ? "on campus" : nearestFriend.location
        
        return SpontaneousPlan(
            id: nearestFriend.id,
            title: "\(firstName) is at \(place)",
            subtitle: "Free right now",
            friendId: nearestFriend.id,
            icon: "location.fill"
        )
    }
    
    func acceptSpontaneousPlan(_ plan: SpontaneousPlan) async {
        showToast("Great! We'll let \(plan.title.components(separatedBy: " ").dropFirst().first ?? "them") know")
        await setActivityMode(.social)
    }
    
    func dismissSpontaneousPlan(_ plan: SpontaneousPlan) {
        showToast("Got it")
    }

    func signOut() {
        session = nil
        dashboard = nil
        hashBasedClassConnections = []
        needsConsent = false
        streamTask?.cancel()
        authStep = .welcome
        activationCode = ""
        errorMessage = nil
    }

    private func completeSignIn(_ auth: AuthSession) async throws {
        session = auth
        let data = try await service.refreshDashboard(session: auth)
        applyDashboard(data)
        preferences.bind(userId: data.me.id, friendIds: data.nearbyFriends.map(\.id))
        preferences.applyServerSharePrefs(data.shareFreeTimeWith)
        autoSuggestStars(from: data)
        await syncCourseHashes()
        listenForPresence()
        await loadEvents()
        let consentKey = "\(Self.consentKey).\(data.me.id)"
        needsConsent = !UserDefaults.standard.bool(forKey: consentKey)
        authStep = .welcome
    }

    private func autoSuggestStars(from data: DashboardData) {
        let overlapIds = Set(data.todayPlan.flatMap(\.friendOverlaps).map(\.friendId))
        guard preferences.starredFriendIds.isEmpty else { return }
        preferences.ensureDemoStars(
            friendIds: data.nearbyFriends.map(\.id),
            overlapFriendIds: overlapIds
        )
    }

    private func applyDashboard(_ data: DashboardData) {
        dashboard = data
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        lastSyncText = "Updated \(formatter.localizedString(for: data.syncTimestamp, relativeTo: Date()))"
    }

    private func syncShareFreeTime(friendId: String, allowed: Bool) async {
        guard let session else { return }
        do {
            try await service.updateShareFreeTime(session: session, friendId: friendId, allowed: allowed)
            let name = nearbyFriends.first(where: { $0.id == friendId })?.name
                .components(separatedBy: " ").first ?? "Friend"
            showToast(allowed ? "Sharing overlap with \(name)" : "Overlap hidden from \(name)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncCourseHashes() async {
        guard let session, let me = dashboard?.me else { return }
        let hashes = CourseHashService.hashSections(mySections, schoolId: me.schoolId)
        guard !hashes.isEmpty else { return }
        do {
            let result = try await service.uploadCourseHashes(session: session, hashes: hashes)
            hashBasedClassConnections = result.matches.flatMap(\.friendConnections)
        } catch {
            // Non-fatal: fall back to dashboard.classConnections
        }
    }

    func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    private func listenForPresence() {
        streamTask?.cancel()
        guard let session else { return }
        streamTask = Task {
            let stream = await service.connectPresenceStream(session: session)
            for await updatedPresence in stream {
                await updatePresence(updatedPresence)
            }
        }
    }
    
    private func updatePresence(_ presence: PresenceRecord) {
        guard var dashboard = dashboard else { return }
        if let idx = dashboard.nearbyFriends.firstIndex(where: { $0.id == presence.studentId }) {
            dashboard.nearbyFriends[idx] = FriendCard(
                id: dashboard.nearbyFriends[idx].id,
                name: dashboard.nearbyFriends[idx].name,
                email: dashboard.nearbyFriends[idx].email,
                avatarEmoji: dashboard.nearbyFriends[idx].avatarEmoji,
                status: presence.status,
                activity: presence.activity,
                location: presence.location,
                distanceLabel: dashboard.nearbyFriends[idx].distanceLabel
            )
            self.dashboard = dashboard
        }
    }
}
