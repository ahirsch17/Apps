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
                            .font(SparqFont.secondary().weight(.medium))
                        Text("Section \(section.sectionLabel) · \(section.location)")
                            .font(SparqFont.caption())
                            .foregroundStyle(.secondary)
                        Text("\(SparqFormat.displayDays(section.meetingDays)) · \(SparqFormat.displayTime(section.startTime)) to \(SparqFormat.displayTime(section.endTime))")
                            .font(SparqFont.caption())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    if sameSection.isEmpty {
                        Text("No friends in this section yet")
                            .font(SparqFont.secondary())
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sameSection) { connection in
                            friendConnectionRow(connection)
                        }
                    }
                } header: {
                    Label("Same section", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(SparqTheme.accent)
                }

                Section {
                    if otherSection.isEmpty {
                        Text("No friends in a different section")
                            .font(SparqFont.secondary())
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(otherSection) { connection in
                            friendConnectionRow(connection)
                        }
                    }
                } header: {
                    Label("Same class, different section", systemImage: "arrow.left.arrow.right")
                        .foregroundStyle(SparqTheme.studying)
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
                    .font(SparqFont.secondary().weight(.medium))
                Text(connection.kind.shortLabel)
                    .font(SparqFont.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Sec \(connection.sectionLabel.replacingOccurrences(of: "Section ", with: ""))")
                .font(SparqFont.captionMedium())
                .foregroundStyle(connection.kind.color)
        }
    }
}
