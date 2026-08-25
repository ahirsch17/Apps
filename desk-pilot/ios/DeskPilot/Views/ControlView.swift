import SwiftUI
import UIKit

struct ControlView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var showOptions = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                TrackpadSurface()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 10) {
                    clickButton(title: "Left", icon: "hand.tap.fill", button: "left")
                    clickButton(title: "Right", icon: "hand.point.up.left.fill", button: "right")
                }

                Button {
                    connection.requestKeyboard()
                    Haptics.light(enabled: settings.hapticsEnabled)
                } label: {
                    Label("Keyboard", systemImage: "keyboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(isActive: connection.keyboardIsOpen))
                .disabled(!connection.isConnected)

                Text("Tap Keyboard above, or click a text field on your PC.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .screenBackground()
            .deskPilotNavigation("DeskPilot")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showOptions = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(AppTheme.accent)
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
                Section {
                    sensitivityRow(title: "Move", value: settings.trackpadSensitivity) {
                        Slider(value: $settings.trackpadSensitivity, in: 0.25...3.0, step: 0.05)
                    }
                    sensitivityRow(title: "Scroll", value: settings.scrollSensitivity) {
                        Slider(value: $settings.scrollSensitivity, in: 0.25...3.0, step: 0.05)
                    }
                    Toggle("Tap to click", isOn: $settings.tapToClick)
                    Toggle("Invert scroll", isOn: $settings.invertScroll)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Trackpad")
                }

                Section {
                    LabeledContent("PC", value: PCDefaults.pcName)
                    LabeledContent("IP", value: settings.host)
                } header: {
                    Text("Connection")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .deskPilotNavigation("Options")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showOptions = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(AppTheme.backgroundElevated)
    }

    @ViewBuilder
    private func sensitivityRow<Content: View>(
        title: String,
        value: Double,
        @ViewBuilder slider: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(title) sensitivity")
                Spacer()
                Text(String(format: "%.1fx", value))
                    .foregroundStyle(AppTheme.accent)
                    .fontWeight(.semibold)
            }
            slider()
        }
    }

    private func clickButton(title: String, icon: String, button: String) -> some View {
        Button {
            connection.send(command: RemoteCommand.mouseClick(button: button))
            Haptics.light(enabled: settings.hapticsEnabled)
        } label: {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!connection.isConnected)
    }
}

#Preview {
    ControlView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
