import SwiftUI
import UIKit

struct PowerView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var confirmAction: PowerAction?
    @State private var wakeMessage = ""
    @State private var isWaking = false

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
                    Task { await wakePC() }
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 56))
                        Text("Wake PC")
                            .font(.title3.weight(.semibold))
                        Text("Sign in + open Netflix & Prime")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                }
                .buttonStyle(TileButtonStyle())
                .disabled(isWaking)

                if !wakeMessage.isEmpty {
                    Text(wakeMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
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
            .onChange(of: connection.wakeRoutineMessage) { _, message in
                if !message.isEmpty {
                    wakeMessage = message
                }
            }
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
        .disabled(!connection.isConnected)
    }

    private func wakePC() async {
        isWaking = true
        defer { isWaking = false }

        do {
            try WakeOnLAN.wake(
                macAddress: settings.macAddress,
                pcHost: settings.host,
                broadcastHost: settings.wolBroadcast
            )
            wakeMessage = "Wake signal sent — waiting for PC…"
            haptic()

            let connected = await connection.waitForConnection(timeout: 90, settings: settings)
            guard connected else {
                wakeMessage = "Wake sent. PC still starting — tap banner to retry."
                return
            }

            wakeMessage = "Signing in and opening apps…"
            connection.send(command: RemoteCommand.wakeRoutine())
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
