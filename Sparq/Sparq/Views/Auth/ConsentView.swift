import SwiftUI

struct ConsentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var privacyChecked = false
    @State private var interestChecked = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(SparqTheme.accent)
                .padding(.bottom, 16)

            VStack(spacing: 8) {
                Text("Low pressure, your privacy")
                    .font(SparqFont.screenTitle())
                Text("Sparq helps you find campus events without broadcasting your plans. Tracking stays private unless you opt in.")
                    .font(SparqFont.secondary())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 16) {
                consentRow(
                    icon: "bell.badge",
                    title: "Keep me posted is private",
                    detail: "Other students only see anonymous counts - not your name - unless you explicitly opt in."
                )
                consentRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "VT students only",
                    detail: "Sign-in uses your @vt.edu email so the feed stays campus-real."
                )
                consentRow(
                    icon: "hand.raised.fill",
                    title: "No class schedules",
                    detail: "We don’t import courses or free-time calendars. This is about campus life, not academics."
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)

            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $interestChecked) {
                    Text("I understand event tracking is private by default")
                        .font(SparqFont.secondary())
                }
                Toggle(isOn: $privacyChecked) {
                    Text("I agree to the Privacy Policy (v2026-09)")
                        .font(SparqFont.secondary())
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: SparqTheme.accent))
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Spacer()

            Button {
                Task { await viewModel.acceptConsent() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Setting up…" : "Continue to Sparq")
                }
            }
            .buttonStyle(SparqPrimaryButtonStyle())
            .disabled(!interestChecked || !privacyChecked || viewModel.isLoading)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(SparqTheme.screenBackground(colorScheme).ignoresSafeArea())
    }

    private func consentRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(SparqTheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SparqFont.secondary().weight(.semibold))
                Text(detail)
                    .font(SparqFont.caption())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
