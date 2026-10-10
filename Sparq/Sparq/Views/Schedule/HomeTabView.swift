import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDay = Date()
    @State private var showFreeNow = false
    @State private var selectedSection: CourseSection?

    private var snapshot: TodayPresenter.Snapshot { viewModel.today }

    private var freeBlocks: [TodayPlanItem] {
        viewModel.fullDayPlan.filter { $0.kind == .freeBlock }
    }

    private var freeMinutesToday: Int {
        freeBlocks.reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                MockupWeekStrip(selectedDay: $selectedDay)
                MockupGlanceCard(
                    freeTimeLabel: freeTimeLabel,
                    gapCount: freeBlocks.count,
                    friendsFree: snapshot.friendsFreeNow,
                    onFindSomething: {
                        if !snapshot.friendsFreeNow.isEmpty { showFreeNow = true }
                    }
                )
                classesSection
                MockupWhoInClassesSection(
                    sections: viewModel.mySections,
                    connectionsFor: viewModel.connections(for:),
                    onTap: { selectedSection = $0 }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
        .background(SparqTheme.screenBackground(colorScheme))
        .refreshable { await viewModel.refresh() }
        .sheet(isPresented: $showFreeNow) {
            FreeNowListSheet(friends: snapshot.friendsFreeNow)
        }
        .sheet(item: $selectedSection) { section in
            ClassFriendsSheet(section: section)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(greeting)
                .font(.title2.weight(.bold))
            Spacer()
            profileBubble
        }
    }

    private var profileBubble: some View {
        let name = viewModel.me?.name ?? "You"
        return Text(FriendColorPalette.initials(for: name))
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(SparqTheme.accent)
            .clipShape(Circle())
    }

    private var classesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your classes today")
                .font(.headline.weight(.semibold))

            if viewModel.fullDayPlan.isEmpty {
                Text("No classes on the schedule today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                MockupHomeTimeline(
                    items: viewModel.fullDayPlan,
                    connectionsFor: viewModel.connections(for:),
                    onClassTap: { selectedSection = $0 }
                )
            }
        }
    }

    private var freeTimeLabel: String {
        let hours = freeMinutesToday / 60
        let mins = freeMinutesToday % 60
        if hours > 0, mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(mins)m"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation: String
        switch hour {
        case 5..<12: salutation = "Good morning"
        case 12..<17: salutation = "Good afternoon"
        default: salutation = "Good evening"
        }
        if let first = viewModel.me?.name.components(separatedBy: " ").first {
            return "\(salutation), \(first) ☀️"
        }
        return "\(salutation) ☀️"
    }
}

private struct FreeNowListSheet: View {
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
