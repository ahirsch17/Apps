import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel(service: {
        do {
            return try LocalBackendService.live()
        } catch {
            fatalError("Failed to bootstrap local backend: \(error)")
        }
    }())
    @State private var page = 0
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

            TabView(selection: $page) {
                HomeMapView()
                    .tag(0)
                FriendsListView()
                    .tag(1)
                PlansView()
                    .tag(2)
            }
            .environmentObject(viewModel)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(alignment: .top) {
                PagerHeader(page: $page)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            if viewModel.me == nil {
                LoginOverlayView()
                    .environmentObject(viewModel)
            }
        }
        .fontDesign(.rounded)
        .task {
            await viewModel.bootstrap()
        }
    }
}

private struct PagerHeader: View {
    @Binding var page: Int
    private let tabs = ["Friends", "Now", "Plans"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        page = index
                    }
                } label: {
                    Text(tabs[index])
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(index == page ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(index == page ? Color.white : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(6)
        .background(Color.primary.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}

private struct LoginOverlayView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text("Local Pipeline Login")
                    .font(.title2.weight(.bold))
                Text("Select a seeded @vt.edu user to test login, friend requests, and class matching.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Account", selection: $viewModel.selectedEmail) {
                    ForEach(viewModel.candidates, id: \.id) { student in
                        Text("\(student.name) (\(student.email))").tag(student.email)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    Task { await viewModel.login() }
                } label: {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        Text(viewModel.isLoading ? "Logging in..." : "Login")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedEmail.isEmpty || viewModel.isLoading)

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
