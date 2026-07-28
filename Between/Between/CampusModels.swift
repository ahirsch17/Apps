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
    /// Demo credibility: adds to real participation counts (campus-scale social proof).
    let promotedInterestedCount: Int
    let promotedPartnerCount: Int

    init(
        id: String, schoolId: String, interestId: String, title: String,
        description: String, location: String, startTime: Date, endTime: Date? = nil,
        promotedInterestedCount: Int = 0, promotedPartnerCount: Int = 0
    ) {
        self.id = id
        self.schoolId = schoolId
        self.interestId = interestId
        self.title = title
        self.description = description
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.promotedInterestedCount = promotedInterestedCount
        self.promotedPartnerCount = promotedPartnerCount
    }

    enum CodingKeys: String, CodingKey {
        case id, schoolId, interestId, title, description, location, startTime, endTime
        case promotedInterestedCount, promotedPartnerCount
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
        promotedInterestedCount = try c.decodeIfPresent(Int.self, forKey: .promotedInterestedCount) ?? 0
        promotedPartnerCount = try c.decodeIfPresent(Int.self, forKey: .promotedPartnerCount) ?? 0
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
    let isInterested: Bool
    let isLookingForPartner: Bool
    let canViewPartners: Bool
    let partnerProfiles: [PartnerSeekingProfile]
}

struct EventsData {
    let events: [CampusEventCard]
    let interests: [Interest]
    let myInterestIds: [String]
    let onboardingComplete: Bool
    let activeMode: ActivityMode?
    let modeExpiresAt: Date?
}
