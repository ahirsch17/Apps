import SwiftUI

/// Home — center page is the overlap board; swipe for campus events or later today.
struct TodayView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var homePage = 1
    @State private var showNetwork = false
    @State private var showEvents = false
    @State private var showFreeNow = false
    @State private var showLaterToday = false
    @State private var showStatusSheet = false
    @State private var selectedEvent: CampusEventCard?

    private var snapshot: TodayPresenter.Snapshot { viewModel.today }

    private var laterMeetups: [TodayPresenter.MeetupWindow] {
        snapshot.meetups.filter { !$0.friendNames.isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pageHint
                TabView(selection: $homePage) {
                    campusPage.tag(0)
                    overlapPage.tag(1)
                    laterPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .background(BetweenTheme.screenBackground(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) { statusDock }
        }
        .sheet(isPresented: $showEvents) { EventsSheet() }
        .sheet(isPresented: $showNetwork) { NetworkSheet() }
        .sheet(isPresented: $showFreeNow) { FreeNowSheet(friends: snapshot.friendsFreeNow) }
        .sheet(isPresented: $showLaterToday) { LaterTodaySheet(meetups: laterMeetups) }
        .sheet(isPresented: $showStatusSheet) { StatusSheet() }
        .sheet(item: $selectedEvent) { event in EventDetailSheet(event: event) }
    }

    // MARK: - Pages

    private var pageHint: some View {
        Text(pageHintText)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.bottom, 2)
            .accessibilityHidden(true)
    }

    private var pageHintText: String {
        switch homePage {
        case 0: return "Campus"
        case 1: return "Today"
        case 2: return "Later"
        default: return ""
        }
    }

    private var overlapPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerStrip
                DayOverlapBoardView(
                    todayPlan: viewModel.todayPlan,
                    starredIds: viewModel.preferences.starredFriendIds
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.refresh()
            await viewModel.loadEvents()
        }
    }

    private var laterPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Later today")
                    .font(.title2.weight(.bold))
                Text("People and windows when you're both free.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !snapshot.friendsFreeNow.isEmpty {
                    freeNowSection
                }

                if laterMeetups.isEmpty {
                    ContentUnavailableView(
                        "Nothing queued yet",
                        systemImage: "clock",
                        description: Text("Overlap windows will show up here as your day unfolds.")
                    )
                    .padding(.top, 24)
                } else {
                    VStack(spacing: 8) {
                        ForEach(laterMeetups) { meetup in
                            Button { showLaterToday = true } label: {
                                meetupRow(meetup)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var campusPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("On campus")
                    .font(.title2.weight(.bold))
                Text("Events matched to your interests.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                let campusEvents = viewModel.featuredEvents()
                if campusEvents.isEmpty {
                    ContentUnavailableView(
                        "No events right now",
                        systemImage: "calendar",
                        description: Text("Pull to refresh or check the full calendar.")
                    )
                    .padding(.top, 24)
                } else {
                    VStack(spacing: 8) {
                        ForEach(campusEvents) { event in
                            Button { selectedEvent = event } label: {
                                campusRow(event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button { showEvents = true } label: {
                    Label("Full calendar", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Header

    private var headerStrip: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                Text(BackendConfiguration.formattedToday())
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

    private var freeNowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Free now")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(snapshot.friendsFreeNow.prefix(8)) { friend in
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

    private var statusDock: some View {
        BoardStatusDock {
            Button { showStatusSheet = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "figure.wave")
                        .font(.body.weight(.semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your status")
                            .font(.subheadline.weight(.semibold))
                        Text("Tap to set activity or “available to hang”")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            BetweenMark(size: .compact)
                .accessibilityLabel("Between")
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                Button { showEvents = true } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Campus events")

                Button { showNetwork = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "person.2.fill")
                        if viewModel.notificationCount > 0 {
                            Text("\(min(viewModel.notificationCount, 9))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(Circle().fill(BetweenTheme.accentAction))
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .accessibilityLabel("Friends")
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

private struct StatusSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ActivityModeBar(showsHeader: true)
                Button {
                    Task {
                        await viewModel.setActivityMode(.social)
                        dismiss()
                    }
                } label: {
                    Label("Available to hang", systemImage: "hand.wave.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(BetweenTheme.accentAction)
                Spacer()
            }
            .padding(20)
            .navigationTitle("Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

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
