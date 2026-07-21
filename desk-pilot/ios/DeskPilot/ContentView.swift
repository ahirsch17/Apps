import SwiftUI

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
