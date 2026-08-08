import Foundation

/// One row from the user's address book (device or simulated fixture).
struct DeviceContactEntry: Codable, Hashable, Sendable {
    let displayName: String
    let phoneNumber: String
}

/// Abstraction over iOS Contacts. Production: `CNContactStore`; local demo: bundled JSON.
protocol DeviceContactsProviding: Sendable {
    /// Normalized entries the signed-in user has on their phone.
    func fetchContacts(forOwnerStudentId ownerId: String) async throws -> [DeviceContactEntry]
}

/// Bundled fixture — simulates Alex's address book. Not mixed into `seed_data.json`.
enum SimulatedDeviceContactsProvider: DeviceContactsProviding {
    private struct Fixture: Codable {
        let ownerStudentId: String
        let contacts: [DeviceContactEntry]
    }

    static func loadFixtureFromBundle() throws -> Fixture {
        guard let url = Bundle.main.url(forResource: "simulated_device_contacts", withExtension: "json") else {
            throw ContactsProviderError.missingFixture
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Fixture.self, from: data)
    }

    func fetchContacts(forOwnerStudentId ownerId: String) async throws -> [DeviceContactEntry] {
        let fixture = try Self.loadFixtureFromBundle()
        guard fixture.ownerStudentId == ownerId else { return [] }
        return fixture.contacts
    }
}

/// Placeholder for real Contacts.framework integration.
struct SystemDeviceContactsProvider: DeviceContactsProviding {
    func fetchContacts(forOwnerStudentId ownerId: String) async throws -> [DeviceContactEntry] {
        _ = ownerId
        // TODO: request CNContactStore authorization and map phone numbers.
        return []
    }
}

enum ContactsProviderError: Error {
    case missingFixture
}
