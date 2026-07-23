import Foundation

/// Pure domain logic for assembling dashboard view data from raw store records.
/// Shared conceptually with the server; local backend uses this in-process.
enum DashboardBuilder {
    private static let avatarEmojis = ["🙂", "😎", "🤓", "🧠", "🏃", "☕", "📚", "🎧", "✨", "🌟", "🦉", "🔥"]

    struct Input {
        let me: Student
        let students: [Student]
        let sections: [CourseSection]
        let enrollments: [Enrollment]
        let friendships: [Friendship]
        let friendRequests: [FriendRequest]
        let presenceByStudentId: [String: PresenceRecord]
        let plans: [Plan]
        let syncTime: Date
    }

    static func build(_ input: Input) -> DashboardData {
        let friendIds = friendIds(for: input.me.id, friendships: input.friendships)
        let sectionById = Dictionary(uniqueKeysWithValues: input.sections.map { ($0.sectionId, $0) })

        let nearbyFriends: [FriendCard] = input.students
            .filter { friendIds.contains($0.id) }
            .compactMap { student in
                guard let presence = input.presenceByStudentId[student.id] else { return nil }
                return FriendCard(
                    id: student.id,
                    name: student.name,
                    email: student.email,
                    avatarEmoji: avatarEmoji(for: student),
                    status: presence.status,
                    activity: presence.activity,
                    location: presence.location,
                    distanceLabel: ["2 min walk", "5 min walk", "8 min walk", "12 min walk"].randomElement()!
                )
            }
            .sorted { $0.name < $1.name }

        let mySectionIds = Set(input.enrollments.filter { $0.studentId == input.me.id }.map(\.sectionId))
        let mySections = mySectionIds.compactMap { sectionById[$0] }
        let myByCanonical = Dictionary(grouping: mySections, by: \.canonicalCourseId)

        let classConnections: [ClassConnection] = nearbyFriends.compactMap { friend in
            let friendSections = Set(input.enrollments.filter { $0.studentId == friend.id }.map(\.sectionId))
            let overlaps = friendSections.compactMap { sectionById[$0] }.filter { myByCanonical[$0.canonicalCourseId] != nil }
            guard let matched = overlaps.first else { return nil }
            let myMatch = myByCanonical[matched.canonicalCourseId]?.first
            let kind: ClassConnection.Kind = myMatch?.sectionId == matched.sectionId ? .sameSection : .differentSection
            return ClassConnection(
                id: "\(friend.id)-\(matched.canonicalCourseId)",
                courseCode: matched.courseCode,
                courseName: matched.courseName,
                friendName: friend.name,
                kind: kind,
                sectionLabel: kind == .sameSection
                    ? "Section \(matched.sectionLabel)"
                    : "Sec \(myMatch?.sectionLabel ?? "--") vs \(matched.sectionLabel)",
                meetingDays: matched.meetingDays
            )
        }

        let incoming = input.friendRequests.filter { $0.toStudentId == input.me.id && $0.status == "pending" }
        let outgoing = input.friendRequests.filter { $0.fromStudentId == input.me.id && $0.status == "pending" }
        let pendingIncoming = incoming.compactMap { req -> IncomingFriendRequest? in
            guard let student = input.students.first(where: { $0.id == req.fromStudentId }) else { return nil }
            return IncomingFriendRequest(requestId: req.id, from: student)
        }
        let pendingOutgoing = outgoing.compactMap { req in input.students.first(where: { $0.id == req.toStudentId }) }

        let blockedIds = friendIds
            .union([input.me.id])
            .union(Set(pendingOutgoing.map(\.id)))
            .union(Set(pendingIncoming.map(\.from.id)))

        let suggestedStudents = input.students
            .filter { !blockedIds.contains($0.id) }
            .sorted { lhs, rhs in
                let lhsContact = lhs.suggestedVia == "contacts"
                let rhsContact = rhs.suggestedVia == "contacts"
                if lhsContact != rhsContact { return lhsContact }
                return lhs.name < rhs.name
            }

        let friendSectionsById = Dictionary(uniqueKeysWithValues: friendIds.compactMap { friendId -> (String, [CourseSection])? in
            let ids = Set(input.enrollments.filter { $0.studentId == friendId }.map(\.sectionId))
            let sections = ids.compactMap { sectionById[$0] }
            return sections.isEmpty ? nil : (friendId, sections)
        })
        let friendNamesById = Dictionary(uniqueKeysWithValues: nearbyFriends.map { ($0.id, $0.name) })
        let todayPlan = ScheduleEngine.buildTodayPlan(
            mySections: mySections,
            friendSectionsById: friendSectionsById,
            friendNamesById: friendNamesById
        )

        let visiblePlans = input.plans
            .filter { $0.creatorId == input.me.id || friendIds.contains($0.creatorId) }
            .sorted { $0.startTime < $1.startTime }

        return DashboardData(
            me: input.me,
            nearbyFriends: nearbyFriends,
            classConnections: classConnections,
            mySections: mySections.sorted { $0.courseCode < $1.courseCode },
            pendingIncoming: pendingIncoming,
            pendingOutgoing: pendingOutgoing,
            suggestedStudents: suggestedStudents,
            plans: visiblePlans,
            todayPlan: todayPlan,
            syncTimestamp: input.syncTime
        )
    }

    static func friendIds(for studentId: String, friendships: [Friendship]) -> Set<String> {
        Set(friendships.compactMap { relation -> String? in
            guard relation.status == "accepted" else { return nil }
            if relation.studentA == studentId { return relation.studentB }
            if relation.studentB == studentId { return relation.studentA }
            return nil
        })
    }

    private static func avatarEmoji(for student: Student) -> String {
        avatarEmojis[abs(student.id.hashValue) % avatarEmojis.count]
    }
}
