import SwiftUI

struct CourseLookupSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var classDetailSection: CourseSection?

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.mySections.isEmpty {
                    Section("Your classes") {
                        ForEach(viewModel.mySections) { section in
                            Button {
                                classDetailSection = section
                            } label: {
                                courseRow(section, highlight: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section(viewModel.mySections.isEmpty ? "Search catalog" : "Search all sections") {
                    if viewModel.courseSearchResults.isEmpty {
                        ContentUnavailableView(
                            "Search classes",
                            systemImage: "magnifyingglass",
                            description: Text("Try a course code or name from your schedule")
                        )
                    } else {
                        ForEach(viewModel.courseSearchResults) { section in
                            Button {
                                classDetailSection = section
                            } label: {
                                courseRow(section, highlight: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Classes & matches")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.courseSearchQuery, prompt: "Course code or name")
            .onChange(of: viewModel.courseSearchQuery) { _, _ in
                viewModel.searchCourses()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if viewModel.courseSearchQuery.isEmpty {
                    viewModel.courseSearchQuery = "CS"
                    viewModel.searchCourses()
                }
            }
            .sheet(item: $classDetailSection) { section in
                ClassFriendsSheet(section: section)
            }
        }
    }

    private func courseRow(_ section: CourseSection, highlight: Bool) -> some View {
        let friendCount = viewModel.connections(for: section).count
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(section.courseCode)
                    .font(BetweenFont.secondary().weight(.semibold))
                Text("Sec \(section.sectionLabel)")
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
                Spacer()
                if friendCount > 0 {
                    Label("\(friendCount) friends", systemImage: "person.2.fill")
                        .font(BetweenFont.captionMedium())
                        .foregroundStyle(BetweenTheme.accent)
                } else {
                    Text("No friend matches")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            Text(section.courseName)
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text("\(BetweenFormat.displayDays(section.meetingDays)) · \(BetweenFormat.displayTime(section.startTime)) – \(BetweenFormat.displayTime(section.endTime))")
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
            if highlight {
                Text("Tap to see friends in this class")
                    .font(.caption2)
                    .foregroundStyle(BetweenTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
