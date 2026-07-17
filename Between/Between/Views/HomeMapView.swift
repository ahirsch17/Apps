import SwiftUI

struct HomeMapView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                mapPanel
                classesPanel
                myClassesPanel
                nearbyPanel
                pingPanel
            }
            .padding(.top, 86)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hey \(viewModel.me?.name.components(separatedBy: " ").first ?? "there")")
                .font(.largeTitle.weight(.bold))
            Text("\(viewModel.nearbyFriends.count) friends nearby · \(viewModel.nearbyFriends.filter { $0.status == .freeNow }.count) free now")
                .foregroundStyle(BetweenTheme.neonMint)
                .font(.subheadline.weight(.medium))
            Text(viewModel.lastSyncText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var mapPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.11, green: 0.20, blue: 0.45), Color(red: 0.03, green: 0.05, blue: 0.10)]
                            : [Color(red: 0.72, green: 0.85, blue: 1.00), Color(red: 0.86, green: 0.93, blue: 1.00)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .frame(height: 290)
            Circle()
                .fill(BetweenTheme.neonBlue.opacity(0.4))
                .frame(width: 32, height: 32)
            ForEach(Array(viewModel.nearbyFriends.enumerated()), id: \.offset) { index, friend in
                FriendMapChip(friend: friend)
                    .offset(offset(for: index))
            }
        }
        .glassCard()
    }

    private var classesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Class connections")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button(viewModel.isRefreshing ? "Refreshing..." : "Refresh") {
                    Task { await viewModel.refresh() }
                }
                    .font(.caption.weight(.semibold))
            }

            Text("Friends in your courses and nearby sections")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(viewModel.classConnections.prefix(6)) { connection in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(connection.kind.color)
                        .frame(width: 9, height: 9)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(connection.courseCode) · \(connection.friendName)")
                            .font(.subheadline.weight(.semibold))
                        Text(connection.courseName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(connection.kind.label) · \(connection.sectionLabel)")
                            .font(.caption)
                            .foregroundStyle(connection.kind.color)
                        Text("Meets: \(connection.meetingDays.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .glassCard()
    }

    private var myClassesPanel: some View {
        let weekend = viewModel.mySections.filter { !$0.meetingDays.filter({ $0 == "Sat" || $0 == "Sun" }).isEmpty }
        let display = weekend.isEmpty ? Array(viewModel.mySections.prefix(4)) : Array(weekend.prefix(4))

        return VStack(alignment: .leading, spacing: 8) {
            Text("Your classes (weekend test set)")
                .font(.headline)
            ForEach(display) { section in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(section.courseCode) · Section \(section.sectionLabel)")
                        .font(.subheadline.weight(.semibold))
                    Text("\(section.meetingDays.joined(separator: ", ")) · \(section.startTime)-\(section.endTime) · \(section.location)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glassCard()
    }

    private func offset(for index: Int) -> CGSize {
        switch index {
        case 0: return CGSize(width: -95, height: 75)
        case 1: return CGSize(width: 74, height: -72)
        case 2: return CGSize(width: 92, height: 50)
        default: return CGSize(width: -32, height: 124)
        }
    }

    private var nearbyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("People you know nearby")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("See all") { }
                    .foregroundStyle(BetweenTheme.neonViolet)
            }

            ForEach(viewModel.nearbyFriends) { friend in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 38, height: 38)
                        .overlay(Text(friend.avatarEmoji).font(.title3))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.name).font(.headline)
                        Text("\(friend.status.label) · \(friend.activity)")
                            .font(.subheadline)
                            .foregroundStyle(friend.status.color)
                        Text("\(friend.location) · \(friend.distanceLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if friend.status == .freeNow {
                        Button("Join") { }
                            .buttonStyle(.borderedProminent)
                            .tint(BetweenTheme.neonViolet)
                    } else {
                        Image(systemName: "bubble.left")
                            .foregroundStyle(.primary.opacity(0.8))
                    }
                }
            }
        }
        .glassCard()
    }

    private var pingPanel: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ping friends")
                    .font(.headline)
                Text("Let friends know you're free")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("I'm free") { }
                .buttonStyle(.borderedProminent)
                .tint(BetweenTheme.neonViolet)
        }
        .glassCard()
    }
}

private struct FriendMapChip: View {
    let friend: FriendCard

    var body: some View {
        HStack(spacing: 8) {
            Text(friend.avatarEmoji)
                .font(.caption)
            VStack(alignment: .leading, spacing: 0) {
                Text(friend.name)
                    .font(.caption.weight(.semibold))
                Text(friend.status.label)
                    .font(.caption2)
                    .foregroundStyle(friend.status.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.18))
        .clipShape(Capsule())
    }
}

#Preview {
    HomeMapView()
}
