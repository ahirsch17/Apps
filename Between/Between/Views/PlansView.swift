import SwiftUI

struct PlansView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    private let quickActions = [
        ("Grab food", "fork.knife", BetweenTheme.neonGreen, "food", "Turner Place"),
        ("Study sprint", "book.closed", BetweenTheme.neonViolet, "study", "Newman Library"),
        ("Gym run", "figure.run", BetweenTheme.neonMint, "fitness", "War Memorial Gym"),
        ("Walk to class", "figure.walk", BetweenTheme.neonBlue, "transit", "Drillfield")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create a Plan")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 84)
                    .accessibilityAddTraits(.isHeader)

                Text("One tap. Friends who overlap get notified.")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(quickActions, id: \.0) { action in
                        Button {
                            Task {
                                await viewModel.createQuickPlan(
                                    type: action.3,
                                    title: action.0,
                                    location: action.4
                                )
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: action.1)
                                    .font(.title2)
                                    .foregroundStyle(action.2)
                                Text(action.0)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Notify relevant friends")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard()
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Create \(action.0) plan at \(action.4)")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Upcoming from friend network")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    if viewModel.plans.isEmpty {
                        Text("No plans yet — tap a quick action above.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.plans.prefix(6)) { plan in
                        timelineRow(title: "\(plan.type): \(plan.title)", subtitle: "\(plan.location) · \(plan.startTime.formatted(date: .omitted, time: .shortened))")
                    }
                }
                .glassCard()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func timelineRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

#Preview {
    PlansView()
}
