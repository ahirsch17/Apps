import SwiftUI

/// Home screen — overlap board is the centerpiece; everything else is compact context.
struct TodayView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showNetwork = false
    @State private var showEvents = false
    @State private var showFreeNow = false
    @State private var showLaterToday = false
    @State private var selectedEvent: CampusEventCard?

    private var snapshot: TodayPresenter.Snapshot { viewModel.today }

    private var laterMeetups: [TodayPresenter.MeetupWindow] {
        snapshot.meetups.filter { !$0.friendNames.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerStrip

                    DayOverlapBoardView(
                        todayPlan: viewModel.todayPlan,
                        starredIds: viewModel.preferences.starredFriendIds
                    )

                    if !snapshot.friendsFreeNow.isEmpty {
                        freeNowStrip
                    }

                    if !laterMeetups.isEmpty {
                        laterTodayStrip
                    }

                    let campusEvents = viewModel.featuredEvents()
                    if !campusEvents.isEmpty {
                        campusStrip(campusEvents)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 100)
            }
            .background(BetweenTheme.screenBackground(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) { statusDock }
            .refreshable {
                await viewModel.refresh()
                await viewModel.loadEvents()
            }
        }
        .sheet(isPresented: $showEvents) { EventsSheet() }
        .sheet(isPresented: $showNetwork) { NetworkSheet() }
        .sheet(isPresented: $showFreeNow) { FreeNowSheet(friends: snapshot.friendsFreeNow) }
        .sheet(isPresented: $showLaterToday) { LaterTodaySheet(meetups: laterMeetups) }
        .sheet(item: $selectedEvent) { event in EventDetailSheet(event: event) }
    }

    // MARK: - Header

    private var headerStrip: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                Text(BackendConfiguration.demoWeekdayName())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !snapshot.friendsFreeNow.isEmpty {
                Button { showFreeNow = true } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(BetweenTheme.free)
                            .frame(width: 8, height: 8)
                        Text("\(snapshot.friendsFreeNow.count) free")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(BetweenTheme.free.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Secondary strips

    private var freeNowStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("On campus now")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(snapshot.friendsFreeNow.prefix(6)) { friend in
                        freeNowChip(friend)
                    }
                }
            }
        }
    }

    private func freeNowChip(_ friend: FriendCard) -> some View {
        Button { showFreeNow = true } label: {
            HStack(spacing: 8) {
                FriendAvatarView(name: friend.name, friendId: friend.id, size: 32, showsFreeRing: true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(FriendColorPalette.firstName(friend.name))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !friend.location.isEmpty {
                        Text(friend.location)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BetweenTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var laterTodayStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Later today", action: laterMeetups.count > 2 ? { showLaterToday = true } : nil)

            VStack(spacing: 8) {
                ForEach(laterMeetups.prefix(2)) { meetup in
                    Button { showLaterToday = true } label: {
                        meetupRow(meetup)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func meetupRow(_ meetup: TodayPresenter.MeetupWindow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: meetup.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BetweenTheme.accent)
                .frame(width: 36, height: 36)
                .background(BetweenTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(meetup.namesLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(meetup.contextLabel) · \(meetup.timeLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(BetweenTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func campusStrip(_ events: [CampusEventCard]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "For you on campus", action: { showEvents = true })

            VStack(spacing: 8) {
                ForEach(events) { event in
                    Button { selectedEvent = event } label: {
                        campusRow(event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func campusRow(_ event: CampusEventCard) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.interestIcon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BetweenTheme.accentAction)
                .frame(width: 36, height: 36)
                .background(BetweenTheme.accentActionSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(event.timeLabel) · \(event.interestedCount) interested")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(BetweenTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sectionHeader(title: String, action: (() -> Void)?) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
            if let action {
                Button("See all", action: action)
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private var statusDock: some View {
        BoardStatusDock {
            VStack(alignment: .leading, spacing: 12) {
                ActivityModeBar(showsHeader: false)
                Button {
                    Task { await viewModel.setActivityMode(.social) }
                } label: {
                    Label("Available to hang", systemImage: "hand.wave.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(BetweenTheme.accentAction)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            BetweenBrandLockup(style: .toolbar)
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 8) {
                ToolbarIconButton(systemName: "calendar", onTap: { showEvents = true })
                ToolbarIconButton(
                    systemName: "person.2.fill",
                    badge: viewModel.notificationCount,
                    onTap: { showNetwork = true }
                )
            }
        }
    }

    private var greeting: String {
        if let first = viewModel.me?.name.components(separatedBy: " ").first {
            return "Hey, \(first)"
        }
        return "Hey"
    }
}

// MARK: - Sheets

private struct FreeNowSheet: View {
    @Environment(\.dismiss) private var dismiss
    let friends: [FriendCard]

    var body: some View {
        NavigationStack {
            List {
                ForEach(friends) { friend in
                    HStack(spacing: 12) {
                        FriendAvatarView(name: friend.name, friendId: friend.id, size: 44, showsFreeRing: true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(FriendColorPalette.firstName(friend.name))
                            if !friend.location.isEmpty {
                                Text(friend.location)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        StatusPill(status: friend.status, compact: true)
                    }
                }
            }
            .navigationTitle("Free now")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct LaterTodaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let meetups: [TodayPresenter.MeetupWindow]

    var body: some View {
        NavigationStack {
            List {
                ForEach(meetups) { meetup in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meetup.timeLabel)
                            .font(.body.weight(.semibold))
                        Text("with \(meetup.namesLine)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Later today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    TodayView()
        .environmentObject(AppViewModel.make())
}
