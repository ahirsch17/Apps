import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showNetwork = false
    @State private var showNotifications = false
    @State private var showCourseLookup = false
    @State private var classSheetSection: CourseSection?

    private var snapshot: TodayPresenter.Snapshot { viewModel.today }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(BetweenTheme.screenBackground(colorScheme))

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingHeader

                    if let headline = snapshot.headline {
                        headlineCard(headline)
                    }

                    if !snapshot.friendsFreeNow.isEmpty {
                        friendsFreeNowSection
                    }

                    if let next = snapshot.nextClass {
                        nextClassCard(next)
                    }

                    if !snapshot.meetups.isEmpty {
                        meetupsSection
                    }

                    DayTimelineView(
                        entries: snapshot.timeline,
                        onClassFriendsTap: { classSheetSection = $0 }
                    )

                    Button {
                        Task { await viewModel.markFreeNow() }
                    } label: {
                        Label("Tap if you're free", systemImage: "hand.wave.fill")
                    }
                    .buttonStyle(BetweenPrimaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
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

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let first = viewModel.me?.name.components(separatedBy: " ").first {
                Text("Hey, \(first)")
                    .font(BetweenFont.greeting())
            }
            Text("\(BackendConfiguration.demoWeekdayName()) · \(viewModel.nearbyFriends.count) friends on Between")
                .font(BetweenFont.secondary())
                .foregroundStyle(.secondary)
        }
    }

    private var topBar: some View {
        HStack {
            ToolbarIconButton(systemName: "magnifyingglass", action: { showCourseLookup = true })
            Spacer()
            ToolbarIconButton(systemName: "bell.fill", badge: viewModel.notificationCount, action: { showNotifications = true })
            ToolbarIconButton(systemName: "person.2.fill", action: { showNetwork = true })
        }
    }

    private func headlineCard(_ headline: TodayPresenter.Headline) -> some View {
        HStack(alignment: .top, spacing: 14) {
            if let name = headline.friendName, let id = headline.friendId {
                FriendAvatarView(name: name, friendId: id, size: 56, showsFreeRing: true)
            } else {
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundStyle(BetweenTheme.accent)
                    .frame(width: 56, height: 56)
                    .background(BetweenTheme.accentSoft)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(headline.title)
                    .font(BetweenFont.cardTitle())
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle = headline.subtitle {
                    Text(subtitle)
                        .font(BetweenFont.secondary())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private var friendsFreeNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Free right now", subtitle: "On campus")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(snapshot.friendsFreeNow) { friend in
                        freeNowChip(friend)
                    }
                }
            }
        }
    }

    private func freeNowChip(_ friend: FriendCard) -> some View {
        VStack(spacing: 8) {
            FriendAvatarView(
                name: friend.name,
                friendId: friend.id,
                size: 52,
                showsFreeRing: true
            )
            Text(FriendColorPalette.firstName(friend.name))
                .font(BetweenFont.captionMedium())
            Text(friend.location)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 88)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(BetweenTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: BetweenTheme.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, y: 2)
    }

    private func nextClassCard(_ next: TodayPresenter.NextClass) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Next class")
                    .font(BetweenFont.captionMedium())
                    .foregroundStyle(.secondary)
                Text(next.courseCode)
                    .font(BetweenFont.cardTitle())
                Text(next.timeLabel)
                    .font(BetweenFont.secondary())
                Text(next.location)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
                if let startsIn = next.startsInLabel {
                    Text(startsIn)
                        .font(BetweenFont.captionMedium())
                        .foregroundStyle(BetweenTheme.accent)
                }
            }
            Spacer()
            Button {
                classSheetSection = next.section
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.body)
                    Text("Classmates")
                        .font(.caption2)
                }
                .foregroundStyle(BetweenTheme.accent)
                .frame(width: 72, height: 72)
                .background(BetweenTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .surfaceCard()
    }

    private var meetupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Find time together", subtitle: "Shared free windows today")

            ForEach(snapshot.meetups.prefix(3)) { meetup in
                HStack(spacing: 14) {
                    Image(systemName: meetup.icon)
                        .font(.title3)
                        .foregroundStyle(BetweenTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(BetweenTheme.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(meetup.contextLabel)
                            .font(BetweenFont.captionMedium())
                            .foregroundStyle(BetweenTheme.accent)
                        Text(meetup.timeLabel)
                            .font(BetweenFont.cardTitle())
                        Text("With \(meetup.namesLine)")
                            .font(BetweenFont.secondary())
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    friendAvatarStack(meetup.friendIds, names: meetup.friendNames)
                }
                .surfaceCard()
            }
        }
    }

    private func friendAvatarStack(_ ids: [String], names: [String]) -> some View {
        HStack(spacing: -8) {
            ForEach(Array(zip(ids, names).prefix(3)), id: \.0) { id, name in
                FriendAvatarView(name: name, friendId: id, size: 30)
                    .overlay(Circle().stroke(BetweenTheme.surface(colorScheme), lineWidth: 2))
            }
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppViewModel.make())
}
