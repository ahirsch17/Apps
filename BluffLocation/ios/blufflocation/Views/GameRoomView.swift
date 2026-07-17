import SwiftUI

struct GameRoomView: View {
  @EnvironmentObject private var store: BluffLocationStore

  @State private var voteFor: String = ""
  @State private var guessLocation: String = ""

  var body: some View {
    ZStack {
      BackgroundView()

      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Room")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.85))

            Text(store.activeRoom ?? "—")
              .font(.title.bold())
              .foregroundStyle(.white)

            if let host = store.host, !host.isEmpty {
              Text("Host: \(host)")
                .foregroundStyle(.white.opacity(0.85))
            }
          }
          .card()

          VStack(alignment: .leading, spacing: 10) {
            Text("You")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.85))

            if let role = store.role {
              Text("Role: \(role)")
                .foregroundStyle(.white)
                .font(.headline)
            } else {
              Text("Role: (waiting)")
                .foregroundStyle(.white.opacity(0.75))
            }

            if let location = store.location, !location.isEmpty {
              Text("Location: \(location)")
                .foregroundStyle(.white)
                .font(.subheadline)
            }
          }
          .card()

          VStack(alignment: .leading, spacing: 10) {
            Text("Players (\(store.players.count))")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.85))

            ForEach(store.players) { player in
              Text(player.name)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.10))
                .cornerRadius(10)
            }
          }
          .card()

          VStack(spacing: 10) {
            PrimaryButton(title: "Start Game") {
              store.startGame()
            }

            PrimaryButton(title: "Sync State") {
              store.syncState()
            }

            PrimaryButton(title: "Leave Room") {
              store.leaveGame()
            }
          }

          VStack(alignment: .leading, spacing: 10) {
            Text("Vote Spy")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.85))

            TextField("Vote for username", text: $voteFor)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .padding(12)
              .background(Color.white.opacity(0.12))
              .cornerRadius(12)
              .foregroundStyle(.white)

            PrimaryButton(title: "Submit Vote", isDisabled: voteFor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
              store.voteSpy(voteFor: voteFor.trimmingCharacters(in: .whitespacesAndNewlines))
            }
          }
          .card()

          VStack(alignment: .leading, spacing: 10) {
            Text("Spy Guess")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.85))

            TextField("Guess location", text: $guessLocation)
              .textInputAutocapitalization(.words)
              .autocorrectionDisabled()
              .padding(12)
              .background(Color.white.opacity(0.12))
              .cornerRadius(12)
              .foregroundStyle(.white)

            PrimaryButton(title: "Submit Guess", isDisabled: guessLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
              store.guessLocation(guessLocation.trimmingCharacters(in: .whitespacesAndNewlines))
            }
          }
          .card()

          if let err = store.lastError, !err.isEmpty {
            Text(err)
              .font(.subheadline)
              .foregroundStyle(.red.opacity(0.9))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 12)
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Game")
    .navigationBarTitleDisplayMode(.inline)
  }
}

