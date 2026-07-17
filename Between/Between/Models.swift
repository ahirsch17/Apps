import Foundation

struct SeedDatabase: Codable {
    let generatedAt: Date
    let universities: [University]
    let sections: [Section]
    let students: [Student]
    let enrollments: [Enrollment]
    let friendships: [Friendship]
    let friendRequests: [FriendRequest]
    let presence: [PresenceRecord]
    let plans: [Plan]
}

struct University: Codable, Identifiable {
    let id: String
    let name: String
    let emailDomain: String
    let timezone: String
}

struct Section: Codable, Identifiable {
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

enum PresenceStatus: String, Codable, CaseIterable {
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

struct ClassConnection: Identifiable, Hashable {
    enum Kind: String, Hashable {
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

struct DashboardData {
    let me: Student
    let nearbyFriends: [FriendCard]
    let classConnections: [ClassConnection]
    let mySections: [Section]
    let pendingIncomingRequests: [Student]
    let pendingOutgoingRequests: [Student]
    let suggestedStudents: [Student]
    let plans: [Plan]
    let syncTimestamp: Date
}
