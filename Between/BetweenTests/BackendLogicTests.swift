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
        let db = try SeedDataLoader.loadFromBundle()
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
        let db = try SeedDataLoader.loadFromBundle()
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
}
