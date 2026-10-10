import SwiftUI

struct InterestsOnboardingView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selected: Set<String> = []

    private var interests: [Interest] { viewModel.eventsData?.interests ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("Almost done")
                    .font(SparqFont.captionMedium())
                    .foregroundStyle(SparqTheme.accent)
                Text("What are you into?")
                    .font(SparqFont.greeting())
                Text("Pick at least two. We'll prioritize campus events and hangouts that fit.")
                    .font(SparqFont.secondary())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(interests) { interest in
                    interestChip(interest)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer()

            Button {
                Task { await viewModel.completeOnboarding(selected: Array(selected)) }
            } label: {
                Text("Continue")
            }
            .buttonStyle(SparqPrimaryButtonStyle())
            .disabled(selected.count < 2)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(SparqTheme.screenBackground(colorScheme).ignoresSafeArea())
        .task { await viewModel.loadEvents() }
    }

    private func interestChip(_ interest: Interest) -> some View {
        let picked = selected.contains(interest.id)
        return Button {
            if picked { selected.remove(interest.id) } else { selected.insert(interest.id) }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: interest.icon)
                    .font(.title2)
                Text(interest.name)
                    .font(SparqFont.captionMedium())
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(picked ? SparqTheme.accent : SparqTheme.surface(colorScheme))
            .foregroundStyle(picked ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous)
                    .stroke(picked ? SparqTheme.accent : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
