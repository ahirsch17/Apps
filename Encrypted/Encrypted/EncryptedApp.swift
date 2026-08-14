import SwiftUI

@main
struct EncryptedApp: App {
    @StateObject private var store = GameStore()
    @State private var path = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                LobbyView(path: $path)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .setup:
                            GameSetupView(path: $path)
                        case .game:
                            GameView(path: $path)
                        case .results:
                            ResultsView(path: $path)
                        case .help:
                            HelpView()
                        }
                    }
            }
            .environmentObject(store)
            .preferredColorScheme(.dark)
        }
    }
}

enum AppRoute: Hashable {
    case setup
    case game
    case results
    case help
}
