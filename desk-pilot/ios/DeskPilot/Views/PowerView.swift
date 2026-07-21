import SwiftUI
import UIKit

struct PowerView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var confirmAction: PowerAction?
    @State private var wakeMessage = ""

    enum PowerAction: String, Identifiable {
        case sleep, lock, shutdown

        var id: String { rawValue }

        var title: String {
            switch self {
            case .sleep: return "Sleep PC?"
            case .lock: return "Lock PC?"
            case .shutdown: return "Shut down PC?"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ConnectionBanner()

                Spacer()

                Button {
                    wakePC()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 56))
                        Text("Wake PC")
                            .font(.title3.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                }
                .buttonStyle(TileButtonStyle())

                if !wakeMessage.isEmpty {
                    Text(wakeMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                HStack(spacing: 12) {
                    powerTile("Sleep", icon: "moon.fill") { confirmAction = .sleep }
                    powerTile("Lock", icon: "lock.fill") {
                        connection.send(command: RemoteCommand.shortcut("lock"))
                        haptic()
                    }
                    powerTile("Off", icon: "power", destructive: true) { confirmAction = .shutdown }
                }

                Spacer()
            }
            .padding(16)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Power")
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $confirmAction) { action in
                Alert(
                    title: Text(action.title),
                    message: Text(""),
                    primaryButton: .destructive(Text("Confirm")) {
                        switch action {
                        case .sleep:
                            connection.send(command: RemoteCommand.power(action: "sleep"))
                        case .lock:
                            connection.send(command: RemoteCommand.shortcut("lock"))
                        case .shutdown:
                            connection.send(command: RemoteCommand.power(action: "shutdown"))
                        }
                        haptic()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func powerTile(
        _ title: String,
        icon: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(destructive ? AppTheme.danger : AppTheme.accent)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 88)
        }
        .buttonStyle(TileButtonStyle())
        .disabled(title != "Wake" && !connection.isConnected)
    }

    private func wakePC() {
        do {
            try WakeOnLAN.wake(macAddress: settings.macAddress, broadcastHost: settings.wolBroadcast)
            wakeMessage = "Wake signal sent"
            haptic()
        } catch {
            wakeMessage = error.localizedDescription
        }
    }

    private func haptic() {
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

#Preview {
    PowerView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
