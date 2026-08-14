import SwiftUI

struct JoinGameView: View {
  @EnvironmentObject private var store: BluffLocationStore

  @State private var roomCode: String = ""
  @State private var navigateToRoom = false

  var body: some View {
    ZStack {
      BackgroundView()

      VStack(spacing: 14) {
        VStack(alignment: .leading, spacing: 10) {
          Text("Join Game")
            .font(.title2.bold())
            .foregroundStyle(.white)

          TextField("Room code", text: $roomCode)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color.white.opacity(0.12))
            .cornerRadius(12)
            .foregroundStyle(.white)
        }
        .card()

        PrimaryButton(title: "Join", isDisabled: roomCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
          store.joinGame(room: roomCode.trimmingCharacters(in: .whitespacesAndNewlines))
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

