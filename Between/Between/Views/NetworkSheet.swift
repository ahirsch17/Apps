import SwiftUI

struct NetworkSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var settingsFriend: FriendCard?
    @State private var searchText = ""

    private var filteredFriends: [FriendCard] {
        guard !searchText.isEmpty else { return viewModel.nearbyFriends }
        return viewModel.nearbyFriends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.nearbyFriends.isEmpty {
                    Section {
                        ForEach(filteredFriends) { friend in
                            friendRow(friend)
                        }
                    } header: {
                        Text("\(viewModel.nearbyFriends.count) friends")
                    }
                }

                if !viewModel.suggested.isEmpty {
                    Section("People you may know") {
                        ForEach(viewModel.suggested.prefix(8), id: \.id) { student in
                            suggestionRow(student)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(item: $settingsFriend) { friend in
            FriendSettingsSheet(friend: friend, preferences: viewModel.preferences)
        }
    }

    private func friendRow(_ friend: FriendCard) -> some View {
        HStack(spacing: 12) {
            FriendAvatarView(
                name: friend.name,
                friendId: friend.id,
                size: 44,
                showsFreeRing: friend.status == .freeNow
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(BetweenFont.secondary().weight(.medium))
                Text(friendSubtitle(friend))
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            StatusPill(status: friend.status, compact: true)

            Button {
                viewModel.toggleStar(friend)
            } label: {
                Image(systemName: viewModel.preferences.isStarred(friend.id) ? "star.fill" : "star")
                    .foregroundStyle(viewModel.preferences.isStarred(friend.id) ? BetweenTheme.accentSecondary : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private func suggestionRow(_ student: Student) -> some View {
        HStack(spacing: 12) {
            FriendAvatarView(name: student.name, friendId: student.id, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(BetweenFont.secondary())
                Text(student.major)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
                if student.suggestedVia == "contacts" {
                    Text("From your contacts")
                        .font(.caption2)
                        .foregroundStyle(BetweenTheme.accent)
                }
            }
            Spacer()
            Button("Add") {
                Task { await viewModel.sendFriendRequest(to: student) }
            }
            .font(BetweenFont.captionMedium())
            .buttonStyle(.borderedProminent)
            .tint(BetweenTheme.accent)
        }
    }

    private func friendSubtitle(_ friend: FriendCard) -> String {
        switch friend.status {
        case .freeNow:
            return friend.location.isEmpty ? "Free on campus" : friend.location
        case .onTheWay:
            return friend.activity.isEmpty ? "Heading somewhere" : friend.activity
        case .studying:
            return friend.location.isEmpty ? "Studying" : "At \(friend.location)"
        case .busy:
            return friend.activity.isEmpty ? "In class" : friend.activity
        }
    }
}
