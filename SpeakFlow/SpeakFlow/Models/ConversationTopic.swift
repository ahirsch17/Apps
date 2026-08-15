import Foundation

enum ConversationTopic: String, CaseIterable, Identifiable, Codable {
    case freeform, dailyLife, food, travel, work, family, hobbies, shopping, health, opinions

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .freeform: return "Free conversation"
        case .dailyLife: return "Daily life"
        case .food: return "Food & dining"
        case .travel: return "Travel"
        case .work: return "Work & school"
        case .family: return "Family & friends"
        case .hobbies: return "Hobbies"
        case .shopping: return "Shopping"
        case .health: return "Health & feelings"
        case .opinions: return "Opinions"
        }
    }

    var icon: String {
        switch self {
        case .freeform: return "bubble.left.and.bubble.right"
        case .dailyLife: return "sun.max"
        case .food: return "fork.knife"
        case .travel: return "airplane"
        case .work: return "briefcase"
        case .family: return "person.2"
        case .hobbies: return "paintpalette"
        case .shopping: return "bag"
        case .health: return "heart"
        case .opinions: return "lightbulb"
        }
    }

    var tutorGuidance: String {
        switch self {
        case .freeform: return "Pick natural everyday topics. Follow the learner's interests."
        case .dailyLife: return "Routines: morning, workday, evening, weekends, weather, habits."
        case .food: return "Meals, restaurants, cooking, preferences, ordering food."
        case .travel: return "Trips, directions, hotels, airports, sightseeing, plans."
        case .work: return "Jobs, classes, meetings, coworkers, deadlines, goals."
        case .family: return "Relatives, friends, relationships, celebrations."
        case .hobbies: return "Sports, music, reading, games, free time."
        case .shopping: return "Stores, prices, clothing, markets, online orders."
        case .health: return "How you feel, sleep, exercise, stress — keep it light."
        case .opinions: return "Ask for opinions and reasons. Practice agreement/disagreement phrases."
        }
    }
}
