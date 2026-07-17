import SwiftUI

struct MainMenuView: View {
  @EnvironmentObject private var store: BluffLocationStore

  @State private var showRules = false

  var body: some View {
    ZStack {
      BackgroundView()

      ScrollView {
        VStack(spacing: 16) {
          VStack(spacing: 6) {
            Text("BluffLocation")
              .font(.largeTitle.bold())
              .foregroundStyle(.white)

            Text(store.isConnected ? "Connected" : "Disconnected")
              .font(.subheadline)
              .foregroundStyle(store.isConnected ? .green.opacity(0.9) : .white.opacity(0.75))
          }
          .padding(.top, 12)

          VStack(alignment: .leading, spacing: 10) {
            Text("Server URL")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.9))

            TextField("http://localhost:3000", text: $store.serverUrl)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .keyboardType(.URL)
              .padding(12)
              .background(Color.white.opacity(0.12))
              .cornerRadius(12)
              .foregroundStyle(.white)

            Text("Username")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.9))
              .padding(.top, 4)

            TextField("Alex", text: $store.userName)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .padding(12)
              .background(Color.white.opacity(0.12))
              .cornerRadius(12)
              .foregroundStyle(.white)
          }
          .card()

          VStack(spacing: 10) {
            NavigationLink {
              CreateGameView()
            } label: {
              PrimaryButtonLabel(title: "Create Game")
            }
            .buttonStyle(.plain)

            NavigationLink {
              JoinGameView()
            } label: {
              PrimaryButtonLabel(title: "Join Game")
            }
            .buttonStyle(.plain)

            PrimaryButton(title: "Rules") {
              showRules = true
            }
          }
          .buttonStyle(.plain)

          if let err = store.lastError, !err.isEmpty {
            Text(err)
              .font(.subheadline)
              .foregroundStyle(.red.opacity(0.9))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 12)
          }

          if let msg = store.lastServerMessage, !msg.isEmpty {
            Text(msg)
              .font(.subheadline)
              .foregroundStyle(.white.opacity(0.85))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 12)
          }
        }
        .padding(16)
      }
    }
    .sheet(isPresented: $showRules) {
      RulesView()
        .environmentObject(store)
    }
    .onAppear {
      // Keep it best-effort; the user can also tap actions which will call connect().
      if !store.serverUrl.isEmpty { store.connect() }
    }
  }
}

