import Foundation
import Combine

final class SettingsStore: ObservableObject {
    private enum Keys {
        static let host = "deskpilot.host"
        static let port = "deskpilot.port"
        static let token = "deskpilot.token"
        static let trackpadSensitivity = "deskpilot.trackpadSensitivity"
        static let scrollSensitivity = "deskpilot.scrollSensitivity"
        static let tapToClick = "deskpilot.tapToClick"
        static let invertScroll = "deskpilot.invertScroll"
        static let haptics = "deskpilot.haptics"
        static let macAddress = "deskpilot.macAddress"
        static let wolBroadcast = "deskpilot.wolBroadcast"
    }

    @Published var host: String {
        didSet { UserDefaults.standard.set(host, forKey: Keys.host) }
    }

    @Published var port: Int {
        didSet { UserDefaults.standard.set(port, forKey: Keys.port) }
    }

    @Published var authToken: String? {
        didSet { UserDefaults.standard.set(authToken, forKey: Keys.token) }
    }

    @Published var trackpadSensitivity: Double {
        didSet { UserDefaults.standard.set(trackpadSensitivity, forKey: Keys.trackpadSensitivity) }
    }

    @Published var scrollSensitivity: Double {
        didSet { UserDefaults.standard.set(scrollSensitivity, forKey: Keys.scrollSensitivity) }
    }

    @Published var tapToClick: Bool {
        didSet { UserDefaults.standard.set(tapToClick, forKey: Keys.tapToClick) }
    }

    @Published var invertScroll: Bool {
        didSet { UserDefaults.standard.set(invertScroll, forKey: Keys.invertScroll) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var macAddress: String {
        didSet { UserDefaults.standard.set(macAddress, forKey: Keys.macAddress) }
    }

    @Published var wolBroadcast: String {
        didSet { UserDefaults.standard.set(wolBroadcast, forKey: Keys.wolBroadcast) }
    }

    var isPaired: Bool {
        authToken?.isEmpty == false
    }

    init() {
        let defaults = UserDefaults.standard
        host = defaults.string(forKey: Keys.host) ?? PCDefaults.host
        port = defaults.object(forKey: Keys.port) as? Int ?? PCDefaults.port
        authToken = defaults.string(forKey: Keys.token)
        trackpadSensitivity = defaults.object(forKey: Keys.trackpadSensitivity) as? Double ?? 1.6
        scrollSensitivity = defaults.object(forKey: Keys.scrollSensitivity) as? Double ?? 1.0
        tapToClick = defaults.object(forKey: Keys.tapToClick) as? Bool ?? true
        invertScroll = defaults.object(forKey: Keys.invertScroll) as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        macAddress = defaults.string(forKey: Keys.macAddress) ?? PCDefaults.macAddress
        wolBroadcast = defaults.string(forKey: Keys.wolBroadcast) ?? "255.255.255.255"
    }
}
