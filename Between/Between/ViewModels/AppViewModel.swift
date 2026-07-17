import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var candidates: [Student] = []
    @Published var dashboard: DashboardData?
    @Published var selectedEmail: String = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var lastSyncText = "Not synced"

    private let service: BetweenBackendServicing
    private var streamTask: Task<Void, Never>?

    init(service: BetweenBackendServicing) {
        self.service = service
    }

    var me: Student? { dashboard?.me }
    var nearbyFriends: [FriendCard] { dashboard?.nearbyFriends ?? [] }
    var classConnections: [ClassConnection] { dashboard?.classConnections ?? [] }
    var mySections: [Section] { dashboard?.mySections ?? [] }
    var pendingIncoming: [Student] { dashboard?.pendingIncomingRequests ?? [] }
    var pendingOutgoing: [Student] { dashboard?.pendingOutgoingRequests ?? [] }
    var suggested: [Student] { dashboard?.suggestedStudents ?? [] }
    var plans: [Plan] { dashboard?.plans ?? [] }

    func bootstrap() async {
        candidates = await service.fetchLoginCandidates()
        if selectedEmail.isEmpty, let first = candidates.first {
            selectedEmail = first.email
        }
    }

    func login() async {
        guard !selectedEmail.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await service.login(email: selectedEmail)
            applyDashboard(data)
            listenForPresence()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard let me else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let data = try await service.refreshDashboard(for: me.id)
            applyDashboard(data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendFriendRequest(to student: Student) async {
        guard let me else { return }
        do {
            try await service.sendFriendRequest(from: me.id, to: student.id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(from student: Student) async {
        guard let me else { return }
        do {
            let requests = try await service.refreshDashboard(for: me.id)
            if let req = requests.pendingIncomingRequests.first(where: { $0.id == student.id }),
               let requestId = await findRequestId(from: req.id, dashboard: requests, meId: me.id) {
                try await service.acceptFriendRequest(requestId: requestId, actingUserId: me.id)
                await refresh()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyDashboard(_ data: DashboardData) {
        dashboard = data
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        lastSyncText = "Synced \(formatter.localizedString(for: data.syncTimestamp, relativeTo: Date()))"
    }

    private func listenForPresence() {
        streamTask?.cancel()
        streamTask = Task {
            let stream = await service.connectPresenceStream()
            for await _ in stream {
                await refresh()
            }
        }
    }

    private func findRequestId(from requesterId: String, dashboard: DashboardData, meId: String) async -> String? {
        // local helper: request ID is not on student objects, so re-fetch from backend via refresh and map by ids.
        // This is intentionally simple for the local pipeline simulation.
        if let backend = service as? LocalBackendServiceAccessor {
            return await backend.pendingRequestId(from: requesterId, to: meId)
        }
        return nil
    }
}

// Small accessor protocol to avoid exposing full mutable backend internals.
protocol LocalBackendServiceAccessor {
    func pendingRequestId(from: String, to: String) async -> String?
}
