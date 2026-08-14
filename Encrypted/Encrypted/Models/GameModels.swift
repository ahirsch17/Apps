import Foundation

enum TeamColor: String, Codable, CaseIterable, Identifiable, Hashable {
    case red
    case blue

    var id: String { rawValue }

    var displayName: String { rawValue.uppercased() }

    var opposite: TeamColor {
        self == .red ? .blue : .red
    }
}

enum CardType: String, Codable, Hashable {
    case red
    case blue
    case neutral
    case assassin

    init(team: TeamColor) {
        switch team {
        case .red: self = .red
        case .blue: self = .blue
        }
    }

    var asTeam: TeamColor? {
        switch self {
        case .red: return .red
        case .blue: return .blue
        default: return nil
        }
    }
}

enum PlayerRole: String, Codable, CaseIterable, Identifiable, Hashable {
    case encoder
    case decoder

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .encoder: return "Encoder"
        case .decoder: return "Decoder"
        }
    }
}

struct Player: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var team: TeamColor
    var role: PlayerRole
    var isHost: Bool
}

struct CardPosition: Codable, Hashable {
    var row: Int
    var col: Int
}

struct GameCard: Identifiable, Codable, Hashable {
    var id: String
    var word: String
    var type: CardType
    var revealed: Bool
    var position: CardPosition
}

enum AssignmentMode: String, Codable {
    case random
    case choose
    case rotate
}

struct GameSettings: Codable, Hashable {
    var useTimer: Bool
    var encoderTimer: Int
    var decoderTimer: Int
    var teamAssignment: AssignmentMode
    var roleAssignment: AssignmentMode

    static let `default` = GameSettings(
        useTimer: false,
        encoderTimer: 60,
        decoderTimer: 60,
        teamAssignment: .choose,
        roleAssignment: .choose
    )
}

struct Clue: Identifiable, Codable, Hashable {
    var id: String { "\(timestamp)_\(word)_\(number)" }
    var word: String
    var number: Int
    var team: TeamColor
    var timestamp: String
}

struct RemainingCounts: Codable, Hashable {
    var red: Int
    var blue: Int
}

struct GameState: Identifiable {
    var id: String
    var players: [Player]
    var cards: [GameCard]
    var currentTurn: TeamColor
    var clues: [Clue]
    var remaining: RemainingCounts
    var isGameOver: Bool
    var winner: TeamColor?
    var settings: GameSettings
    var votes: [String: [String]]
    var currentGuesses: [String]
    var guessesRemaining: Int
    var roundNumber: Int

    var latestClue: Clue? { clues.last }

    func latestClue(for team: TeamColor) -> Clue? {
        clues.last { $0.team == team }
    }
}
