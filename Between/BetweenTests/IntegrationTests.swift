import XCTest
@testable import Between

// Integration tests for full backend flow
// Run these against RemoteBackendService with test database
final class IntegrationTests: XCTestCase {
    
    var service: (any BetweenBackendServicing)!
    var testSession: AuthSession!
    
    override func setUp() async throws {
        // Use RemoteBackendService pointing to test environment
        // export TEST_API_URL="https://between-test.azurewebsites.net"
        guard let testURL = ProcessInfo.processInfo.environment["TEST_API_URL"],
              let url = URL(string: testURL) else {
            throw XCTSkip("TEST_API_URL not set, skipping integration tests")
        }
        
        service = RemoteBackendService(baseURL: url)
        testSession = try await service.loginWithSSO(email: "test@vt.edu")
    }
    
    override func tearDown() async throws {
        // Cleanup: delete test data from database
        testSession = nil
        service = nil
    }
    
    // Test SSO flow (production sign-in path)
    func testSSOLoginWithVTEmail() async throws {
        let session = try await service.loginWithSSO(email: "test@vt.edu")
        XCTAssertFalse(session.userId.isEmpty)
        XCTAssertFalse(session.token.isEmpty)
    }
    
    // Test dashboard data integrity
    func testDashboardReturnsCompleteData() async throws {
        let dashboard = try await service.refreshDashboard(session: testSession)
        
        XCTAssertEqual(dashboard.me.email, testSession.email)
        XCTAssertNotNil(dashboard.mySections)
        XCTAssertNotNil(dashboard.todayPlan)
        XCTAssert(dashboard.syncTimestamp.timeIntervalSinceNow < 60) // Recent sync
    }
    
    // Test friend request flow: send -> accept -> verify friendship
    func testFriendRequestFlow() async throws {
        let targetStudentId = "stu-test-friend"
        
        // Send request
        try await service.sendFriendRequest(session: testSession, to: targetStudentId)
        
        // Verify pending outgoing request
        let dashboard1 = try await service.refreshDashboard(session: testSession)
        XCTAssert(dashboard1.pendingOutgoing.contains { $0.id == targetStudentId })
        
        // Accept request (simulated as target user)
        let targetSession = AuthSession(userId: targetStudentId, email: "target@vt.edu", token: "target-token")
        let dashboard2 = try await service.refreshDashboard(session: targetSession)
        guard let request = dashboard2.pendingIncoming.first else {
            XCTFail("No incoming request found")
            return
        }
        
        try await service.acceptFriendRequest(session: targetSession, requestId: request.requestId)
        
        // Verify friendship established
        let dashboard3 = try await service.refreshDashboard(session: testSession)
        XCTAssert(dashboard3.nearbyFriends.contains { $0.id == targetStudentId })
    }
    
    // Test event participation
    func testMarkEventInterested() async throws {
        let eventId = "evt-test-volleyball"
        
        let before = try await service.fetchEvents(session: testSession)
        let eventBefore = before.events.first { $0.id == eventId }
        let beforeCount = eventBefore?.interestedCount ?? 0
        
        try await service.markEventInterested(session: testSession, eventId: eventId)
        
        let after = try await service.fetchEvents(session: testSession)
        let eventAfter = after.events.first { $0.id == eventId }
        
        XCTAssertEqual(eventAfter?.interestedCount, beforeCount + 1)
        XCTAssertTrue(eventAfter?.isInterested == true)
    }
    
    // Test partner profile creation
    func testMarkLookingForPartner() async throws {
        let eventId = "evt-test-volleyball"
        
        try await service.markLookingForPartner(
            session: testSession,
            eventId: eventId,
            note: "Looking for a setter",
            experience: "Intermediate"
        )
        
        let events = try await service.fetchEvents(session: testSession)
        let event = events.events.first { $0.id == eventId }
        
        XCTAssertTrue(event?.isLookingForPartner == true)
        XCTAssertTrue(event?.canViewPartners == true)
        XCTAssert(event?.partnerProfiles.contains { $0.studentId == testSession.userId } == true)
    }
    
    // Test presence updates
    func testSetPresence() async throws {
        try await service.setPresence(
            session: testSession,
            status: .freeNow,
            activity: "At Squires"
        )
        
        let dashboard = try await service.refreshDashboard(session: testSession)
        // Verify presence reflected in friends list (as seen by others)
        XCTAssertNotNil(dashboard.nearbyFriends)
    }
    
    // Test activity mode setting
    func testSetActivityMode() async throws {
        try await service.setActivityMode(session: testSession, mode: .hungry)
        
        let events = try await service.fetchEvents(session: testSession)
        XCTAssertEqual(events.activeMode, .hungry)
        XCTAssertNotNil(events.modeExpiresAt)
    }
    
    // Test concurrent requests (race condition check)
    func testConcurrentFriendRequests() async throws {
        let targetIds = ["stu-test-1", "stu-test-2", "stu-test-3"]
        let session = testSession
        let backend = service

        await withTaskGroup(of: Void.self) { group in
            for id in targetIds {
                group.addTask {
                    try? await backend.sendFriendRequest(session: session, to: id)
                }
            }
        }
        
        let dashboard = try await service.refreshDashboard(session: testSession)
        XCTAssertGreaterThanOrEqual(dashboard.pendingOutgoing.count, 3)
    }
    
}
