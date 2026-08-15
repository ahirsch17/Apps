import Foundation

enum ConversationLevel: String, CaseIterable, Identifiable, Codable {
    case warmup
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var subtitle: String {
        switch self {
        case .warmup: return "Short answers. Present tense. No pressure."
        case .beginner: return "Everyday questions. Mostly present tense."
        case .intermediate: return "Past & future. Longer replies."
        case .advanced: return "Natural conversation. Opinions & stories."
        }
    }

    var rank: Int {
        switch self {
        case .warmup: return 0
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }

    var systemGuidance: String {
        switch self {
        case .warmup:
            return "Ask very simple questions requiring 1–5 word answers. Present tense only. Celebrate small wins. Offer fill-in phrases."
        case .beginner:
            return "Ask straightforward everyday questions. Focus on present tense. Help with transitions like because/but/also."
        case .intermediate:
            return "Natural back-and-forth using past, present, and future. Encourage 2–4 sentence answers and connectors."
        case .advanced:
            return "Fully natural conversation. Idioms, hypotheticals, nuanced opinions. Expect longer responses."
        }
    }
}
