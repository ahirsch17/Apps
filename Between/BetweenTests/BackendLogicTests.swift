import CryptoKit
import XCTest
@testable import Between

final class BackendLogicTests: XCTestCase {
    func testCourseHashDeterministic() {
        let a = CourseHashService.hash(canonicalCourseId: "CSE-1002", schoolId: "vt")
        let b = CourseHashService.hash(canonicalCourseId: "CSE-1002", schoolId: "vt")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, 64)
    }

    func testCourseHashDiffersBySchool() {
        let vt = CourseHashService.hash(canonicalCourseId: "CSE-1002", schoolId: "vt")
        let uva = CourseHashService.hash(canonicalCourseId: "CSE-1002", schoolId: "uva")
        XCTAssertNotEqual(vt, uva)
    }

    func testScheduleEngineFormatRange() {
        let label = ScheduleEngine.formatRange(start: 9 * 60, end: 10 * 60 + 50)
        XCTAssertTrue(label.contains("9 AM"))
        XCTAssertTrue(label.contains("10:50 AM"))
    }

    func testEventsBuilderCountsRealParticipantsOnly() throws {
        let db = try TestFixtures.seedDatabase()
        let profile = db.studentProfiles.first(where: { $0.studentId == "stu-alex" })
        let data = EventsBuilder.build(
            events: db.campusEvents,
            interests: db.interests,
            participations: db.eventParticipations,
            partnerProfiles: db.partnerProfiles,
            students: db.students,
            viewerId: "stu-alex",
            myInterestIds: profile?.interestIds ?? [],
            activeMode: nil,
            modeExpiresAt: nil,
            onboardingComplete: profile?.onboardingComplete ?? false
        )
        guard let vb = data.events.first(where: { $0.id == "evt-vb-im" }) else {
            return XCTFail("missing vb event")
        }
        let real = Set(db.eventParticipations.filter { $0.eventId == "evt-vb-im" }.map(\.studentId)).count
        XCTAssertEqual(vb.interestedCount, real)
        XCTAssertEqual(vb.interestedCount, 11)
    }

    func testEventsBuilderMutualOptIn() throws {
        let db = try TestFixtures.seedDatabase()
        let profile = db.studentProfiles.first(where: { $0.studentId == "stu-alex" })
        let before = EventsBuilder.build(
            events: db.campusEvents,
            interests: db.interests,
            participations: db.eventParticipations,
            partnerProfiles: db.partnerProfiles,
            students: db.students,
            viewerId: "stu-alex",
            myInterestIds: profile?.interestIds ?? [],
            activeMode: nil,
            modeExpiresAt: nil,
            onboardingComplete: profile?.onboardingComplete ?? false
        )
        let vbBefore = before.events.first(where: { $0.id == "evt-vb-im" })
        XCTAssertFalse(vbBefore?.canViewPartners ?? true)
    }

    func testShareFreeTimeHidesFriendOverlapFromViewer() throws {
        let db = try TestFixtures.seedDatabase()
        guard let me = db.students.first(where: { $0.id == "stu-alex" }) else {
            return XCTFail("missing alex")
        }
        let friendIds = DashboardBuilder.friendIds(for: me.id, friendships: db.friendships)
        guard let blockedFriend = friendIds.first else {
            return XCTFail("expected at least one friend")
        }

        var sharePrefs: [String: Set<String>] = [blockedFriend: []]

        let withoutBlock = DashboardBuilder.build(
            DashboardBuilder.Input(
                me: me,
                students: db.students,
                sections: db.sections,
                enrollments: db.enrollments,
                friendships: db.friendships,
                friendRequests: db.friendRequests,
                presenceByStudentId: Dictionary(uniqueKeysWithValues: db.presence.map { ($0.studentId, $0) }),
                plans: db.plans,
                syncTime: Date(),
                shareFreeTimeWithByStudentId: [:],
                myShareFreeTimeWith: friendIds
            )
        )
        let blockedOverlapIds = Set(
            withoutBlock.todayPlan.flatMap(\.friendOverlaps).map(\.friendId)
        )
        XCTAssertTrue(blockedOverlapIds.contains(blockedFriend))

        sharePrefs = [blockedFriend: []]
        let withBlock = DashboardBuilder.build(
            DashboardBuilder.Input(
                me: me,
                students: db.students,
                sections: db.sections,
                enrollments: db.enrollments,
                friendships: db.friendships,
                friendRequests: db.friendRequests,
                presenceByStudentId: Dictionary(uniqueKeysWithValues: db.presence.map { ($0.studentId, $0) }),
                plans: db.plans,
                syncTime: Date(),
                shareFreeTimeWithByStudentId: sharePrefs,
                myShareFreeTimeWith: friendIds
            )
        )
        let filteredIds = Set(withBlock.todayPlan.flatMap(\.friendOverlaps).map(\.friendId))
        XCTAssertFalse(filteredIds.contains(blockedFriend))
    }

    func testOverlapTimelinePicksTopStarredFriends() throws {
        let db = try TestFixtures.seedDatabase()
        guard let me = db.students.first(where: { $0.id == "stu-alex" }) else {
            return XCTFail("missing alex")
        }
        let friendIds = DashboardBuilder.friendIds(for: me.id, friendships: db.friendships)
        let dashboard = DashboardBuilder.build(
            DashboardBuilder.Input(
                me: me,
                students: db.students,
                sections: db.sections,
                enrollments: db.enrollments,
                friendships: db.friendships,
                friendRequests: db.friendRequests,
                presenceByStudentId: Dictionary(uniqueKeysWithValues: db.presence.map { ($0.studentId, $0) }),
                plans: db.plans,
                syncTime: Date(),
                shareFreeTimeWithByStudentId: [:],
                myShareFreeTimeWith: friendIds
            )
        )
        let starred = Set(friendIds.prefix(4))
        let board = OverlapTimelineModel.build(from: dashboard.todayPlan, starredIds: starred)
        XCTAssertLessThanOrEqual(board.friendRows.count, OverlapTimelineModel.maxFriendRows)
        XCTAssertFalse(board.classBlocks.isEmpty)
        for row in board.friendRows {
            XCTAssertFalse(row.overlapBlocks.isEmpty)
        }
    }

    func testUploadCourseHashesReturnsFriendConnections() async throws {
        let db = try TestFixtures.seedDatabase()
        let service = LocalBackendService(database: db)
        let session = AuthSession(userId: "stu-alex", email: "alex.hirsch@vt.edu", token: "test")
        guard let me = db.students.first(where: { $0.id == session.userId }) else {
            return XCTFail("missing alex")
        }
        let dashboard = try await service.refreshDashboard(session: session)
        let hashes = CourseHashService.hashSections(dashboard.mySections, schoolId: me.schoolId)
        XCTAssertFalse(hashes.isEmpty)

        let result = try await service.uploadCourseHashes(session: session, hashes: hashes)
        XCTAssertFalse(result.matches.isEmpty)
        let totalFriends = result.matches.reduce(0) { $0 + $1.friendConnections.count }
        XCTAssertGreaterThan(totalFriends, 0)
    }
}
