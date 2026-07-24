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
        VStack(spacing: 0) {
            Spacer()

            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 64)
                .accessibilityLabel("Between logo")

            VStack(spacing: 10) {
                Text("Between")
                    .font(BetweenFont.greeting())
                Text("Know when you and your friends\nare free between classes.")
                    .font(BetweenFont.secondary())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "person.2.fill", text: "See who's free right now")
                featureRow(icon: "fork.knife", text: "Find lunch windows together")
                featureRow(icon: "books.vertical.fill", text: "Spot friends in your classes")
            }
            .padding(.horizontal, 36)
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.authStep = .returning
                    viewModel.errorMessage = nil
                } label: {
                    Text("Sign in")
                }
                .buttonStyle(BetweenPrimaryButtonStyle())

                Button {
                    viewModel.authStep = .newUser
                    viewModel.errorMessage = nil
                } label: {
                    Text("New to Between? Activate account")
                }
                .buttonStyle(BetweenSecondaryButtonStyle())
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BetweenTheme.accent)
                .frame(width: 32)
            Text(text)
                .font(BetweenFont.secondary())
        }
    }

    private var returningScreen: some View {
        authForm(
            title: "Welcome back",
            subtitle: "Use your VT email to sign in."
        ) {
            TextField("you@vt.edu", text: $viewModel.loginEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(12)
                .background(BetweenTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            SecureField("Password", text: $viewModel.loginPassword)
                .textContentType(.password)
                .padding(12)
                .background(BetweenTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            #if DEBUG
            Text("Demo: alex.hirsch@vt.edu · demo123")
                .font(BetweenFont.caption())
                .foregroundStyle(.tertiary)
            #endif

            Button {
                Task { await viewModel.loginReturning() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Signing in…" : "Sign in")
                }
            }
            .buttonStyle(BetweenPrimaryButtonStyle())
            .disabled(viewModel.loginEmail.isEmpty || viewModel.isLoading)
        }
    }

    private var newUserScreen: some View {
        authForm(
            title: "Activate your account",
            subtitle: "Enter the code from your welcome email."
        ) {
            TextField("you@vt.edu", text: $viewModel.loginEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(12)
                .background(BetweenTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            TextField("6-digit code", text: $viewModel.activationCode)
                .keyboardType(.numberPad)
                .padding(12)
                .background(BetweenTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            #if DEBUG
            Text("Demo code: 482910")
                .font(BetweenFont.caption())
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
            .buttonStyle(BetweenPrimaryButtonStyle())
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
                Button {
                    viewModel.authStep = .welcome
                    viewModel.errorMessage = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(BetweenFont.secondary())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(BetweenFont.screenTitle())
                        Text(subtitle)
                            .font(BetweenFont.secondary())
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 14) {
                        fields()
                    }

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(BetweenFont.caption())
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
        }
    }
}
