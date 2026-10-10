import SwiftUI

struct ScheduleTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedSection: CourseSection?

    private var plan: [TodayPlanItem] { viewModel.fullDayPlan }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if plan.isEmpty {
                    ContentUnavailableView(
                        "No classes today",
                        systemImage: "calendar.badge.minus",
                        description: Text("Your \(BackendConfiguration.weekdayName()) schedule is clear.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    MockupScheduleStack(
                        plan: plan,
                        connectionsFor: viewModel.connections(for:),
                        onClassTap: { selectedSection = $0 }
                    )

                    MockupDailyInsight(
                        freeMinutes: plan.filter { $0.kind == .freeBlock }.reduce(0) { $0 + $1.durationMinutes },
                        overlapHint: overlapHint
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
        .background(SparqTheme.screenBackground(colorScheme))
        .sheet(item: $selectedSection) { section in
            ClassFriendsSheet(section: section)
        }
    }

    private var header: some View {
        HStack {
            Text("My Schedule")
                .font(.largeTitle.weight(.bold))
            Spacer()
            Button { Task { await viewModel.refresh() } } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SparqTheme.accent)
            }
            .buttonStyle(.plain)
            Button {} label: {
                Image(systemName: "calendar")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SparqTheme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var overlapHint: String? {
        guard let window = viewModel.today.meetups.first, !window.friendNames.isEmpty else { return nil }
        return "Most friends overlap \(window.timeLabel.lowercased()). Good time to meet up."
    }
}
