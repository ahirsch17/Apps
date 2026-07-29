import SwiftUI

struct NotificationsSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.pendingIncoming.isEmpty {
                        ContentUnavailableView(
                            "All caught up",
                            systemImage: "bell.slash",
                            description: Text("No pending friend requests")
                        )
                    } else {
                        ForEach(viewModel.pendingIncoming) { request in
                            HStack(spacing: 12) {
                                FriendAvatarView(name: request.from.name, friendId: request.from.id, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(request.from.name)
                                        .font(BetweenFont.secondary().weight(.medium))
                                    Text("Wants to connect on Between")
                                        .font(BetweenFont.caption())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Accept") {
                                    Task { await viewModel.acceptRequest(request) }
                                }
                                .font(BetweenFont.captionMedium())
                                .buttonStyle(.borderedProminent)
                                .tint(BetweenTheme.accent)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Friend requests")
                }

                if !viewModel.pendingOutgoing.isEmpty {
                    Section("Waiting on them") {
                        ForEach(viewModel.pendingOutgoing, id: \.id) { student in
                            HStack(spacing: 12) {
                                FriendAvatarView(name: student.name, friendId: student.id, size: 36)
                                Text(student.name)
                                    .font(BetweenFont.secondary())
                                Spacer()
                                Text("Pending")
                                    .font(BetweenFont.caption())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
