import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var settingsFriend: FriendCard?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Friends")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    InfoTipButton(
                        title: "Friends",
                        message: "Star your close friends to highlight them on Today. Friend suggestions from contacts and social apps will match by phone or username within your school — coming soon."
                    )
                }
                .padding(.top, 84)

                if !viewModel.pendingIncoming.isEmpty {
                    requestsSection
                }

                if !viewModel.classConnections.isEmpty {
                    classSection
                }

                friendsSection
                suggestionsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(item: $settingsFriend) { friend in
            FriendSettingsSheet(friend: friend, preferences: viewModel.preferences)
        }
    }

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requests")
                .font(.headline)
            ForEach(viewModel.pendingIncoming) { request in
                HStack {
                    Text(request.from.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button("Accept") {
                        Task { await viewModel.acceptRequest(request) }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: 44)
                }
            }
        }
        .glassCard()
    }

    private var classSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("In your classes")
                .font(.headline)
            ForEach(viewModel.classConnections.prefix(6)) { connection in
                HStack {
                    Circle()
                        .fill(connection.kind.color)
                        .frame(width: 8, height: 8)
                    Text("\(connection.friendName.components(separatedBy: " ").first ?? connection.friendName) · \(connection.courseCode)")
                        .font(.subheadline)
                    Spacer()
                    Text(connection.kind.shortLabel)
                        .font(.caption)
                        .foregroundStyle(connection.kind.color)
                }
            }
        }
        .glassCard()
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your friends")
                .font(.headline)
            ForEach(viewModel.nearbyFriends) { friend in
                HStack(spacing: 10) {
                    Circle()
                        .fill(FriendColorPalette.color(for: friend.id).opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(Text(friend.avatarEmoji))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.name)
                            .font(.subheadline.weight(.semibold))
                        Text(friend.status.label)
                            .font(.caption)
                            .foregroundStyle(friend.status.color)
                    }
                    Spacer()
                    Button {
                        viewModel.toggleStar(friend)
                    } label: {
                        Image(systemName: viewModel.preferences.isStarred(friend.id) ? "star.fill" : "star")
                            .foregroundStyle(viewModel.preferences.isStarred(friend.id) ? BetweenTheme.neonAmber : .secondary)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel(viewModel.preferences.isStarred(friend.id) ? "Unstar \(friend.name)" : "Star \(friend.name)")

                    Button {
                        settingsFriend = friend
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Settings for \(friend.name)")
                }
            }
        }
        .glassCard()
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Suggested")
                    .font(.headline)
                Spacer()
                if !viewModel.contactSuggestions.isEmpty {
                    Text("From contacts")
                        .font(.caption2)
                        .foregroundStyle(BetweenTheme.neonMint)
                }
            }
            ForEach(viewModel.suggested.prefix(8), id: \.id) { student in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(student.name)
                            .font(.subheadline)
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
                    .frame(minHeight: 44)
                }
            }
        }
        .glassCard()
    }
}

#Preview {
    FriendsListView()
        .environmentObject(AppViewModel.make())
}
