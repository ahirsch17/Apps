import SwiftUI

@main
struct SpeakFlowApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var conversation = ConversationController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(conversation)
                .tint(SF.teal)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var conversation: ConversationController

    var body: some View {
        Group {
            if settings.hasSeenWelcome {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .task {
            conversation.bind(settings)
            await conversation.prepareAudio()
        }
        .onChange(of: settings.language) { _, _ in
            conversation.bind(settings)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            CallHomeView(onNeedKey: { tab = 3 })
                .tabItem { Label("Call", systemImage: "phone.fill") }
                .tag(0)
            TextHomeView(onNeedKey: { tab = 3 })
                .tabItem { Label("Text", systemImage: "message.fill") }
                .tag(1)
            LearnHomeView()
                .tabItem { Label("Learn", systemImage: "flame.fill") }
                .tag(2)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(3)
        }
    }
}
