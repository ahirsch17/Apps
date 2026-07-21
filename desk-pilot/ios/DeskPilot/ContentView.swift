import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TrackpadView()
                .tabItem {
                    Label("Trackpad", systemImage: "rectangle.on.rectangle.angled")
                }

            KeyboardView()
                .tabItem {
                    Label("Keyboard", systemImage: "keyboard")
                }

            MediaView()
                .tabItem {
                    Label("Media", systemImage: "speaker.wave.2.fill")
                }

            PowerView()
                .tabItem {
                    Label("Power", systemImage: "power")
                }

            ShortcutsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "square.grid.2x2")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
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
