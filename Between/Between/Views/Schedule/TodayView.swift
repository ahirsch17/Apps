import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showNetwork = false
    @State private var showEvents = false
    @State private var classSheetSection: CourseSection?
    @State private var showScheduleTimeline = false

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

                    quickActionsCard
                    
                    if let featured = viewModel.featuredEvent() {
                        featuredEventCard(featured)
                    }
                    
                    if viewModel.spontaneousPlanSuggestion() != nil {
                        spontaneousPlanCard
                    }
                    
                    scheduleSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .refreshable {
                await viewModel.refresh()
                await viewModel.loadEvents()
            }
        }
        .sheet(isPresented: $showEvents) {
            EventsSheet()
        }
        .sheet(isPresented: $showNetwork) {
            NetworkSheet()
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
            ToolbarIconButton(systemName: "calendar", onTap: { showEvents = true })
            Spacer()
            BetweenBrandLockup(style: .toolbar)
            Spacer()
            ToolbarIconButton(
                systemName: "person.2.fill",
                badge: viewModel.notificationCount,
                onTap: { showNetwork = true }
            )
        }
    }

    private func featuredEventCard(_ event: CampusEventCard) -> some View {
        Button { showEvents = true } label: {
            HStack(spacing: 14) {
                Image(systemName: event.interestIcon)
                    .font(.title2)
                    .foregroundStyle(BetweenTheme.accent)
                    .frame(width: 48, height: 48)
                    .background(BetweenTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Because you picked \(event.interestName.lowercased())")
                        .font(BetweenFont.captionMedium())
                        .foregroundStyle(BetweenTheme.accent)
                    Text(event.title)
                        .font(BetweenFont.secondary().weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitleForFeatured(event))
                        .font(BetweenFont.caption())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .surfaceCard()
        }
        .buttonStyle(.plain)
    }

    private func subtitleForFeatured(_ event: CampusEventCard) -> String {
        var parts = ["\(event.interestedCount) interested"]
        if event.showsMatching {
            parts.append("\(event.partnerSeekingCount) \(event.matchingKind.seekingShortLabel)")
        }
        if let recurrence = event.recurrenceLabel {
            parts.append(recurrence)
        }
        return parts.joined(separator: " · ")
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
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundStyle(BetweenTheme.accent)
                SectionHeader(title: "Free right now", subtitle: "\(snapshot.friendsFreeNow.count) on campus")
            }

            ForEach(snapshot.friendsFreeNow.prefix(3)) { friend in
                freeNowCard(friend)
            }
        }
    }

    private func freeNowCard(_ friend: FriendCard) -> some View {
        HStack(spacing: 14) {
            FriendAvatarView(
                name: friend.name,
                friendId: friend.id,
                size: 52,
                showsFreeRing: true
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(FriendColorPalette.firstName(friend.name))
                    .font(BetweenFont.cardTitle())
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(BetweenTheme.accent)
                    Text(friend.location)
                        .font(BetweenFont.caption())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    viewModel.showToast("Coming soon")
                } label: {
                    Image(systemName: "message.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(BetweenTheme.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(BetweenTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            SectionHeader(title: "Free later today", subtitle: "Overlapping time")

            ForEach(snapshot.meetups.prefix(3)) { meetup in
                HStack(spacing: 14) {
                    Image(systemName: meetup.icon)
                        .font(.title3)
                        .foregroundStyle(BetweenTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(BetweenTheme.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(meetup.timeLabel)
                            .font(BetweenFont.cardTitle())
                        Text(meetup.namesLine)
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
    
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Down for...")
                .font(BetweenFont.sectionTitle())
            
            ActivityModeBar()
            
            Button {
                Task { await viewModel.setActivityMode(.social) }
            } label: {
                HStack {
                    Image(systemName: "hand.wave.fill")
                        .font(.title3)
                    Text("Available to hang")
                        .font(BetweenFont.secondary().weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(BetweenTheme.accent.opacity(0.12))
                .foregroundStyle(BetweenTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var spontaneousPlanCard: some View {
        Group {
            if let suggestion = viewModel.spontaneousPlanSuggestion() {
                Button {
                    viewModel.showToast("Tap to message them")
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.title2)
                            .foregroundStyle(BetweenTheme.accent)
                            .frame(width: 44, height: 44)
                            .background(BetweenTheme.accentSoft)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.title)
                                .font(BetweenFont.cardTitle())
                                .foregroundStyle(.primary)
                            Text(suggestion.subtitle)
                                .font(BetweenFont.secondary())
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .surfaceCard()
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showScheduleTimeline.toggle()
            } label: {
                HStack {
                    SectionHeader(title: "Schedule", subtitle: "Today's timeline")
                    Spacer()
                    Image(systemName: showScheduleTimeline ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showScheduleTimeline {
                HorizontalOverlapTimeline(
                    todayPlan: viewModel.todayPlan,
                    starredIds: viewModel.preferences.starredFriendIds
                )
            }
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppViewModel.make())
}
