import Foundation
import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var candidates: [Student] = []
    @Published var dashboard: DashboardData?
    @Published var selectedEmail: String = ""
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var lastSyncText = "Not synced"
    @Published var selectedTab = 1

    let preferences = FriendPreferencesStore()

    private let service: any BetweenBackendServicing
    private var session: AuthSession?
    private var streamTask: Task<Void, Never>?
    private var preferenceCancellable: AnyCancellable?

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
    var mySections: [Section] { dashboard?.mySections ?? [] }
    var pendingIncoming: [IncomingFriendRequest] { dashboard?.pendingIncoming ?? [] }
    var pendingOutgoing: [Student] { dashboard?.pendingOutgoing ?? [] }
    var suggested: [Student] { dashboard?.suggestedStudents ?? [] }
    var plans: [Plan] { dashboard?.plans ?? [] }
    var todayPlan: [TodayPlanItem] { dashboard?.todayPlan ?? [] }

    var starredFriends: [FriendCard] {
        nearbyFriends.filter { preferences.isStarred($0.id) }
    }

    var freeNowCount: Int {
        nearbyFriends.filter { $0.status == .freeNow }.count
    }

    var contactSuggestions: [Student] {
        suggested.filter { $0.suggestedVia == "contacts" }
    }

    func bootstrap() async {
        candidates = await service.fetchLoginCandidates()
        if selectedEmail.isEmpty {
            selectedEmail = candidates.first(where: { $0.email == "alex.hirsch@vt.edu" })?.email
                ?? candidates.first?.email
                ?? ""
        }
    }

    func login() async {
        guard !selectedEmail.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let auth = try await service.login(email: selectedEmail, password: nil)
            session = auth
            let data = try await service.refreshDashboard(session: auth)
            applyDashboard(data)
            preferences.bind(userId: data.me.id, friendIds: data.nearbyFriends.map(\.id))
            autoSuggestStars(from: data)
            listenForPresence()
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

    func joinFriend(_ friend: FriendCard) async {
        selectedTab = 2
        showToast("Plan with \(friend.name.components(separatedBy: " ").first ?? friend.name)")
    }

    func nudge(friend: FriendCard) async {
        guard let session else { return }
        do {
            try await service.sendNudge(session: session, to: friend.id, message: "Hey")
            showToast("Nudged \(friend.name.components(separatedBy: " ").first ?? friend.name)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func nudge(connection: ClassConnection) async {
        if let friend = nearbyFriends.first(where: { $0.name == connection.friendName }) {
            await nudge(friend: friend)
        }
    }

    func planWith(friend: FriendCard) async {
        guard let session else { return }
        do {
            _ = try await service.createPlan(
                session: session,
                type: "hangout",
                title: "Meet \(friend.name.components(separatedBy: " ").first ?? friend.name)",
                location: friend.location
            )
            selectedTab = 2
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createQuickPlan(type: String, title: String, location: String) async {
        guard let session else { return }
        do {
            _ = try await service.createPlan(session: session, type: type, title: title, location: location)
            showToast("\(title) created")
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func autoSuggestStars(from data: DashboardData) {
        let allOverlaps = data.todayPlan.flatMap(\.friendOverlaps)
        preferences.suggestStars(from: allOverlaps, limit: 5)
        // Ensure demo anchors John + Rachel stay starred when present.
        for friendId in ["stu-john", "stu-rachel"] {
            if data.nearbyFriends.contains(where: { $0.id == friendId }) {
                if !preferences.isStarred(friendId) {
                    preferences.toggleStar(friendId)
                }
            }
        }
    }

    private func applyDashboard(_ data: DashboardData) {
        dashboard = data
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        lastSyncText = "Synced \(formatter.localizedString(for: data.syncTimestamp, relativeTo: Date()))"
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
