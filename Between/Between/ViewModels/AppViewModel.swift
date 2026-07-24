import Foundation
import SwiftUI
import Combine

enum AuthStep {
    case welcome
    case returning
    case newUser
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var authStep: AuthStep = .welcome
    @Published var loginEmail: String = ""
    @Published var loginPassword: String = ""
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

    let preferences = FriendPreferencesStore()

    private let service: any BetweenBackendServicing
    private var session: AuthSession?
    private var streamTask: Task<Void, Never>?
    private var preferenceCancellable: AnyCancellable?
    private var searchTask: Task<Void, Never>?

    init(service: any BetweenBackendServicing) {
        self.service = service
        preferenceCancellable = preferences.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
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
    var classConnections: [ClassConnection] { dashboard?.classConnections ?? [] }
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

    func loginReturning() async {
        guard !loginEmail.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let auth = try await service.login(email: loginEmail, password: loginPassword)
            try await completeSignIn(auth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func activateNewUser() async {
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
        guard let session else { return }
        do {
            try await service.setPresence(session: session, status: .freeNow, activity: "Free")
            showToast("You're marked free")
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        session = nil
        dashboard = nil
        streamTask?.cancel()
        authStep = .welcome
        loginPassword = ""
        activationCode = ""
        errorMessage = nil
    }

    private func completeSignIn(_ auth: AuthSession) async throws {
        session = auth
        let data = try await service.refreshDashboard(session: auth)
        applyDashboard(data)
        preferences.bind(userId: data.me.id, friendIds: data.nearbyFriends.map(\.id))
        autoSuggestStars(from: data)
        listenForPresence()
        authStep = .welcome
    }

    private func autoSuggestStars(from data: DashboardData) {
        #if DEBUG
        preferences.ensureDemoStars(
            friendIds: data.nearbyFriends.map(\.id),
            overlapFriendIds: Set(data.todayPlan.flatMap(\.friendOverlaps).map(\.friendId))
        )
        #else
        let allOverlaps = data.todayPlan.flatMap(\.friendOverlaps)
        preferences.suggestStars(from: allOverlaps, limit: 8)
        #endif
    }

    private func applyDashboard(_ data: DashboardData) {
        dashboard = data
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        lastSyncText = "Updated \(formatter.localizedString(for: data.syncTimestamp, relativeTo: Date()))"
    }

    private func showToast(_ message: String) {
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
            for await _ in stream {
                await refresh()
            }
        }
    }
}
