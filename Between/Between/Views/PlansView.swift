import SwiftUI

struct PlansView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    private let quickActions = [
        ("Grab food", "fork.knife", BetweenTheme.neonGreen),
        ("Study sprint", "book.closed", BetweenTheme.neonViolet),
        ("Gym run", "figure.run", BetweenTheme.neonMint),
        ("Walk to class", "figure.walk", BetweenTheme.neonBlue)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create a Plan")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 84)

                Text("One tap plans. Friends with matching availability get notified.")
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(quickActions, id: \.0) { action in
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: action.1)
                                .font(.title2)
                                .foregroundStyle(action.2)
                            Text(action.0)
                                .font(.headline)
                            Text("Notify relevant friends")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Upcoming from friend network")
                        .font(.headline)
                    ForEach(viewModel.plans.prefix(6)) { plan in
                        timelineRow(title: "\(plan.type): \(plan.title)", subtitle: "\(plan.location) • \(plan.startTime.formatted(date: .omitted, time: .shortened))")
                    }
                }
                .glassCard()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
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
    }
}

#Preview {
    PlansView()
}
