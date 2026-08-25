import Foundation

enum ConversationLevel: String, CaseIterable, Identifiable, Codable {
    case warmup, beginner, intermediate, advanced
    var id: String { rawValue }
    var title: String {
        switch self {
        case .warmup: return "Warm-up"
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    var blurb: String {
        switch self {
        case .warmup: return "Short answers. Zero pressure."
        case .beginner: return "Everyday chat. Present tense."
        case .intermediate: return "Stories, past & future."
        case .advanced: return "Real talk. Opinions & nuance."
        }
    }
    var guidance: String {
        switch self {
        case .warmup: return "Very simple questions, 1–5 word answers, present only. Celebrate tries."
        case .beginner: return "Everyday questions, mostly present. Help with because/but/also."
        case .intermediate: return "Past/present/future. 2–4 sentence answers. Follow-ups."
        case .advanced: return "Natural conversation, idioms, hypotheticals."
        }
    }
}

enum ConversationTopic: String, CaseIterable, Identifiable, Codable {
    case freeform, dailyLife, food, travel, work, family, hobbies, feelings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .freeform: return "Whatever"
        case .dailyLife: return "Daily life"
        case .food: return "Food"
        case .travel: return "Travel"
        case .work: return "Work / school"
        case .family: return "People"
        case .hobbies: return "Hobbies"
        case .feelings: return "Feelings"
        }
    }
    var icon: String {
        switch self {
        case .freeform: return "sparkles"
        case .dailyLife: return "sun.max.fill"
        case .food: return "fork.knife"
        case .travel: return "airplane"
        case .work: return "briefcase.fill"
        case .family: return "person.2.fill"
        case .hobbies: return "gamecontroller.fill"
        case .feelings: return "heart.fill"
        }
    }
}

enum MessageRole: String, Codable { case user, tutor, system }

struct Correction: Identifiable, Codable, Equatable {
    let id: UUID
    let type: String
    let original: String
    let corrected: String
    let explanation: String
    init(id: UUID = UUID(), type: String, original: String, corrected: String, explanation: String) {
        self.id = id; self.type = type; self.original = original; self.corrected = corrected; self.explanation = explanation
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let text: String
    let corrections: [Correction]
    let createdAt: Date
    init(id: UUID = UUID(), role: MessageRole, text: String, corrections: [Correction] = [], createdAt: Date = .init()) {
        self.id = id; self.role = role; self.text = text; self.corrections = corrections; self.createdAt = createdAt
    }
}

struct TutorTurn: Codable {
    let reply: String
    let corrections: [CorrectionPayload]?
    let starters: [String]?
    let shouldWrapUp: Bool?
    let encouragement: String?

    struct CorrectionPayload: Codable {
        let type: String
        let original: String
        let corrected: String
        let explanation: String
        func asCorrection() -> Correction {
            Correction(type: type, original: original, corrected: corrected, explanation: explanation)
        }
    }
}

struct CallReport: Codable, Identifiable {
    var id: UUID = UUID()
    let summary: String
    let strengths: [String]
    let focusNext: [String]
    let keyPhrases: [String]
    let scoreLabel: String

    enum CodingKeys: String, CodingKey {
        case summary, strengths, focusNext, keyPhrases, scoreLabel
    }
}
