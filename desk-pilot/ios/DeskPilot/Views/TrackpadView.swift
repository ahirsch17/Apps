import SwiftUI
import UIKit

struct TrackpadView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var scrollMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ConnectionBanner()

                TrackpadSurface(scrollMode: $scrollMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sensitivity")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text(String(format: "%.1fx", settings.trackpadSensitivity))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AppTheme.accent)
                    }

                    Slider(value: $settings.trackpadSensitivity, in: 0.25...3.0, step: 0.05)
                        .tint(AppTheme.accent)
                }
                .padding(16)
                .cardStyle()

                HStack(spacing: 10) {
                    Button("Left Click") {
                        sendClick(button: "left")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Right Click") {
                        sendClick(button: "right")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(scrollMode ? "Track" : "Scroll") {
                        scrollMode.toggle()
                    }
                    .buttonStyle(PrimaryButtonStyle(isActive: scrollMode))
                }
            }
            .padding(16)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Trackpad")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { ensureConnected() }
        }
    }

    private func sendClick(button: String) {
        connection.send(command: RemoteCommand.mouseClick(button: button))
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func ensureConnected() {
        guard !connection.isConnected else { return }
        if settings.isPaired {
            connection.connect(host: settings.host, port: settings.port, token: settings.authToken)
        }
    }
}

#Preview {
    TrackpadView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
