import Foundation
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var game: GameState?
    @Published var localPlayers: [Player] = []
    @Published var settings: GameSettings = .default
    @Published var usedWords: Set<String> = []
    @Published var viewingPlayerId: String?

    var viewingPlayer: Player? {
        guard let game else { return nil }
        if let id = viewingPlayerId,
           let player = game.players.first(where: { $0.id == id }) {
            return player
        }
        return game.players.first(where: { $0.isHost }) ?? game.players.first
    }

    func initializeNewGame(players: [Player], settings: GameSettings) {
        var used = usedWords
        let newGame = GameLogic.initializeGame(players: players, settings: settings, usedWords: &used)
        game = newGame
        localPlayers = players
        self.settings = settings
        usedWords = used
        viewingPlayerId = players.first?.id
    }

    func submitClue(word: String, number: Int) {
        guard var game, !game.isGameOver else { return }

        let clue = Clue(
            word: word.uppercased(),
            number: number,
            team: game.currentTurn,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        game.clues.append(clue)
        game.guessesRemaining = number + 1
        game.currentGuesses = []
        self.game = game
    }

    func toggleGuess(cardId: String) {
        guard var game, !game.isGameOver else { return }
        if let index = game.currentGuesses.firstIndex(of: cardId) {
            game.currentGuesses.remove(at: index)
        } else {
            game.currentGuesses.append(cardId)
        }
        self.game = game
    }

    func submitGuesses() {
        guard var game, !game.isGameOver, !game.currentGuesses.isEmpty else { return }

        var continueGuessing = true
        let selected = game.currentGuesses

        for cardId in selected {
            guard let cardIndex = game.cards.firstIndex(where: { $0.id == cardId }) else { continue }
            let card = game.cards[cardIndex]
            if card.revealed { continue }

            game.cards[cardIndex].revealed = true

            if card.type == .red {
                game.remaining.red = max(0, game.remaining.red - 1)
            }
            if card.type == .blue {
                game.remaining.blue = max(0, game.remaining.blue - 1)
            }

            if card.type == .assassin {
                game.isGameOver = true
                game.winner = game.currentTurn.opposite
                continueGuessing = false
            } else if game.remaining.red == 0 {
                game.isGameOver = true
                game.winner = .red
                continueGuessing = false
            } else if game.remaining.blue == 0 {
                game.isGameOver = true
                game.winner = .blue
                continueGuessing = false
            } else if card.type != CardType(team: game.currentTurn) {
                continueGuessing = false
            }

            game.guessesRemaining = max(0, game.guessesRemaining - 1)

            if !continueGuessing || game.isGameOver { break }
        }

        if !continueGuessing || game.guessesRemaining == 0 {
            game.currentTurn = game.currentTurn.opposite
            game.currentGuesses = []
            game.guessesRemaining = 0
        } else {
            game.currentGuesses = []
        }

        self.game = game
    }

    func endTurn() {
        guard var game, !game.isGameOver else { return }
        game.currentTurn = game.currentTurn.opposite
        game.votes = [:]
        game.currentGuesses = []
        game.guessesRemaining = 0
        self.game = game
    }

    func resetGame() {
        game = nil
        localPlayers = []
        settings = .default
        usedWords = []
        viewingPlayerId = nil
    }
}
