import SwiftUI

struct ConsentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var ferpaChecked = false
    @State private var privacyChecked = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(BetweenTheme.accent)
                .padding(.bottom, 16)

            VStack(spacing: 8) {
                Text("Your schedule, your rules")
                    .font(BetweenFont.screenTitle())
                Text("Between keeps your schedule private on our servers. Friends only see overlap windows you allow—not your full class list.")
                    .font(BetweenFont.secondary())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 16) {
                consentRow(
                    icon: "lock.shield.fill",
                    title: "Encrypted in transit",
                    detail: "Your data is protected between your phone and campus systems. Course discovery can use one-way hashes so we don't expose raw catalog details unnecessarily."
                )
                consentRow(
                    icon: "calendar.badge.checkmark",
                    title: "Free time overlap only",
                    detail: "Friends you add will only see when your free time overlaps with theirs. You control who can see this for each friend."
                )
                consentRow(
                    icon: "person.2.badge.gearshape",
                    title: "FERPA-aligned",
                    detail: "Between is built for campus partners. We don't sell student data."
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)

            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $ferpaChecked) {
                    Text("I understand my schedule is encrypted and only I control who sees overlap times")
                        .font(BetweenFont.secondary())
                }
                Toggle(isOn: $privacyChecked) {
                    Text("I agree to the Privacy Policy (v2026-07)")
                        .font(BetweenFont.secondary())
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: BetweenTheme.accent))
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Spacer()

            Button {
                Task { await viewModel.acceptConsent() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Setting up…" : "Continue to Between")
                }
            }
            .buttonStyle(BetweenPrimaryButtonStyle())
            .disabled(!ferpaChecked || !privacyChecked || viewModel.isLoading)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(BetweenTheme.screenBackground(colorScheme).ignoresSafeArea())
    }

    private func consentRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(BetweenTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BetweenFont.secondary().weight(.semibold))
                Text(detail)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
