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
                    Text(section.courseName)
                        .font(.subheadline)
                    Text("Section \(section.sectionLabel) · \(section.location)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Same section") {
                    if sameSection.isEmpty {
                        Text("No connected friends in this section yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sameSection) { connection in
                            friendConnectionRow(connection)
                        }
                    }
                }

                Section("Same course, other section") {
                    if otherSection.isEmpty {
                        Text("No connected friends in other sections.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(otherSection) { connection in
                            friendConnectionRow(connection)
                        }
                    }
                }
            }
            .navigationTitle(section.courseCode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func friendConnectionRow(_ connection: ClassConnection) -> some View {
        HStack {
            Circle()
                .fill(connection.kind.color)
                .frame(width: 8, height: 8)
            Text(connection.friendName)
            Spacer()
            Text(connection.sectionLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
