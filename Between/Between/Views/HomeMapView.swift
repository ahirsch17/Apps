import SwiftUI

struct HomeMapView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                hero
                DayTimelineView(
                    items: viewModel.todayPlan,
                    starredFriendIds: viewModel.preferences.starredFriendIds,
                    friends: viewModel.nearbyFriends
                )
                ClassConnectionsStrip(connections: viewModel.classConnections)
                starredRow
                freeNowRow
            }
            .padding(.top, 86)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var hero: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.me?.name.components(separatedBy: " ").first ?? "Hey")
                    .font(.largeTitle.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Text("\(viewModel.freeNowCount) free now")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BetweenTheme.neonMint)
            }
            Spacer()
            InfoTipButton(
                title: "Privacy",
                message: "Only friends see your schedule overlap — never the whole campus. Control visibility per friend. Contacts and social matching coming in a future release."
            )
        }
    }

    @ViewBuilder
    private var starredRow: some View {
        if !viewModel.starredFriends.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Close friends")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.starredFriends) { friend in
                            starredChip(friend)
                        }
                    }
                }
            }
            .glassCard()
        }
    }

    private func starredChip(_ friend: FriendCard) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(FriendColorPalette.color(for: friend.id).opacity(0.25))
                .frame(width: 48, height: 48)
                .overlay(Text(friend.avatarEmoji).font(.title3))
            Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(friend.status == .freeNow ? "Free" : friend.status.label)
                .font(.caption2)
                .foregroundStyle(friend.status.color)
        }
        .frame(width: 72)
        .accessibilityLabel("\(friend.name), \(friend.status.label)")
    }

    private var freeNowRow: some View {
        HStack {
            if let free = viewModel.nearbyFriends.first(where: { $0.status == .freeNow }) {
                HStack(spacing: 8) {
                    Circle().fill(BetweenTheme.neonMint).frame(width: 8, height: 8)
                    Text("\(free.name.components(separatedBy: " ").first ?? free.name) is free")
                        .font(.subheadline)
                }
                Spacer()
                Button("Join") {
                    Task { await viewModel.joinFriend(free) }
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
            }
            Button("I'm free") {
                Task { await viewModel.markFreeNow() }
            }
            .buttonStyle(.borderedProminent)
            .tint(BetweenTheme.neonViolet)
            .frame(minHeight: 44)
            .accessibilityLabel("Mark yourself as free")
        }
        .glassCard()
    }
}

#Preview {
    HomeMapView()
        .environmentObject(AppViewModel.make())
}
