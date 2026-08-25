import Foundation
import SwiftUI

enum Language: String, CaseIterable, Identifiable, Codable {
    case spanish = "es", german = "de", italian = "it", tagalog = "fil"
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
    var localeID: String {
        switch self {
        case .spanish: return "es-ES"
        case .german: return "de-DE"
        case .italian: return "it-IT"
        case .tagalog: return "fil-PH"
        }
    }
    var langLabel: String {
        switch self {
        case .spanish: return "Spanish (español)"
        case .german: return "German (Deutsch)"
        case .italian: return "Italian (italiano)"
        case .tagalog: return "Tagalog (Filipino)"
        }
    }
}

struct TutorCharacter: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let language: Language
    let vibe: String
    let colorHex: UInt

    var color: Color { Color(hex: colorHex) }

    static func forLanguage(_ language: Language) -> TutorCharacter {
        all.first { $0.language == language } ?? all[0]
    }

    static let all: [TutorCharacter] = [
        .init(id: "maria", name: "María", emoji: "👩‍🎤", language: .spanish, vibe: "Warm, funny, patient — keeps you talking.", colorHex: 0x0D9488),
        .init(id: "anna", name: "Anna", emoji: "👩‍💼", language: .german, vibe: "Clear, encouraging, a little dry humor.", colorHex: 0x2563EB),
        .init(id: "giulia", name: "Giulia", emoji: "👩‍🎨", language: .italian, vibe: "Expressive, lively, celebrates every try.", colorHex: 0xE11D48),
        .init(id: "maya", name: "Maya", emoji: "👩‍🚀", language: .tagalog, vibe: "Friendly, chill, keeps things light.", colorHex: 0xEA580C)
    ]
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
