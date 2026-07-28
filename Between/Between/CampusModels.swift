import Foundation

// MARK: - Activity modes

enum ActivityMode: String, Codable, CaseIterable, Identifiable {
    case quiet
    case hungry
    case study
    case gym
    case sports
    case social

    var id: String { rawValue }

    var label: String {
        switch self {
        case .quiet: return "Quiet time"
        case .hungry: return "Hungry"
        case .study: return "Study"
        case .gym: return "Gym"
        case .sports: return "Sports"
        case .social: return "Social"
        }
    }

    var icon: String {
        switch self {
        case .quiet: return "moon.fill"
        case .hungry: return "fork.knife"
        case .study: return "book.fill"
        case .gym: return "figure.strengthtraining.traditional"
        case .sports: return "sportscourt.fill"
        case .social: return "person.3.fill"
        }
    }

    var encouragement: String {
        switch self {
        case .quiet: return "Taking time for yourself — you won't appear in match lists."
        case .hungry: return "Friends who are also hungry will show up."
        case .study: return "Find friends studying nearby."
        case .gym: return "See who's heading to the gym."
        case .sports: return "Match with pickup games and IM events."
        case .social: return "Open to hanging out on campus."
        }
    }

    /// Default mode duration in seconds.
    var defaultDuration: TimeInterval {
        switch self {
        case .quiet: return 2 * 3600
        case .hungry: return 3600
        case .study: return 2 * 3600
        case .gym: return 5400
        case .sports: return 5400
        case .social: return 3600
        }
    }

    var presenceStatus: PresenceStatus {
        switch self {
        case .quiet: return .busy
        case .hungry, .social: return .freeNow
        case .study: return .studying
        case .gym, .sports: return .onTheWay
        }
    }
}

// MARK: - Event matching (partner vs newcomer vs none)

enum EventMatchingKind: String, Codable, CaseIterable {
    case partner
    case newcomer
    case none

    var seekingShortLabel: String {
        switch self {
        case .partner: return "need a partner"
        case .newcomer: return "new to this"
        case .none: return ""
        }
    }

    var seekingStatLabel: String {
        switch self {
        case .partner: return "need a partner"
        case .newcomer: return "don't know anyone"
        case .none: return ""
        }
    }

    var optInTitle: String {
        switch self {
        case .partner: return "Looking for a partner?"
        case .newcomer: return "Don't know anyone going?"
        case .none: return ""
        }
    }

    var optInButton: String {
        switch self {
        case .partner: return "I'm looking for a partner"
        case .newcomer: return "I'm new — want to meet people"
        case .none: return ""
        }
    }

    var privacyNote: String {
        switch self {
        case .partner:
            return "Partner profiles stay private until you opt in too. Only other seekers see your note."
        case .newcomer:
            return "Nobody sees that you're new unless you opt in. Then you only see others who opted in too."
        case .none:
            return ""
        }
    }

    var seekersSectionTitle: String {
        switch self {
        case .partner: return "Others looking for a partner"
        case .newcomer: return "Others who don't know anyone"
        case .none: return ""
        }
    }
}

// MARK: - Interests & events (seed + API)

struct Interest: Codable, Identifiable, Hashable {
    let id: String
    let schoolId: String
    let name: String
    let icon: String
}

struct StudentProfile: Codable, Hashable {
    let studentId: String
    var interestIds: [String]
    var onboardingComplete: Bool
}

struct CampusEvent: Codable, Identifiable, Hashable {
    let id: String
    let schoolId: String
    let interestId: String
    let title: String
    let description: String
    let location: String
    let startTime: Date
    let endTime: Date?
    let matchingKind: EventMatchingKind
    let isRecurring: Bool
    let recurrenceLabel: String?

    init(
        id: String, schoolId: String, interestId: String, title: String,
        description: String, location: String, startTime: Date, endTime: Date? = nil,
        matchingKind: EventMatchingKind = .partner,
        isRecurring: Bool = false,
        recurrenceLabel: String? = nil
    ) {
        self.id = id
        self.schoolId = schoolId
        self.interestId = interestId
        self.title = title
        self.description = description
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.matchingKind = matchingKind
        self.isRecurring = isRecurring
        self.recurrenceLabel = recurrenceLabel
    }

    enum CodingKeys: String, CodingKey {
        case id, schoolId, interestId, title, description, location, startTime, endTime
        case matchingKind, isRecurring, recurrenceLabel
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        schoolId = try c.decode(String.self, forKey: .schoolId)
        interestId = try c.decode(String.self, forKey: .interestId)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        location = try c.decode(String.self, forKey: .location)
        startTime = try c.decode(Date.self, forKey: .startTime)
        endTime = try c.decodeIfPresent(Date.self, forKey: .endTime)
        matchingKind = try c.decodeIfPresent(EventMatchingKind.self, forKey: .matchingKind) ?? .partner
        isRecurring = try c.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        recurrenceLabel = try c.decodeIfPresent(String.self, forKey: .recurrenceLabel)
    }
}

enum EventParticipationKind: String, Codable {
    case interested
    case lookingForPartner
}

struct EventParticipation: Codable, Hashable {
    let eventId: String
    let studentId: String
    let kind: EventParticipationKind
}

struct PartnerSeekingProfile: Codable, Identifiable, Hashable {
    let studentId: String
    let eventId: String
    let displayName: String
    let year: String
    let experienceNote: String
    let lookingNote: String
    let socialHandle: String?

    var id: String { "\(eventId)-\(studentId)" }
}

// MARK: - App-facing event cards

struct CampusEventCard: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let location: String
    let timeLabel: String
    let interestName: String
    let interestIcon: String
    let interestedCount: Int
    let partnerSeekingCount: Int
    let matchingKind: EventMatchingKind
    let recurrenceLabel: String?
    let isInterested: Bool
    let isLookingForPartner: Bool
    let canViewPartners: Bool
    let partnerProfiles: [PartnerSeekingProfile]

    var showsMatching: Bool { matchingKind != .none && partnerSeekingCount > 0 }
}

struct EventsData {
    let events: [CampusEventCard]
    let interests: [Interest]
    let myInterestIds: [String]
    let onboardingComplete: Bool
    let activeMode: ActivityMode?
    let modeExpiresAt: Date?
}
