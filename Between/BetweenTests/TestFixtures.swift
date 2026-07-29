import Foundation
@testable import Between

enum TestFixtures {
    static func seedDatabase() throws -> SeedDatabase {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Between/Resources/seed_data.json")
        return try SeedDataLoader.load(from: url)
    }
}
