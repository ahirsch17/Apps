import SwiftUI

struct CreateGameView: View {
  @EnvironmentObject private var store: BluffLocationStore

  @State private var navigateToRoom = false

  var body: some View {
    ZStack {
      BackgroundView()

      VStack(spacing: 14) {
        VStack(alignment: .leading, spacing: 10) {
          Text("Create Game")
            .font(.title2.bold())
            .foregroundStyle(.white)

          Stepper(value: $store.timeLimitMinutes, in: 1...30) {
            Text("Time limit: \(store.timeLimitMinutes) min")
              .foregroundStyle(.white.opacity(0.9))
          }
          .tint(.white)
        }
        .card()

        PrimaryButton(title: "Create") {
          store.createGame()
          // Server will send room_created; we navigate once activeRoom is set.
        }

        if let room = store.activeRoom {
          Text("Room: \(room)")
            .foregroundStyle(.white)
            .font(.headline)
        }

        NavigationLink(isActive: $navigateToRoom) {
          GameRoomView()
        } label: {
          EmptyView()
        }
      }
      .padding(16)
    }
    .onChange(of: store.activeRoom) { newValue in
      navigateToRoom = (newValue != nil)
    }
  }
}

