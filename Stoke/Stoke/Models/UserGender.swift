import Foundation

enum UserGender: String, Codable, CaseIterable, Identifiable {
    case woman
    case man

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .woman: return "Woman"
        case .man: return "Man"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case veryLow
    case sedentary
    case light
    case moderate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .veryLow: return "Mostly seated"
        case .sedentary: return "A few short walks"
        case .light: return "Walk most days"
        case .moderate: return "Move most days"
        }
    }

    var suggestedWeeklyTarget: Int {
        switch self {
        case .veryLow: return 40
        case .sedentary: return 52
        case .light: return 68
        case .moderate: return 90
        }
    }
}
