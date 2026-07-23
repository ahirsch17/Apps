import SwiftUI

struct CourseLookupSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("CRN, course code, or name", text: $viewModel.courseSearchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: viewModel.courseSearchQuery) { _, _ in
                        viewModel.searchCourses()
                    }

                List(viewModel.courseSearchResults) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(section.courseCode) · Sec \(section.sectionLabel)")
                            .font(.subheadline.weight(.semibold))
                        Text(section.courseName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(section.meetingDays.joined(separator: ", ")) · \(section.startTime)–\(section.endTime) · \(section.location)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Course lookup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
}
