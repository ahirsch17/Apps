import SwiftUI

@main
struct SpeakFlowApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var vocabulary = VocabularyStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(vocabulary)
                .tint(SFTheme.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        if settings.hasSeenWelcome {
            ContentView()
        } else {
            WelcomeView()
        }
    }
}
