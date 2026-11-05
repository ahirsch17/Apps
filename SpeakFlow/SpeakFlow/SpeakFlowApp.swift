import SwiftUI
import UIKit

@main
struct SpeakFlowApp: App {
    init() {
        let ink = UIColor(red: 0.08, green: 0.08, blue: 0.07, alpha: 1)
        let brass = UIColor(red: 0.93, green: 0.76, blue: 0.38, alpha: 1)
        let tabFont = UIFont(name: "AvenirNextCondensed-DemiBold", size: 11) ?? .systemFont(ofSize: 11)
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = ink
        let normal: [NSAttributedString.Key: Any] = [.font: tabFont, .foregroundColor: UIColor.white.withAlphaComponent(0.55)]
        let selected: [NSAttributedString.Key: Any] = [.font: tabFont, .foregroundColor: brass]
        tab.stackedLayoutAppearance.normal.titleTextAttributes = normal
        tab.stackedLayoutAppearance.selected.titleTextAttributes = selected
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let navFont = UIFont(name: "AvenirNextCondensed-DemiBold", size: 13) ?? .systemFont(ofSize: 13)
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = ink
        nav.titleTextAttributes = [.font: navFont, .foregroundColor: brass]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

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

private struct TabIndexKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    var tabIndex: Int {
        get { self[TabIndexKey.self] }
        set { self[TabIndexKey.self] = newValue }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            PracticeHomeView()
                .tabItem { Label("Practice", systemImage: "mic.fill") }
                .tag(0)
            PathOverviewView()
                .tabItem { Label("Path", systemImage: "map.fill") }
                .tag(1)
            ProfileView()
                .tabItem { Label("You", systemImage: "person.crop.circle.fill") }
                .tag(2)
        }
        .environment(\.tabIndex, tab)
    }
}
