import SwiftUI

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
            VStack(spacing: 18) {
                ConnectionBanner()

                Spacer(minLength: 8)

                Button {
                    Task { await wakePC() }
                } label: {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: isWaking ? "ellipsis" : "power.circle.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(AppTheme.accent)
                                .symbolEffect(.pulse, isActive: isWaking)
                        }

                        VStack(spacing: 4) {
                            Text(isWaking ? "Waking PC…" : "Wake PC")
                                .font(.title3.weight(.semibold))
                            Text("Wake & sign in")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .buttonStyle(AccentHeroButtonStyle())
                .disabled(isWaking)

                if !wakeMessage.isEmpty {
                    StatusMessage(text: wakeMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "PC controls", icon: "desktopcomputer")

                    HStack(spacing: 12) {
                        powerTile("Sleep", icon: "moon.fill") { confirmAction = .sleep }
                        powerTile("Lock", icon: "lock.fill") {
                            connection.send(command: RemoteCommand.shortcut("lock"))
                            Haptics.medium(enabled: settings.hapticsEnabled)
                        }
                        powerTile("Off", icon: "power", destructive: true) { confirmAction = .shutdown }
                    }
                }
                .padding(16)
                .cardStyle()

                Spacer()
            }
            .padding(16)
            .screenBackground()
            .deskPilotNavigation("Power")
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
                        Haptics.medium(enabled: settings.hapticsEnabled)
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
                    .font(.title3)
                    .foregroundStyle(destructive ? AppTheme.danger : AppTheme.accent)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 84)
        }
        .buttonStyle(TileButtonStyle(tint: destructive ? AppTheme.danger : AppTheme.accent))
        .disabled(!connection.isConnected)
    }

    private func wakePC() async {
        isWaking = true
        wakeMessage = ""
        defer { isWaking = false }

        connection.prepareForWakeReconnect()

        do {
            try WakeOnLAN.wake(
                macAddress: settings.macAddress,
                pcHost: settings.host,
                broadcastHost: settings.wolBroadcast
            )
            wakeMessage = "Wake signal sent — waiting for PC to respond…"
            Haptics.medium(enabled: settings.hapticsEnabled)
        } catch {
            wakeMessage = error.localizedDescription
            return
        }

        let connected = await connection.waitForConnection(timeout: 120, settings: settings)
        guard connected else {
            wakeMessage = """
            PC did not respond. Sleep the PC instead of shutting down, run enable-wol.bat on the PC, \
            and stay on the same Wi‑Fi.
            """
            return
        }

        wakeMessage = "PC online — signing in…"
        connection.send(command: RemoteCommand.wakeRoutine())
    }
}

#Preview {
    PowerView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
