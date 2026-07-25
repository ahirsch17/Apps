import SwiftUI

enum PCDefaults {
    static let pcName = "DESKTOP-FCHFL42"
    static let host = "192.168.12.154"
    static let port = 8765
    static let macAddress = "08:F9:7E:38:6C:F4"
    static let pairPIN = "717077"

    static let netflixApp = "Netflix"
    static let primeVideoApp = "Prime Video"
}

struct StreamingApp: Identifiable {
    let id: String
    let title: String
    let launchName: String
    let icon: String
    let accent: Color

    static let catalog: [StreamingApp] = [
        StreamingApp(
            id: "netflix",
            title: "Netflix",
            launchName: PCDefaults.netflixApp,
            icon: "play.tv.fill",
            accent: AppTheme.netflix
        ),
        StreamingApp(
            id: "prime",
            title: "Prime Video",
            launchName: PCDefaults.primeVideoApp,
            icon: "film.fill",
            accent: AppTheme.primeVideo
        ),
    ]
}
