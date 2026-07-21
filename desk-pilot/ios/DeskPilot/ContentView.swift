import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ControlView()
                    .tag(0)
                    .tabItem {
                        Label("Control", systemImage: "cursorarrow")
                    }

                MediaView()
                    .tag(1)
                    .tabItem {
                        Label("Media", systemImage: "speaker.wave.2.fill")
                    }

                PowerView()
                    .tag(2)
                    .tabItem {
                        Label("Power", systemImage: "power")
                    }
            }
            .tint(AppTheme.accent)

            TypingOverlay()
        }
        .task {
            await connection.bootstrap(settings: settings)
        }
        .onChange(of: connection.keyboardFocusRequestID) { _, _ in
            selectedTab = 0
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
