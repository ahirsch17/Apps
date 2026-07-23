import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            BetweenTheme.screenBackground(colorScheme).ignoresSafeArea()

            switch viewModel.authStep {
            case .welcome:
                welcomeScreen
            case .returning:
                returningScreen
            case .newUser:
                newUserScreen
            }
        }
    }

    private var welcomeScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 80)
                .accessibilityLabel("Between logo")

            VStack(spacing: 8) {
                Text("Between")
                    .font(.largeTitle.weight(.bold))
                Text("See when you and friends are free between classes.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button {
                    viewModel.authStep = .returning
                    viewModel.errorMessage = nil
                } label: {
                    Text("I'm returning")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(BetweenTheme.neonViolet)

                Button {
                    viewModel.authStep = .newUser
                    viewModel.errorMessage = nil
                } label: {
                    Text("I'm new")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .padding(.vertical, 32)
    }

    private var returningScreen: some View {
        authForm(
            title: "Welcome back",
            subtitle: "Sign in with your VT email and password."
        ) {
            TextField("Email", text: $viewModel.loginEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $viewModel.loginPassword)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            Text("Demo: alex.hirsch@vt.edu · password demo123")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task { await viewModel.loginReturning() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Signing in…" : "Sign in")
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(BetweenTheme.neonViolet)
            .disabled(viewModel.loginEmail.isEmpty || viewModel.isLoading)
        }
    }

    private var newUserScreen: some View {
        authForm(
            title: "Activate account",
            subtitle: "Enter the code from your VT welcome email."
        ) {
            TextField("VT email", text: $viewModel.loginEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            TextField("6-digit code", text: $viewModel.activationCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Text("Demo code: 482910 (works with any seed account email)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task { await viewModel.activateNewUser() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Activating…" : "Continue")
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(BetweenTheme.neonViolet)
            .disabled(viewModel.loginEmail.isEmpty || viewModel.activationCode.count < 6 || viewModel.isLoading)
        }
    }

    private func authForm<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder fields: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button("Back") {
                    viewModel.authStep = .welcome
                    viewModel.errorMessage = nil
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.title2.weight(.bold))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        fields()
                    }
                    .surfaceCard()

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
        }
    }
}
