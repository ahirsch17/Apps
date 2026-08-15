import Foundation

enum Language: String, CaseIterable, Identifiable, Codable {
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case tagalog = "fil"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spanish: return "Spanish"
        case .german: return "German"
        case .italian: return "Italian"
        case .tagalog: return "Tagalog"
        }
    }

    var flag: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .tagalog: return "🇵🇭"
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .spanish: return "es-ES"
        case .german: return "de-DE"
        case .italian: return "it-IT"
        case .tagalog: return "fil-PH"
        }
    }

    var tutorName: String {
        switch self {
        case .spanish: return "María"
        case .german: return "Anna"
        case .italian: return "Giulia"
        case .tagalog: return "Maya"
        }
    }

    var languageInstruction: String {
        switch self {
        case .spanish: return "Spanish (español)"
        case .german: return "German (Deutsch)"
        case .italian: return "Italian (italiano)"
        case .tagalog: return "Tagalog (Filipino)"
        }
    }
}
