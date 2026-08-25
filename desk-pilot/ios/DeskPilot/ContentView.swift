import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ConnectionBanner()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                TabView(selection: $selectedTab) {
                    ControlView()
                        .tag(0)
                        .tabItem {
                            Label("Control", systemImage: "cursorarrow.rays")
                        }

                    MediaView()
                        .tag(1)
                        .tabItem {
                            Label("Media", systemImage: "play.tv")
                        }

                    PowerView()
                        .tag(2)
                        .tabItem {
                            Label("Power", systemImage: "power.circle")
                        }
                }
                .tint(AppTheme.accent)
            }

            TypingOverlay()
        }
        .task {
            await connection.verifyOrReconnect(settings: settings)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await connection.verifyOrReconnect(settings: settings) }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
