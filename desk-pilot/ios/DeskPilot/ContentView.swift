import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        TabView {
            ControlView()
                .tabItem {
                    Label("Control", systemImage: "cursorarrow")
                }

            MediaView()
                .tabItem {
                    Label("Media", systemImage: "speaker.wave.2.fill")
                }

            PowerView()
                .tabItem {
                    Label("Power", systemImage: "power")
                }
        }
        .tint(AppTheme.accent)
        .task {
            await connection.bootstrap(settings: settings)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
