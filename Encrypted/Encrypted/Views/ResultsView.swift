import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var store: GameStore
    @Binding var path: NavigationPath

    var body: some View {
        BackgroundView(imageName: "OtherBackground", overlayOpacity: 0.6) {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Game Results")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.9), radius: 3, x: 1, y: 1)
                        .padding(.top, 8)

                    if let game = store.game {
                        if game.isGameOver {
                            VStack(spacing: 8) {
                                Text("Winner")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Theme.gold)
                                Text("\(game.winner?.displayName ?? "") TEAM")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundStyle(game.winner == .red ? Theme.redTeam : Theme.blueTeam)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(Theme.gold.opacity(0.2))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.gold, lineWidth: 3))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Final Score")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Theme.textSecondary)

                            HStack(spacing: 12) {
                                finalScoreCard(
                                    title: "Red Team",
                                    value: game.remaining.red,
                                    border: Theme.redTeam.opacity(0.5)
                                )
                                finalScoreCard(
                                    title: "Blue Team",
                                    value: game.remaining.blue,
                                    border: Theme.blueTeam.opacity(0.5)
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Teams")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Theme.textSecondary)

                            teamCard(
                                title: "Red Team",
                                color: Theme.redTeam,
                                players: game.players.filter { $0.team == .red }
                            )
                            teamCard(
                                title: "Blue Team",
                                color: Theme.blueTeam,
                                players: game.players.filter { $0.team == .blue }
                            )
                        }

                        if !game.clues.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Clue History")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Theme.textSecondary)

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(game.clues.reversed())) { clue in
                                        HStack(spacing: 10) {
                                            Text("\(clue.team.displayName):")
                                                .font(.system(size: 14, weight: .black))
                                                .foregroundStyle(clue.team == .red ? Theme.redTeam : Theme.blueTeam)
                                                .frame(width: 50, alignment: .leading)
                                            Text("\(clue.word) (\(clue.number))")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.panelFill)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelBorder))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    } else {
                        Text("No game data available")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(30)
                            .background(Theme.panelFill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(spacing: 12) {
                        if let game = store.game, !game.isGameOver {
                            Button("Back to Game") {
                                if !path.isEmpty { path.removeLast() }
                            }
                            .buttonStyle(ResultsPrimaryButtonStyle(color: Theme.primary))
                        }

                        Button("Back to Lobby") {
                            path = NavigationPath()
                        }
                        .buttonStyle(ResultsPrimaryButtonStyle(color: Theme.secondary))
                    }
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func finalScoreCard(title: String, value: Int, border: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("\(value)")
                .font(.system(size: 36, weight: .black))
                .foregroundStyle(.white)
            Text("cards remaining")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Theme.panelFill)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func teamCard(title: String, color: Color, players: [Player]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(color)

            ForEach(players) { player in
                HStack {
                    Text(player.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(player.role == .encoder ? "Encoder" : "Decoder")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panelFill)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelBorder))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ResultsPrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.45), radius: 5, y: 3)
    }
}
