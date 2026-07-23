import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @AppStorage("between.hasSeenWelcome") private var hasSeenWelcome = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.05, green: 0.06, blue: 0.11), Color.black]
                    : [Color(red: 0.95, green: 0.97, blue: 1.00), Color(red: 0.89, green: 0.93, blue: 1.00)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $viewModel.selectedTab) {
                FriendsListView()
                    .tag(0)
                HomeMapView()
                    .tag(1)
                PlansView()
                    .tag(2)
            }
            .environmentObject(viewModel)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(alignment: .top) {
                PagerHeader(selectedTab: $viewModel.selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            if viewModel.me == nil {
                LoginOverlayView()
                    .environmentObject(viewModel)
            }

            if !hasSeenWelcome && viewModel.me != nil {
                WelcomeOverlayView {
                    hasSeenWelcome = true
                }
            }

            if let toast = viewModel.toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.82))
                        .clipShape(Capsule())
                        .padding(.bottom, 28)
                        .accessibilityAddTraits(.isStaticText)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35), value: viewModel.toastMessage)
            }
        }
        .fontDesign(.rounded)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .task {
            await viewModel.bootstrap()
        }
    }
}

private struct PagerHeader: View {
    @Binding var selectedTab: Int
    private let tabs = ["Friends", "Now", "Plans"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    Text(tabs[index])
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(index == selectedTab ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(index == selectedTab ? Color.white : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .frame(minHeight: 44)
                .accessibilityLabel("\(tabs[index]) tab")
                .accessibilityAddTraits(index == selectedTab ? [.isSelected] : [])
            }
        }
        .padding(6)
        .background(Color.primary.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main navigation")
    }
}

private struct WelcomeOverlayView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 20) {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 72)
                    .accessibilityLabel("Between logo")
                Text("Between")
                    .font(.largeTitle.weight(.bold))
                Text("Find time between classes with people you know.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Get started") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .tint(BetweenTheme.neonViolet)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .frame(maxWidth: 400)
            .padding(24)
            .glassCard()
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel.make())
}

private struct LoginOverlayView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180, maxHeight: 56)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Between logo")
                Text("Sign in")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Text("Demo account — uses local campus data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Account", selection: $viewModel.selectedEmail) {
                    ForEach(viewModel.candidates, id: \.id) { student in
                        Text("\(student.name) (\(student.email))").tag(student.email)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Choose demo account")

                Button {
                    Task { await viewModel.login() }
                } label: {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        Text(viewModel.isLoading ? "Signing in..." : "Sign in")
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedEmail.isEmpty || viewModel.isLoading)
                .accessibilityLabel("Sign in to Between")

                if let message = viewModel.errorMessage {
                    Text(message).font(.caption).foregroundStyle(.red)
                }
            }
            .frame(maxWidth: 520)
            .padding(18)
            .glassCard()
            .padding(.horizontal, 18)
        }
    }
}
