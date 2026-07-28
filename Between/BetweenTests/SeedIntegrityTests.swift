import XCTest

final class SeedIntegrityTests: XCTestCase {
    func testSeedJSONLoadsAndHasEnrolledEventParticipants() throws {
        let url = seedJSONURL()
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let students = json["students"] as! [[String: Any]]
        let enrollments = json["enrollments"] as! [[String: Any]]
        let parts = json["eventParticipations"] as! [[String: Any]]

        let studentIds = Set(students.compactMap { $0["id"] as? String })
        let enrolled = Set(enrollments.compactMap { $0["studentId"] as? String })

        for p in parts {
            let sid = p["studentId"] as! String
            XCTAssertTrue(studentIds.contains(sid), "\(sid) must exist")
            XCTAssertTrue(enrolled.contains(sid), "\(sid) must have enrollments")
        }

        let vb = Set(parts.filter { ($0["eventId"] as! String) == "evt-vb-im" }.map { $0["studentId"] as! String })
        XCTAssertEqual(vb.count, 11)
    }

    private func seedJSONURL() -> URL {
        // BetweenTests/BetweenTests/ -> repo Between/Resources/seed_data.json
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Between/Resources/seed_data.json")
    }
}
