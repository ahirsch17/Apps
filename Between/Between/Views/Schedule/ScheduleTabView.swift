import SwiftUI

/// Full schedule reference — classes list + same overlap board as home.
struct ScheduleTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var classSheetSection: CourseSection?

    private var classBlocks: [TodayPlanItem] {
        viewModel.todayPlan.filter { $0.kind == .classBlock }
    }

    var body: some View {
        List {
            Section {
                DayOverlapBoardView(
                    todayPlan: viewModel.todayPlan,
                    starredIds: viewModel.preferences.starredFriendIds
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Classes today") {
                if classBlocks.isEmpty {
                    Text("No more classes today")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(classBlocks) { item in
                        if let section = item.section {
                            Button { classSheetSection = section } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(section.courseCode)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(ScheduleEngine.formatRange(start: item.startMinutes, end: item.endMinutes))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "person.2")
                                        .foregroundStyle(BetweenTheme.accent)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !viewModel.recurringWindows.isEmpty {
                Section("Weekly patterns") {
                    ForEach(viewModel.recurringWindows) { window in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(window.timeLabel)
                                .font(.body.weight(.medium))
                            Text("\(window.pattern.displayName) · \(window.friendNamesLine)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await viewModel.refresh() }
        .sheet(item: $classSheetSection) { section in
            ClassFriendsSheet(section: section)
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleTabView()
            .environmentObject(AppViewModel.make())
    }
}
