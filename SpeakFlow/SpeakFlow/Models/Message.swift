import Foundation

enum MessageRole: String, Codable {
    case user, tutor, system
}

struct Correction: Identifiable, Codable, Equatable {
    let id: UUID
    let type: CorrectionType
    let original: String
    let corrected: String
    let explanation: String

    init(
        id: UUID = UUID(),
        type: CorrectionType,
        original: String,
        corrected: String,
        explanation: String
    ) {
        self.id = id
        self.type = type
        self.original = original
        self.corrected = corrected
        self.explanation = explanation
    }
}

enum CorrectionType: String, Codable, CaseIterable {
    case grammar, tense, vocabulary, englishLeak, pronunciation

    var label: String {
        switch self {
        case .grammar: return "Grammar"
        case .tense: return "Tense"
        case .vocabulary: return "Word choice"
        case .englishLeak: return "English → target"
        case .pronunciation: return "Pronunciation"
        }
    }

    var icon: String {
        switch self {
        case .grammar: return "text.book.closed"
        case .tense: return "clock.arrow.circlepath"
        case .vocabulary: return "character.book.closed"
        case .englishLeak: return "arrow.left.arrow.right"
        case .pronunciation: return "waveform"
        }
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let text: String
    let corrections: [Correction]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String,
        corrections: [Correction] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.corrections = corrections
        self.createdAt = createdAt
    }
}
