import SwiftUI

struct ClassFriendsSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let section: CourseSection

    private var connections: [ClassConnection] {
        viewModel.connections(for: section)
    }

    private var sameSection: [ClassConnection] {
        connections.filter { $0.kind == .sameSection }
    }

    private var otherSection: [ClassConnection] {
        connections.filter { $0.kind == .differentSection }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.courseName)
                            .font(BetweenFont.secondary().weight(.medium))
                        Text("Section \(section.sectionLabel) · \(section.location)")
                            .font(BetweenFont.caption())
                            .foregroundStyle(.secondary)
                        Text("\(BetweenFormat.displayDays(section.meetingDays)) · \(BetweenFormat.displayTime(section.startTime)) – \(BetweenFormat.displayTime(section.endTime))")
                            .font(BetweenFont.caption())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    if sameSection.isEmpty {
                        Text("No friends in this section yet")
                            .font(BetweenFont.secondary())
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sameSection) { connection in
                            friendConnectionRow(connection)
                        }
                    }
                } header: {
                    Label("Same section", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(BetweenTheme.accent)
                }

                Section {
                    if otherSection.isEmpty {
                        Text("No friends in a different section")
                            .font(BetweenFont.secondary())
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(otherSection) { connection in
                            friendConnectionRow(connection)
                        }
                    }
                } header: {
                    Label("Same class, different section", systemImage: "arrow.left.arrow.right")
                        .foregroundStyle(BetweenTheme.studying)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(section.courseCode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func friendConnectionRow(_ connection: ClassConnection) -> some View {
        HStack(spacing: 12) {
            FriendAvatarView(name: connection.friendName, friendId: connection.id, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.friendName)
                    .font(BetweenFont.secondary().weight(.medium))
                Text(connection.kind.shortLabel)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Sec \(connection.sectionLabel.replacingOccurrences(of: "Section ", with: ""))")
                .font(BetweenFont.captionMedium())
                .foregroundStyle(connection.kind.color)
        }
    }
}
