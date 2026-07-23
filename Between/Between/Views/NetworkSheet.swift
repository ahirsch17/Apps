import SwiftUI

struct NetworkSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var settingsFriend: FriendCard?

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.nearbyFriends.isEmpty {
                    Section("Your friends") {
                        ForEach(viewModel.nearbyFriends) { friend in
                            friendRow(friend)
                        }
                    }
                }

                if !viewModel.suggested.isEmpty {
                    Section("Add people") {
                        ForEach(viewModel.suggested.prefix(10), id: \.id) { student in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(student.name)
                                    if student.suggestedVia == "contacts" {
                                        Text("In your contacts")
                                            .font(.caption2)
                                            .foregroundStyle(BetweenTheme.neonMint)
                                    }
                                }
                                Spacer()
                                Button("Add") {
                                    Task { await viewModel.sendFriendRequest(to: student) }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Network")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: $settingsFriend) { friend in
            FriendSettingsSheet(friend: friend, preferences: viewModel.preferences)
        }
    }

    private func friendRow(_ friend: FriendCard) -> some View {
        HStack(spacing: 10) {
            Text(friend.avatarEmoji)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.subheadline.weight(.medium))
                Text(friend.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                viewModel.toggleStar(friend)
            } label: {
                Image(systemName: viewModel.preferences.isStarred(friend.id) ? "star.fill" : "star")
                    .foregroundStyle(viewModel.preferences.isStarred(friend.id) ? BetweenTheme.neonAmber : .secondary)
            }
            .buttonStyle(.plain)
            Button {
                settingsFriend = friend
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
