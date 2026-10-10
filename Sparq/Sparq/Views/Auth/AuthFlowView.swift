import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            SparqTheme.screenBackground(colorScheme).ignoresSafeArea()

            switch viewModel.authStep {
            case .welcome:
                welcomeScreen
            case .sso:
                ssoScreen
            case .newUser:
                newUserScreen
            }
        }
    }

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            SparqBrandLockup(style: .welcome)

            Text("See what’s happening on campus\nand actually show up.")
                .font(SparqFont.secondary())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            VTPilotBadge()
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "sparkles", text: "Official games, clubs, and pop-ups in one place")
                featureRow(icon: "bell", text: "Keep me posted - private, no commitment")
                featureRow(icon: "sportscourt", text: "IM team fills and pickup spots you’d otherwise miss")
            }
            .padding(.horizontal, 36)
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.authStep = .sso
                    viewModel.errorMessage = nil
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                        Text("Sign in with Virginia Tech")
                    }
                }
                .buttonStyle(SparqPrimaryButtonStyle())

                Button {
                    viewModel.authStep = .newUser
                    viewModel.errorMessage = nil
                } label: {
                    Text("New to Sparq? Activate account")
                }
                .buttonStyle(SparqSecondaryButtonStyle())

                Text("Sparq uses VT SSO. We never see or store your password.")
                    .font(SparqFont.caption())
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(SparqTheme.accent)
                .frame(width: 32)
            Text(text)
                .font(SparqFont.secondary())
        }
    }

    private var ssoScreen: some View {
        authForm(
            title: "Virginia Tech SSO",
            subtitle: "Sign in with your @vt.edu account. Virginia Tech verifies your identity. Sparq never sees your password."
        ) {
            VTPilotBadge()
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("you@vt.edu", text: $viewModel.loginEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(12)
                .background(SparqTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(SparqTheme.vtMaroon)
                Text("Only verified VT students can sign in. Your schedule stays encrypted on your device.")
                    .font(SparqFont.caption())
                    .foregroundStyle(.secondary)
            }

            #if DEBUG
            Text("Demo: alex.hirsch@vt.edu")
                .font(SparqFont.caption())
                .foregroundStyle(.tertiary)
            #endif

            Button {
                Task { await viewModel.loginWithSSO() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Verifying with VT…" : "Continue with Virginia Tech")
                }
            }
            .buttonStyle(SparqPrimaryButtonStyle())
            .disabled(!isValidVTEmail(viewModel.loginEmail) || viewModel.isLoading)
        }
    }

    private var newUserScreen: some View {
        authForm(
            title: "Activate your account",
            subtitle: "Use the email from your welcome message. Pilot accounts must already exist on the VT roster in Sparq."
        ) {
            TextField("you@vt.edu", text: $viewModel.loginEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(12)
                .background(SparqTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            TextField("6-digit code", text: $viewModel.activationCode)
                .keyboardType(.numberPad)
                .padding(12)
                .background(SparqTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            #if DEBUG
            Text("Demo code: 482910")
                .font(SparqFont.caption())
                .foregroundStyle(.tertiary)
            #endif

            Button {
                Task { await viewModel.activateNewUser() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Activating…" : "Continue")
                }
            }
            .buttonStyle(SparqPrimaryButtonStyle())
            .disabled(
                !isValidVTEmail(viewModel.loginEmail)
                    || viewModel.activationCode.count < 6
                    || viewModel.isLoading
            )
        }
    }

    private func isValidVTEmail(_ email: String) -> Bool {
        email.lowercased().hasSuffix("@vt.edu") && email.contains("@")
    }

    private func authForm<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder fields: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    viewModel.authStep = .welcome
                    viewModel.errorMessage = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(SparqFont.secondary())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(SparqFont.screenTitle())
                        Text(subtitle)
                            .font(SparqFont.secondary())
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 14) {
                        fields()
                    }

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(SparqFont.caption())
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
        }
    }
}
