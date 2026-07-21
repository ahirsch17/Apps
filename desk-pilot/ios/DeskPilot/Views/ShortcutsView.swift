import SwiftUI
import UIKit

struct ShortcutsView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    private let shortcuts: [(String, String, String)] = [
        ("Show Desktop", "macwindow.on.rectangle", "show_desktop"),
        ("Switch App", "arrow.left.arrow.right", "alt_tab"),
        ("Task View", "square.on.square", "task_view"),
        ("Lock PC", "lock.fill", "lock"),
        ("Screenshot", "camera.viewfinder", "screenshot"),
        ("Copy", "doc.on.doc", "copy"),
        ("Paste", "doc.on.clipboard", "paste"),
        ("Undo", "arrow.uturn.backward", "undo"),
        ("Select All", "selection.pin.in.out", "select_all"),
        ("Close Window", "xmark.square", "close_window"),
        ("Minimize", "minus.square", "minimize")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ConnectionBanner()

                    Text("Tap a shortcut to run it on your PC")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(shortcuts, id: \.2) { title, icon, name in
                            Button {
                                connection.send(command: RemoteCommand.shortcut(name))
                                if settings.hapticsEnabled {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.accent)
                                    Text(title)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 88)
                            }
                            .buttonStyle(TileButtonStyle())
                            .disabled(!connection.isConnected)
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ShortcutsView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
