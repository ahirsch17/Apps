import SwiftUI

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @Binding var path: NavigationPath

    private var game: GameState? { store.game }
    private var me: Player? { store.viewingPlayer }

    var body: some View {
        BackgroundView(imageName: "OtherBackground", overlayOpacity: 0.5) {
            if let game, let me {
                ScrollView {
                    VStack(spacing: 12) {
                        header(game: game, me: me)
                        scoreRow(game: game)
                        viewingPicker(players: game.players)

                        GameBoardView(
                            cards: game.cards,
                            playerRole: me.role,
                            playerTeam: me.team,
                            votes: game.votes,
                            currentGuesses: game.currentGuesses,
                            onCardPress: { cardId in
                                if canGuess(game: game, me: me) {
                                    store.toggleGuess(cardId: cardId)
                                }
                            }
                        )
                        .padding(.vertical, 4)

                        if canGuess(game: game, me: me), !game.currentGuesses.isEmpty {
                            guessPanel(game: game)
                        }

                        cluePanel(game: game, me: me)
                        clueHistory(game: game)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            } else {
                VStack(spacing: 20) {
                    Text("No active game")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)
                    Button("Back to Lobby") {
                        path = NavigationPath()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func myTurn(game: GameState, me: Player) -> Bool {
        game.currentTurn == me.team
    }

    private func hasActiveClue(game: GameState, me: Player) -> Bool {
        guard let latest = game.latestClue else { return false }
        return latest.team == me.team
    }

    private func canGuess(game: GameState, me: Player) -> Bool {
        me.role == .decoder
            && myTurn(game: game, me: me)
            && hasActiveClue(game: game, me: me)
            && game.guessesRemaining > 0
            && !game.isGameOver
    }

    @ViewBuilder
    private func header(game: GameState, me: Player) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Current Turn:")
                        .foregroundStyle(.white)
                    Text(game.currentTurn.displayName)
                        .foregroundStyle(game.currentTurn == .red ? Theme.redTeam : Theme.blueTeam)
                        .fontWeight(.black)
                }
                .font(.system(size: 18, weight: .bold))

                Text("You: \(me.name) • \(me.team.displayName) • \(me.role.displayName)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    path.append(AppRoute.help)
                } label: {
                    Text("?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Theme.primary.opacity(0.9))
                        .clipShape(Circle())
                }

                if game.isGameOver {
                    Button("Results") {
                        path.append(AppRoute.results)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func scoreRow(game: GameState) -> some View {
        HStack(spacing: 12) {
            scoreCard(title: "Red Team", value: game.remaining.red, border: Theme.redTeam.opacity(0.5))
            scoreCard(title: "Blue Team", value: game.remaining.blue, border: Theme.blueTeam.opacity(0.5))
        }
    }

    private func scoreCard(title: String, value: Int, border: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("\(value)")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Theme.panelFill)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func viewingPicker(players: [Player]) -> some View {
        HStack {
            Text("Viewing as")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Menu {
                ForEach(players) { player in
                    Button("\(player.name) (\(player.team.displayName) \(player.role.displayName))") {
                        store.viewingPlayerId = player.id
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if let me = store.viewingPlayer {
                        Text("\(me.name)")
                            .fontWeight(.bold)
                        Text("• \(me.role.displayName)")
                            .foregroundStyle(Theme.textMuted)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 4)
    }

    private func guessPanel(game: GameState) -> some View {
        VStack(spacing: 10) {
            Text("Selected \(game.currentGuesses.count) card(s) • \(game.guessesRemaining) guess(es) remaining")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button("Reveal Selected Cards") {
                store.submitGuesses()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(Theme.success)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Theme.primary.opacity(0.3))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.primary.opacity(0.6), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func cluePanel(game: GameState, me: Player) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(me.role == .encoder ? "Give Clue" : "Current Clue")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)

            if me.role == .encoder {
                ClueInputView(
                    disabled: !myTurn(game: game, me: me) || game.isGameOver,
                    boardWords: game.cards.map(\.word)
                ) { word, number in
                    store.submitClue(word: word, number: number)
                }
            } else {
                VStack(spacing: 8) {
                    if let clue = game.latestClue, clue.team == me.team {
                        Text("\(clue.word) \(clue.number)")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(Theme.gold)
                        if canGuess(game: game, me: me) {
                            Text("Tap cards to select, then submit your guesses")
                                .font(.system(size: 13).italic())
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("Waiting for Encoder's clue...")
                            .font(.system(size: 15).italic())
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }

            if game.isGameOver {
                VStack(spacing: 10) {
                    Text("Game Over!")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(Theme.gold)
                    HStack(spacing: 4) {
                        Text("Winner:")
                            .foregroundStyle(.white)
                        Text("\(game.winner?.displayName ?? "") TEAM")
                            .foregroundStyle(game.winner == .red ? Theme.redTeam : Theme.blueTeam)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 18))

                    Button("Back to Lobby") {
                        path = NavigationPath()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 11)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            } else {
                Button(me.role == .encoder && !hasActiveClue(game: game, me: me) ? "Skip Turn" : "End Turn") {
                    store.endTurn()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(myTurn(game: game, me: me) ? Theme.success : Color.gray.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(!myTurn(game: game, me: me))
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 10)
        .background(Theme.panelFill)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelBorder))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func clueHistory(game: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clue History")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            if game.clues.isEmpty {
                Text("No clues yet. Encoders start giving clues!")
                    .font(.system(size: 14).italic())
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(Array(game.clues.reversed().prefix(10))) { clue in
                    HStack(spacing: 8) {
                        Text("\(clue.team.displayName):")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(clue.team == .red ? Theme.redTeam : Theme.blueTeam)
                        Text("\(clue.word) (\(clue.number))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.panelFill)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelBorder))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
