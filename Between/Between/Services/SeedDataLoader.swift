import Foundation

enum SeedDataLoader {
    static func loadFromBundle() throws -> SeedDatabase {
        guard let url = Bundle.main.url(forResource: "seed_data", withExtension: "json") else {
            throw BackendError.missingSeedData
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SeedDatabase.self, from: data)
    }
}
