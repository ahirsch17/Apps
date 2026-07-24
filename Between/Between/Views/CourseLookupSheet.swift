import SwiftUI

struct CourseLookupSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    if viewModel.courseSearchResults.isEmpty {
                        ContentUnavailableView(
                            "Search classes",
                            systemImage: "magnifyingglass",
                            description: Text("Try CS 2114, MATH, or a CRN")
                        )
                    } else {
                        ForEach(viewModel.courseSearchResults) { section in
                            courseRow(section)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Find a class")
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
        }
    }

    private func courseRow(_ section: CourseSection) -> some View {
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
                    Label("\(friendCount)", systemImage: "person.2.fill")
                        .font(BetweenFont.captionMedium())
                        .foregroundStyle(BetweenTheme.accent)
                }
            }
            Text(section.courseName)
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text("\(BetweenFormat.displayDays(section.meetingDays)) · \(BetweenFormat.displayTime(section.startTime)) – \(BetweenFormat.displayTime(section.endTime))")
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
            Text(section.location)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
