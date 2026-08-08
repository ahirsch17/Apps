import Foundation

struct SeedDatabase: Codable {
    let generatedAt: Date
    let universities: [University]
    let sections: [CourseSection]
    let students: [Student]
    let enrollments: [Enrollment]
    let friendships: [Friendship]
    let friendRequests: [FriendRequest]
    let presence: [PresenceRecord]
    let plans: [Plan]
    let interests: [Interest]
    let studentProfiles: [StudentProfile]
    let campusEvents: [CampusEvent]
    let eventParticipations: [EventParticipation]
    let partnerProfiles: [PartnerSeekingProfile]

    init(
        generatedAt: Date,
        universities: [University],
        sections: [CourseSection],
        students: [Student],
        enrollments: [Enrollment],
        friendships: [Friendship],
        friendRequests: [FriendRequest],
        presence: [PresenceRecord],
        plans: [Plan],
        interests: [Interest] = [],
        studentProfiles: [StudentProfile] = [],
        campusEvents: [CampusEvent] = [],
        eventParticipations: [EventParticipation] = [],
        partnerProfiles: [PartnerSeekingProfile] = []
    ) {
        self.generatedAt = generatedAt
        self.universities = universities
        self.sections = sections
        self.students = students
        self.enrollments = enrollments
        self.friendships = friendships
        self.friendRequests = friendRequests
        self.presence = presence
        self.plans = plans
        self.interests = interests
        self.studentProfiles = studentProfiles
        self.campusEvents = campusEvents
        self.eventParticipations = eventParticipations
        self.partnerProfiles = partnerProfiles
    }

    enum CodingKeys: String, CodingKey {
        case generatedAt, universities, sections, students, enrollments
        case friendships, friendRequests, presence, plans
        case interests, studentProfiles, campusEvents, eventParticipations, partnerProfiles
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try c.decode(Date.self, forKey: .generatedAt)
        universities = try c.decode([University].self, forKey: .universities)
        sections = try c.decode([CourseSection].self, forKey: .sections)
        students = try c.decode([Student].self, forKey: .students)
        enrollments = try c.decode([Enrollment].self, forKey: .enrollments)
        friendships = try c.decode([Friendship].self, forKey: .friendships)
        friendRequests = try c.decode([FriendRequest].self, forKey: .friendRequests)
        presence = try c.decode([PresenceRecord].self, forKey: .presence)
        plans = try c.decode([Plan].self, forKey: .plans)
        interests = try c.decodeIfPresent([Interest].self, forKey: .interests) ?? []
        studentProfiles = try c.decodeIfPresent([StudentProfile].self, forKey: .studentProfiles) ?? []
        campusEvents = try c.decodeIfPresent([CampusEvent].self, forKey: .campusEvents) ?? []
        eventParticipations = try c.decodeIfPresent([EventParticipation].self, forKey: .eventParticipations) ?? []
        partnerProfiles = try c.decodeIfPresent([PartnerSeekingProfile].self, forKey: .partnerProfiles) ?? []
    }
}

struct University: Codable, Identifiable {
    let id: String
    let name: String
    let emailDomain: String
    let timezone: String
}

struct CourseSection: Codable, Identifiable, Hashable {
    let sectionId: String
    let canonicalCourseId: String
    let courseCode: String
    let courseName: String
    let sectionLabel: String
    let meetingDays: [String]
    let startTime: String
    let endTime: String
    let location: String

    var id: String { sectionId }
}

struct Student: Codable, Identifiable, Hashable {
    struct Privacy: Codable, Hashable {
        let shareSchedule: String
        let shareClassDetails: Bool
    }

    let id: String
    let name: String
    let email: String
    let schoolId: String
    let year: String
    let major: String
    let privacy: Privacy
    let phoneNumber: String?
    let suggestedVia: String?

    init(
        id: String,
        name: String,
        email: String,
        schoolId: String,
        year: String,
        major: String,
        privacy: Privacy,
        phoneNumber: String? = nil,
        suggestedVia: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.schoolId = schoolId
        self.year = year
        self.major = major
        self.privacy = privacy
        self.phoneNumber = phoneNumber
        self.suggestedVia = suggestedVia
    }

    /// Dashboard/API layer only — never persisted on student rows in seed data.
    func withSuggestedVia(_ suggestedVia: String?) -> Student {
        Student(
            id: id,
            name: name,
            email: email,
            schoolId: schoolId,
            year: year,
            major: major,
            privacy: privacy,
            phoneNumber: phoneNumber,
            suggestedVia: suggestedVia
        )
    }
}

struct IncomingFriendRequest: Identifiable, Hashable {
    let requestId: String
    let from: Student

    var id: String { requestId }
}

struct Enrollment: Codable, Hashable {
    let studentId: String
    let sectionId: String
}

struct Friendship: Codable, Hashable {
    let studentA: String
    let studentB: String
    let status: String
}

struct FriendRequest: Codable, Identifiable, Hashable {
    let id: String
    let fromStudentId: String
    let toStudentId: String
    var status: String
    let createdAt: Date
}

enum PresenceStatus: String, Codable, CaseIterable, Hashable {
    case freeNow
    case onTheWay
    case studying
    case busy

    var label: String {
        switch self {
        case .freeNow: return "Free now"
        case .onTheWay: return "On the way"
        case .studying: return "Studying"
        case .busy: return "Busy"
        }
    }
}

struct PresenceRecord: Codable, Identifiable, Hashable {
    var id: String { studentId }
    let studentId: String
    var status: PresenceStatus
    var activity: String
    var location: String
    var lastUpdated: Date
}

struct Plan: Codable, Identifiable, Hashable {
    let id: String
    let creatorId: String
    let type: String
    let title: String
    let location: String
    let startTime: Date
    let visibility: String
}

// App-facing view models from service layer
struct FriendCard: Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let avatarEmoji: String
    let status: PresenceStatus
    let activity: String
    let location: String
    let distanceLabel: String
}

struct ClassConnection: Identifiable, Hashable, Codable {
    enum Kind: String, Hashable, Codable {
        case sameSection
        case differentSection

        var label: String {
            switch self {
            case .sameSection: return "Same section"
            case .differentSection: return "Different section"
            }
        }
    }

    let id: String
    let courseCode: String
    let courseName: String
    let friendName: String
    let kind: Kind
    let sectionLabel: String
    let meetingDays: [String]
}

struct OverlapInterval: Hashable, Sendable {
    let start: Int
    let end: Int
}

struct FriendOverlap: Identifiable {
    let id: String
    let friendId: String
    let friendName: String
    let intervals: [OverlapInterval]
    let totalMinutes: Int

    var longestIntervalMinutes: Int {
        intervals.map { $0.end - $0.start }.max() ?? 0
    }

    var overlapRangeLabel: String {
        guard let best = intervals.max(by: { ($0.end - $0.start) < ($1.end - $1.start) }) else { return "" }
        return ScheduleEngine.formatRange(start: best.start, end: best.end)
    }

    func firstName() -> String {
        friendName.components(separatedBy: " ").first ?? friendName
    }
}

struct FriendTimelineSegment: Identifiable {
    let id: String
    let friendId: String
    let friendName: String
    let startMinutes: Int
    let endMinutes: Int

    var durationMinutes: Int { endMinutes - startMinutes }
}

struct TodayPlanItem: Identifiable {
    enum Kind: String {
        case classBlock
        case freeBlock
    }

    let id: String
    let kind: Kind
    let startMinutes: Int
    let endMinutes: Int
    let section: CourseSection?
    let friendOverlaps: [FriendOverlap]

    var durationMinutes: Int { endMinutes - startMinutes }

    var timeRangeLabel: String {
        ScheduleEngine.formatRange(start: startMinutes, end: endMinutes)
    }

    var isHighlightableFreeBlock: Bool {
        kind == .freeBlock && durationMinutes >= ScheduleEngine.minFreeBlockMinutes
    }

    func starredOverlaps(starredIds: Set<String>, minMinutes: Int = ScheduleEngine.minOverlapMinutes) -> [FriendOverlap] {
        friendOverlaps.filter { overlap in
            starredIds.contains(overlap.friendId) && overlap.longestIntervalMinutes >= minMinutes
        }
    }

    // All meaningful overlaps (not gated on starred friends)
    func qualifyingOverlaps(minMinutes: Int = ScheduleEngine.minOverlapMinutes) -> [FriendOverlap] {
        friendOverlaps.filter { $0.longestIntervalMinutes >= minMinutes }
    }

    func segments(for starredIds: Set<String>) -> [FriendTimelineSegment] {
        starredOverlaps(starredIds: starredIds).flatMap { overlap in
            overlap.intervals
                .filter { $0.end - $0.start >= ScheduleEngine.minOverlapMinutes }
                .map { interval in
                    FriendTimelineSegment(
                        id: "\(overlap.friendId)-\(interval.start)",
                        friendId: overlap.friendId,
                        friendName: overlap.friendName,
                        startMinutes: interval.start,
                        endMinutes: interval.end
                    )
                }
        }
    }
}

extension SeedDatabase: @unchecked Sendable {}

struct DashboardData {
    let me: Student
    var nearbyFriends: [FriendCard]
    let classConnections: [ClassConnection]
    let mySections: [CourseSection]
    let pendingIncoming: [IncomingFriendRequest]
    let pendingOutgoing: [Student]
    let suggestedStudents: [Student]
    let plans: [Plan]
    let todayPlan: [TodayPlanItem]
    let syncTimestamp: Date
    /// Friend IDs this user shares overlap visibility with (server source of truth).
    let shareFreeTimeWith: [String]
}

struct CourseHashMatch: Codable, Hashable {
    let hash: String
    let classmateCount: Int
    let friendConnections: [ClassConnection]
}

struct CourseHashSyncResult: Hashable {
    let matches: [CourseHashMatch]
}

struct SpontaneousPlan: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let friendId: String
    let icon: String
}

// MARK: - Sendable (cross-actor backend calls)

extension University: Sendable {}
extension CourseSection: Sendable {}
extension Student: Sendable {}
extension Student.Privacy: Sendable {}
extension IncomingFriendRequest: Sendable {}
extension Enrollment: Sendable {}
extension Friendship: Sendable {}
extension FriendRequest: Sendable {}
extension PresenceStatus: Sendable {}
extension PresenceRecord: Sendable {}
extension Plan: Sendable {}
extension FriendCard: Sendable {}
extension ClassConnection: Sendable {}
extension ClassConnection.Kind: Sendable {}
extension FriendOverlap: Sendable {}
extension FriendTimelineSegment: Sendable {}
extension TodayPlanItem: Sendable {}
extension TodayPlanItem.Kind: Sendable {}
extension DashboardData: Sendable {}
extension CourseHashMatch: Sendable {}
extension CourseHashSyncResult: Sendable {}
extension SpontaneousPlan: Sendable {}
