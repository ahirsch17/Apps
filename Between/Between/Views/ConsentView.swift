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
                Text("Before we sync your classes, here's how Between protects your data.")
                    .font(BetweenFont.secondary())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 16) {
                consentRow(
                    icon: "calendar.badge.checkmark",
                    title: "Schedule sharing is opt-in",
                    detail: "Only friends you add see your free windows — never raw class locations."
                )
                consentRow(
                    icon: "person.2.badge.gearshape",
                    title: "FERPA-aligned",
                    detail: "Between is built for campus partners. We don't sell student data."
                )
                consentRow(
                    icon: "key.fill",
                    title: "Courses stay private",
                    detail: "Your phone hashes course IDs before anything is sent. We never see CRNs or grades."
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)

            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $ferpaChecked) {
                    Text("I understand how my schedule data is shared")
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
