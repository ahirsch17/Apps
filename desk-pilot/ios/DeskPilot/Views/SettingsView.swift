import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var pin = ""
    @State private var statusMessage = ""
    @State private var isPairing = false
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ConnectionBanner()

                    connectionSection
                    tuningSection
                    aboutSection
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Connection")

            labeledField("PC IP address", text: $settings.host, placeholder: "192.168.1.42")
            labeledPort("Port", value: $settings.port)

            labeledField("Pairing PIN", text: $pin, placeholder: "6-digit code from PC")
                .keyboardType(.numberPad)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(statusMessage.contains("success") ? AppTheme.success : AppTheme.danger)
            }

            Button(isPairing ? "Pairing…" : "Pair with PC") {
                Task { await pair() }
            }
            .buttonStyle(PrimaryButtonStyle(isActive: true))
            .disabled(isPairing || settings.host.isEmpty || pin.count < 4)

            Button(isTesting ? "Testing…" : "Test Connection") {
                Task { await testConnection() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isTesting || settings.host.isEmpty)

            if settings.isPaired {
                Button("Forget Device") {
                    settings.forgetDevice()
                    connection.disconnect()
                    statusMessage = "Device forgotten — pair again"
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var tuningSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Trackpad")

            sliderRow("Trackpad sensitivity", value: $settings.trackpadSensitivity, range: 0.25...3.0)
            sliderRow("Scroll sensitivity", value: $settings.scrollSensitivity, range: 0.25...3.0)

            toggleRow("Tap to click", isOn: $settings.tapToClick)
            toggleRow("Invert scroll", isOn: $settings.invertScroll)
            toggleRow("Haptic feedback", isOn: $settings.hapticsEnabled)
        }
        .padding(16)
        .cardStyle()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Setup")
            Text("1. Run install-autostart.bat on your PC (starts server at login, no terminal)")
            Text("2. Pair once in this app — survives reboots")
            Text("3. Use the Power tab to wake, sleep, or shut down")
            Text("4. Enable Wake-on-LAN in BIOS + network adapter for wake-from-off")
        }
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
        .padding(16)
        .cardStyle()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
    }

    private func labeledField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    private func labeledPort(_ title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            TextField("8765", value: value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder))
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(String(format: "%.1fx", value.wrappedValue))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.accent)
            }
            Slider(value: value, in: range, step: 0.05)
                .tint(AppTheme.accent)
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .tint(AppTheme.accent)
            .foregroundStyle(AppTheme.textPrimary)
    }

    private func pair() async {
        isPairing = true
        statusMessage = ""
        defer { isPairing = false }

        let deviceName = UIDevice.current.name
        if let token = await connection.pair(
            host: settings.host,
            port: settings.port,
            pin: pin,
            deviceName: deviceName
        ) {
            settings.authToken = token
            if !connection.serverMacAddress.isEmpty {
                settings.macAddress = connection.serverMacAddress
            }
            statusMessage = "Paired successfully"
            pin = ""
        } else if case .error(let msg) = connection.state {
            statusMessage = msg
        }
    }

    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }

        let ok = await connection.testConnection(
            host: settings.host,
            port: settings.port,
            token: settings.authToken
        )
        statusMessage = ok ? "Connection test success" : "Connection test failed"
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
