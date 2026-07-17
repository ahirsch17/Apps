import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Friends First")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 84)

                Text("This view only surfaces friends and trusted connections, never the full campus feed.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Friends in your classes")
                        .font(.headline)
                    ForEach(viewModel.classConnections.prefix(8)) { connection in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(connection.courseCode) · \(connection.friendName)")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(connection.kind.label) · \(connection.sectionLabel)")
                                    .font(.caption)
                                    .foregroundStyle(connection.kind.color)
                            }
                            Spacer()
                            Button("Nudge") { }
                                .buttonStyle(.bordered)
                        }
                    }
                }
                .glassCard()

                if !viewModel.pendingIncoming.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Incoming friend requests")
                            .font(.headline)
                        ForEach(viewModel.pendingIncoming, id: \.id) { student in
                            HStack {
                                Text(student.name)
                                Spacer()
                                Button("Accept") {
                                    Task { await viewModel.acceptRequest(from: student) }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .glassCard()
                }

                ForEach(viewModel.nearbyFriends) { friend in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .overlay(Text(friend.avatarEmoji).font(.title3))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.name).font(.headline)
                            Text(friend.activity).foregroundStyle(.secondary)
                            Text("\(friend.location) · \(friend.distanceLabel)")
                                .font(.caption)
                                .foregroundStyle(friend.status.color)
                        }
                        Spacer()
                        Button("Plan") { }
                            .buttonStyle(.bordered)
                            .tint(friend.status.color)
                    }
                    .glassCard()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("People to add")
                        .font(.headline)
                    ForEach(viewModel.suggested.prefix(12), id: \.id) { student in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(student.name)
                                Text(student.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Add") {
                                Task { await viewModel.sendFriendRequest(to: student) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .glassCard()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    FriendsListView()
}
