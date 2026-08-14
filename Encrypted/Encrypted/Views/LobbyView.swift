import SwiftUI

struct LobbyView: View {
    @EnvironmentObject private var store: GameStore
    @Binding var path: NavigationPath
    @State private var confirmNewGame = false

    private var hasActiveGame: Bool {
        if let game = store.game { return !game.isGameOver }
        return false
    }

    var body: some View {
        BackgroundView(imageName: "MainBackground", overlayOpacity: 0.5) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 24) {
                    Spacer()

                    Text("ENCRYPTED")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.9), radius: 4, x: 2, y: 2)
                        .tracking(4)

                    Text("Advanced mobile Codenames-style play—secret words, one-word clues, and deduction")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)

                    VStack(spacing: 14) {
                        Button {
                            if hasActiveGame {
                                confirmNewGame = true
                            } else {
                                startNewGame()
                            }
                        } label: {
                            Text(store.game == nil ? "Start Game" : "New Game")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                        }

                        if hasActiveGame {
                            Button {
                                path.append(AppRoute.game)
                            } label: {
                                Text("Continue Game")
                                    .font(.system(size: 22, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.secondary)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)

                    Spacer()
                }

                Button {
                    path.append(AppRoute.help)
                } label: {
                    Text("How to Play")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.primary.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                }
                .padding(.top, 12)
                .padding(.trailing, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Start a new game? Current game will be lost.",
            isPresented: $confirmNewGame,
            titleVisibility: .visible
        ) {
            Button("Start New Game", role: .destructive) { startNewGame() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func startNewGame() {
        store.resetGame()
        path.append(AppRoute.setup)
    }
}
