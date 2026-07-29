import XCTest
@testable import Between

final class LocalBackendServiceTests: XCTestCase {
    func testMarkEventInterestedIncrementsRealCount() async throws {
        let db = try TestFixtures.seedDatabase()
        let service = LocalBackendService(database: db)
        let session = AuthSession(userId: "stu-alex", email: "alex.hirsch@vt.edu", token: "test")

        let before = try await service.fetchEvents(session: session)
        let vbBefore = before.events.first(where: { $0.id == "evt-vb-im" })
        XCTAssertEqual(vbBefore?.interestedCount, 11)
        XCTAssertEqual(vbBefore?.isInterested, false)

        try await service.markEventInterested(session: session, eventId: "evt-vb-im")

        let after = try await service.fetchEvents(session: session)
        let vbAfter = after.events.first(where: { $0.id == "evt-vb-im" })
        XCTAssertEqual(vbAfter?.interestedCount, 12)
        XCTAssertEqual(vbAfter?.isInterested, true)
    }

    func testMarkEventInterestedRejectsUnenrolledStudent() async throws {
        let db = try TestFixtures.seedDatabase()
        let service = LocalBackendService(database: db)
        let session = AuthSession(userId: "stu-sug-00", email: "emerson.clark@vt.edu", token: "test")

        do {
            try await service.markEventInterested(session: session, eventId: "evt-vb-im")
            XCTFail("expected invalidRequest for unenrolled student")
        } catch let error as BackendError {
            if case .invalidRequest = error {
                // expected
            } else {
                XCTFail("unexpected BackendError: \(error)")
            }
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
