import SwiftUI

/// Fair family-friendly progress: compare **% of personal goal**, not raw points.
/// Each person shares from their own device until cloud sync exists.
struct FamilyProgressSheet: View {
    @Environment(ProgramStore.self) private var programStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    familyMemberRow(
                        name: programStore.displayName.isEmpty ? "You" : programStore.displayName,
                        week: programStore.weekNumber,
                        percent: programStore.weekCompletionPercent,
                        earned: Int(programStore.weekPoints.rounded()),
                        target: programStore.periodTarget,
                        streak: programStore.consecutiveWeeksMet,
                        isYou: true
                    )
                } header: {
                    Text("Your week")
                } footer: {
                    Text("Compare % of goal, not raw points. Tap Share to send your weekly snapshot image.")
                        .font(.caption)
                }

                Section("Family compare") {
                    Label("Each person uses Stoke on their phone", systemImage: "iphone")
                    Label("Share your weekly snapshot image", systemImage: "square.and.arrow.up")
                    Label("Compare % of goal side by side", systemImage: "percent")
                }
                .font(.subheadline)
            }
            .scrollContentBackground(.hidden)
            .background(StokeTheme.cream)
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareProgressLink {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func familyMemberRow(
        name: String,
        week: Int,
        percent: Int,
        earned: Int,
        target: Int,
        streak: Int,
        isYou: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.headline)
                if isYou {
                    Text("You")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(StokeTheme.parchment)
                        .clipShape(Capsule())
                }
                Spacer()
                Text("Week \(week)")
                    .font(.caption)
                    .foregroundStyle(StokeTheme.inkMuted)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("\(percent)%")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(StokeTheme.terracottaDeep)
                Text("of goal")
                    .font(.subheadline)
                    .foregroundStyle(StokeTheme.inkMuted)
            }

            ProgressView(value: min(Double(percent) / 100.0, 1.0))
                .tint(percent >= 100 ? StokeTheme.sage : StokeTheme.terracotta)

            Text("\(earned) / \(target) pts")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(StokeTheme.inkMuted)

            if streak >= 2 {
                Label("\(streak)-week goal streak", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(StokeTheme.sage)
            }
        }
        .padding(.vertical, 4)
    }
}
