import SwiftUI

struct PowerView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var confirmAction: PowerAction?
    @State private var wakeMessage = ""
    @State private var isWaking = false

    enum PowerAction: String, Identifiable {
        case sleep, shutdown

        var id: String { rawValue }

        var title: String {
            switch self {
            case .sleep: return "Sleep PC?"
            case .shutdown: return "Shut down PC?"
            }
        }

        var message: String {
            switch self {
            case .sleep:
                return "Sleep is best for waking from your phone later."
            case .shutdown:
                return "Shutdown takes 2–3 minutes to wake. Prefer Sleep when you want phone control back quickly."
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
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
                            Text("Wake-on-LAN + sign in")
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

                    Text("Tip: use Sleep instead of Off if you want to wake the PC from this app.")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(16)
                .cardStyle()

                Spacer()
            }
            .padding(.horizontal, 16)
            .screenBackground()
            .deskPilotNavigation("Power")
            .onChange(of: connection.wakeRoutineMessage) { _, message in
                guard !message.isEmpty else { return }
                wakeMessage = message
                if message == "Signed in" || message.contains("failed") || message.contains("signed in") {
                    isWaking = false
                }
            }
            .alert(item: $confirmAction) { action in
                Alert(
                    title: Text(action.title),
                    message: Text(action.message),
                    primaryButton: .destructive(Text("Confirm")) {
                        switch action {
                        case .sleep:
                            connection.send(command: RemoteCommand.power(action: "sleep"))
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
        connection.prepareForWakeReconnect()

        do {
            try WakeOnLAN.wake(
                macAddress: settings.macAddress,
                pcHost: settings.host,
                broadcastHost: settings.wolBroadcast
            )
            wakeMessage = "Wake signal sent — PC may take 2–3 min to boot after shutdown…"
            Haptics.medium(enabled: settings.hapticsEnabled)
        } catch {
            wakeMessage = error.localizedDescription
            isWaking = false
            return
        }

        let connected = await connection.waitForConnection(timeout: 300, settings: settings)
        guard connected else {
            wakeMessage = """
            PC did not respond in time. Use Sleep instead of Off for faster wake, run enable-wol.bat on the PC, \
            and stay on the same Wi‑Fi.
            """
            isWaking = false
            return
        }

        wakeMessage = "PC online — signing in…"
        connection.send(command: RemoteCommand.wakeRoutine())

        let signedIn = await waitForWakeRoutineCompletion(timeout: 120)
        if !signedIn, wakeMessage == "PC online — signing in…" {
            wakeMessage = "Sign-in timed out — tap Wake PC to retry"
            isWaking = false
        }
    }

    private func waitForWakeRoutineCompletion(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if connection.wakeRoutineMessage == "Signed in" {
                return true
            }
            if connection.wakeRoutineMessage.contains("failed") {
                return false
            }
            if connection.wakeRoutineMessage.contains("already be signed in") {
                wakeMessage = "PC is awake"
                return true
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        return connection.wakeRoutineMessage == "Signed in"
    }
}

#Preview {
    PowerView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
