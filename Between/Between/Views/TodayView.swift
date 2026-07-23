import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showNetwork = false
    @State private var showNotifications = false
    @State private var showCourseLookup = false
    @State private var classSheetSection: CourseSection?

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(BetweenTheme.screenBackground(colorScheme))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    overlapHero

                    DayTimelineView(
                        items: viewModel.todayPlan,
                        starredFriendIds: viewModel.preferences.starredFriendIds,
                        friends: viewModel.nearbyFriends,
                        onClassFriendsTap: { classSheetSection = $0 }
                    )

                    HStack {
                        Button {
                            Task { await viewModel.markFreeNow() }
                        } label: {
                            Label("I'm free", systemImage: "hand.wave")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Text(viewModel.lastSyncText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .sheet(isPresented: $showNetwork) {
            NetworkSheet()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet()
        }
        .sheet(isPresented: $showCourseLookup) {
            CourseLookupSheet()
        }
        .sheet(item: $classSheetSection) { section in
            ClassFriendsSheet(section: section)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                showCourseLookup = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.medium))
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Course lookup")

            Spacer()

            VStack(spacing: 2) {
                Text("Today")
                    .font(.headline)
                if let first = viewModel.me?.name.components(separatedBy: " ").first {
                    Text(first)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Button {
                    showNotifications = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.body.weight(.medium))
                            .frame(width: 40, height: 40)
                        if viewModel.notificationCount > 0 {
                            Text("\(viewModel.notificationCount)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 8, y: -4)
                        }
                    }
                }
                .accessibilityLabel("Notifications")

                Button {
                    showNetwork = true
                } label: {
                    Image(systemName: "person.2")
                        .font(.body.weight(.medium))
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Your network")
            }
        }
    }

    @ViewBuilder
    private var overlapHero: some View {
        if let block = viewModel.todayPlan.first(where: { !$0.starredOverlaps(starredIds: viewModel.preferences.starredFriendIds).isEmpty }),
           let overlap = block.starredOverlaps(starredIds: viewModel.preferences.starredFriendIds).first {
            VStack(alignment: .leading, spacing: 6) {
                Text("Shared free time")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text("\(overlap.longestIntervalMinutes)+ min with \(overlap.firstName())")
                    .font(.title3.weight(.bold))
                Text(block.timeRangeLabel)
                    .font(.subheadline)
                    .foregroundStyle(FriendColorPalette.color(for: overlap.friendId))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceCard()
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppViewModel.make())
}
