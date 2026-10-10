import SwiftUI

/// Messages tab - friends, requests, and people you may know.
struct MessagesTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var settingsFriend: FriendCard?
    @State private var showNotifications = false

    private var filteredFriends: [FriendCard] {
        guard !searchText.isEmpty else { return viewModel.nearbyFriends }
        return viewModel.nearbyFriends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.notificationCount > 0 {
                        requestsBanner
                    }
                    friendsSection
                    if !viewModel.suggested.isEmpty {
                        suggestionsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(SparqTheme.screenBackground(colorScheme))
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search friends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNotifications = true } label: {
                        Image(systemName: "bell")
                    }
                }
            }
        }
        .sheet(item: $settingsFriend) { friend in
            FriendSettingsSheet(friend: friend, preferences: viewModel.preferences)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet()
        }
    }

    private var requestsBanner: some View {
        Button { showNotifications = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundStyle(SparqTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.notificationCount) friend request\(viewModel.notificationCount == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Tap to review")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(SparqTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friends")
                .font(.headline.weight(.semibold))

            if filteredFriends.isEmpty {
                Text("No friends match your search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredFriends.enumerated()), id: \.element.id) { index, friend in
                        friendRow(friend)
                        if index < filteredFriends.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(SparqTheme.surface(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous))
            }
        }
    }

    private func friendRow(_ friend: FriendCard) -> some View {
        Button { settingsFriend = friend } label: {
            HStack(spacing: 12) {
                FriendAvatarView(
                    name: friend.name,
                    friendId: friend.id,
                    size: 44,
                    showsFreeRing: friend.status == .freeNow
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text(FriendColorPalette.firstName(friend.name))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(friend.activity.isEmpty ? friend.status.studentFacingDetail : friend.activity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if viewModel.preferences.isStarred(friend.id) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(SparqTheme.accentSecondary)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("People you may know")
                .font(.headline.weight(.semibold))

            VStack(spacing: 0) {
                ForEach(Array(viewModel.suggested.prefix(6).enumerated()), id: \.element.id) { index, student in
                    suggestionRow(student)
                    if index < min(5, viewModel.suggested.count - 1) {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(SparqTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous))
        }
    }

    private func suggestionRow(_ student: Student) -> some View {
        HStack(spacing: 12) {
            FriendAvatarView(name: student.name, friendId: student.id, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.subheadline.weight(.semibold))
                if let via = student.suggestedVia, via == "contacts" {
                    Text("From your contacts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                Task { await viewModel.sendFriendRequest(to: student) }
            } label: {
                Text("Add")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
            .tint(SparqTheme.accent)
        }
        .padding(14)
    }
}
