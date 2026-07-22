import SwiftUI
import UIKit

struct ControlView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var showOptions = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ConnectionBanner()

                TrackpadSurface()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 8) {
                    clickButton("Left", button: "left")
                    clickButton("Right", button: "right")
                }

                Button {
                    connection.requestKeyboard()
                    if settings.hapticsEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Label("Keyboard", systemImage: "keyboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(isActive: connection.keyboardIsOpen))

                Text("Tap a search field on your PC — keyboard opens automatically.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("DeskPilot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showOptions = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showOptions) {
                optionsSheet
            }
        }
    }

    private var optionsSheet: some View {
        NavigationStack {
            Form {
                Section("Trackpad") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Move sensitivity")
                            Spacer()
                            Text(String(format: "%.1fx", settings.trackpadSensitivity))
                                .foregroundStyle(AppTheme.accent)
                        }
                        Slider(value: $settings.trackpadSensitivity, in: 0.25...3.0, step: 0.05)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scroll sensitivity")
                            Spacer()
                            Text(String(format: "%.1fx", settings.scrollSensitivity))
                                .foregroundStyle(AppTheme.accent)
                        }
                        Slider(value: $settings.scrollSensitivity, in: 0.25...3.0, step: 0.05)
                    }
                    Toggle("Tap to click", isOn: $settings.tapToClick)
                    Toggle("Invert scroll", isOn: $settings.invertScroll)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                }

                Section("PC") {
                    LabeledContent("Name", value: PCDefaults.pcName)
                    LabeledContent("IP", value: settings.host)
                }
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showOptions = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func clickButton(_ title: String, button: String) -> some View {
        Button(title) {
            connection.send(command: RemoteCommand.mouseClick(button: button))
            if settings.hapticsEnabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

#Preview {
    ControlView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
