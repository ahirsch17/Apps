import Foundation
@testable import Sparq

enum TestFixtures {
    static func seedDatabase() throws -> SeedDatabase {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sparq/Resources/seed_data.json")
        return try SeedDataLoader.load(from: url)
    }
}
