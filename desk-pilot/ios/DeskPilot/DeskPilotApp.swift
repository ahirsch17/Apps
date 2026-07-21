import SwiftUI
import UIKit

@main
struct DeskPilotApp: App {
    @StateObject private var connection = ConnectionManager()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connection)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
                .task {
                    await connection.bootstrap(settings: settings)
                }
        }
    }
}
