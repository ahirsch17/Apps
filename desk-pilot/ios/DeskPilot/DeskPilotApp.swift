import SwiftUI
import UIKit

@main
struct DeskPilotApp: App {
    @StateObject private var connection = ConnectionManager()
    @StateObject private var settings = SettingsStore()

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppTheme.backgroundElevated)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connection)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
    }
}
