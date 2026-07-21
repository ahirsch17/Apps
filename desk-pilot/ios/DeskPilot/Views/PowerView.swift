import SwiftUI
import UIKit

struct PowerView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var wakeStatus = ""
    @State private var isWaking = false
    @State private var confirmAction: PowerAction?

    enum PowerAction: String, Identifiable {
        case sleep, restart, shutdown

        var id: String { rawValue }

        var title: String {
            switch self {
            case .sleep: return "Sleep PC?"
            case .restart: return "Restart PC?"
            case .shutdown: return "Shut Down PC?"
            }
        }

        var message: String {
            switch self {
            case .sleep:
                return "The PC will sleep. You can wake it again from this tab."
            case .restart:
                return "The PC will restart. DeskPilot reconnects automatically once the server is back."
            case .shutdown:
                return "The PC will shut down. Use Wake PC to turn it back on."
            }
        }

        var serverAction: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ConnectionBanner()

                    wakeSection
                    powerSection
                    howItWorksSection
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Power")
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $confirmAction) { action in
                Alert(
                    title: Text(action.title),
                    message: Text(action.message),
                    primaryButton: .destructive(Text("Confirm")) {
                        sendPower(action.serverAction)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var wakeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Wake PC", systemImage: "sunrise.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)

            Text("Works even when the PC is asleep or off — no server needed. Requires Wake-on-LAN enabled on your PC (see setup below).")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("PC MAC address")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("AA:BB:CC:DD:EE:FF", text: $settings.macAddress)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.body.monospaced())
            }

            if !wakeStatus.isEmpty {
                Text(wakeStatus)
                    .font(.caption)
                    .foregroundStyle(wakeStatus.contains("Sent") ? AppTheme.success : AppTheme.danger)
            }

            Button(isWaking ? "Sending…" : "Wake PC") {
                Task { await wakePC() }
            }
            .buttonStyle(PrimaryButtonStyle(isActive: true))
            .disabled(isWaking || settings.macAddress.count < 11)
        }
        .padding(16)
        .cardStyle()
    }

    private var powerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("While PC is on", systemImage: "power")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Sleep, restart, and shutdown need the DeskPilot server running on your PC (use auto-start so you never open a terminal).")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            powerButton("Sleep", icon: "moon.fill", action: .sleep)
            powerButton("Restart", icon: "arrow.clockwise", action: .restart)
            powerButton("Shut Down", icon: "power", action: .shutdown, destructive: true)
        }
        .padding(16)
        .cardStyle()
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("One-time PC setup for Wake")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("1. Run server/install-autostart.bat (server starts at login, hidden)")
            Text("2. Device Manager → Network adapter → Power Management → allow wake")
            Text("3. BIOS/UEFI → enable Wake-on-LAN (wording varies by motherboard)")
            Text("4. Copy MAC from server output into the field above")
            Text("Tip: Sleep instead of full shutdown for fastest wake from phone.")
        }
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
        .padding(16)
        .cardStyle()
    }

    private func powerButton(_ title: String, icon: String, action: PowerAction, destructive: Bool = false) -> some View {
        Button {
            confirmAction = action
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(destructive ? AppTheme.danger : AppTheme.accent)
                Text(title)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(minHeight: AppTheme.minTapTarget)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder))
        }
        .disabled(!connection.isConnected)
    }

    private func wakePC() async {
        isWaking = true
        wakeStatus = ""
        defer { isWaking = false }

        do {
            try WakeOnLAN.wake(macAddress: settings.macAddress, broadcastHost: settings.wolBroadcast)
            wakeStatus = "Sent wake signal — PC should start in ~30 seconds"
            if settings.hapticsEnabled {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {
            wakeStatus = error.localizedDescription
        }
    }

    private func sendPower(_ action: String) {
        connection.send(command: RemoteCommand.power(action: action))
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
