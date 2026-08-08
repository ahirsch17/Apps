import Foundation

/// Demo-only credentials and simulation knobs. Not used when `BackendConfiguration.mode` is remote.
/// Production auth comes from SSO / server policy — nothing here ships to real users.
enum LocalDemoConfiguration {
    struct PresenceSimulation: Codable, Sendable {
        let activities: [String]
        let locations: [String]
    }

    private struct ConfigFile: Codable, Sendable {
        let demoPassword: String
        let activationCode: String
        let loginCandidateLimit: Int
        let walkDistanceLabels: [String]
        let presenceSimulation: PresenceSimulation
    }

    private static let loaded: ConfigFile = {
        guard let url = Bundle.main.url(forResource: "local_demo_config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ConfigFile.self, from: data)
        else {
            assertionFailure("local_demo_config.json missing from bundle")
            return ConfigFile(
                demoPassword: "",
                activationCode: "",
                loginCandidateLimit: 12,
                walkDistanceLabels: ["Nearby"],
                presenceSimulation: PresenceSimulation(activities: ["Free"], locations: ["Campus"])
            )
        }
        return file
    }()

    static var demoPassword: String { loaded.demoPassword }
    static var activationCode: String { loaded.activationCode }
    static var loginCandidateLimit: Int { loaded.loginCandidateLimit }
    static var walkDistanceLabels: [String] { loaded.walkDistanceLabels }
    static var presenceSimulation: PresenceSimulation { loaded.presenceSimulation }
}
