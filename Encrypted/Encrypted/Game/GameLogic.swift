import Foundation

enum ClueValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var message: String {
        if case .invalid(let message) = self { return message }
        return ""
    }
}

enum GameLogic {
    private static let allowedLowercase: Set<String> = [
        "a", "an", "the", "and", "or", "but", "of", "in", "on", "at", "to", "for", "with"
    ]

    static func shuffle<T>(_ array: [T]) -> [T] {
        var a = array
        guard a.count > 1 else { return a }
        for i in stride(from: a.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            a.swapAt(i, j)
        }
        return a
    }

    static func initializeGame(
        players: [Player],
        settings: GameSettings,
        usedWords: inout Set<String>
    ) -> GameState {
        var available = WordBank.words.filter { !usedWords.contains($0) }
        if available.count < 25 {
            usedWords.removeAll()
            available = WordBank.words
        }

        let pool = available.count >= 25 ? available : WordBank.words
        let selectedWords = Array(shuffle(pool).prefix(25))

        var cards: [GameCard] = selectedWords.enumerated().map { index, word in
            GameCard(
                id: "card_\(index)",
                word: word,
                type: .neutral,
                revealed: false,
                position: CardPosition(row: index / 5, col: index % 5)
            )
        }

        var cardTypes: [CardType] =
            Array(repeating: .red, count: 9) +
            Array(repeating: .blue, count: 8) +
            [.assassin] +
            Array(repeating: .neutral, count: 7)
        cardTypes = shuffle(cardTypes)

        for i in cards.indices {
            cards[i].type = cardTypes[i]
        }

        let firstTeam: TeamColor = Bool.random() ? .red : .blue
        selectedWords.forEach { usedWords.insert($0) }

        return GameState(
            id: "game_\(Int(Date().timeIntervalSince1970 * 1000))",
            players: players,
            cards: cards,
            currentTurn: firstTeam,
            clues: [],
            remaining: RemainingCounts(red: 9, blue: 8),
            isGameOver: false,
            winner: nil,
            settings: settings,
            votes: [:],
            currentGuesses: [],
            guessesRemaining: 0,
            roundNumber: 1
        )
    }

    static func validateClue(word: String, number: Int, boardWords: [String] = []) -> ClueValidationResult {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .invalid("Clue word is required")
        }
        if trimmed.count == 1 {
            return .invalid("Clue cannot be a single letter")
        }

        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if parts.count > 1 {
            let capitalizedCount = parts.filter { $0.first?.isUppercase == true }.count
            let lowercaseAllowed = parts.filter { allowedLowercase.contains($0.lowercased()) }.count
            if capitalizedCount + lowercaseAllowed < parts.count {
                return .invalid("Multi-word clues should be proper names (capitalize first letters)")
            }
        }

        let clueUpper = trimmed.uppercased()
        let containsBoardWord = boardWords.contains { boardWord in
            let boardUpper = boardWord.uppercased()
            return clueUpper.contains(boardUpper) || boardUpper.contains(clueUpper)
        }
        if containsBoardWord {
            return .invalid("Clue cannot contain or be part of any word on the board")
        }

        if number < 1 || number > 9 {
            return .invalid("Number must be between 1 and 9")
        }

        return .valid
    }
}
