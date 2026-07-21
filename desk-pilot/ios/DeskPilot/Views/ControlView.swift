import SwiftUI
import UIKit

struct ControlView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var scrollMode = false
    @State private var showTyping = false
    @State private var textToSend = ""
    @State private var showOptions = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ConnectionBanner()

                TrackpadSurface(scrollMode: $scrollMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showTyping {
                    HStack(spacing: 8) {
                        TextField("Type on your PC…", text: $textToSend)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder))
                            .submitLabel(.send)
                            .onSubmit { sendText() }

                        Button("Send") { sendText() }
                            .buttonStyle(PrimaryButtonStyle(isActive: true))
                            .disabled(textToSend.isEmpty || !connection.isConnected)
                    }
                }

                HStack(spacing: 8) {
                    clickButton("Left", button: "left")
                    clickButton("Right", button: "right")
                    Button(scrollMode ? "Track" : "Scroll") {
                        scrollMode.toggle()
                    }
                    .buttonStyle(PrimaryButtonStyle(isActive: scrollMode))

                    Button {
                        showTyping.toggle()
                        if !showTyping { textToSend = "" }
                    } label: {
                        Image(systemName: showTyping ? "keyboard.chevron.compact.down" : "keyboard")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppTheme.minTapTarget)
                    }
                    .buttonStyle(PrimaryButtonStyle(isActive: showTyping))
                }
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
                            Text("Sensitivity")
                            Spacer()
                            Text(String(format: "%.1fx", settings.trackpadSensitivity))
                                .foregroundStyle(AppTheme.accent)
                        }
                        Slider(value: $settings.trackpadSensitivity, in: 0.25...3.0, step: 0.05)
                    }
                    Toggle("Tap to click", isOn: $settings.tapToClick)
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
        .presentationDetents([.medium])
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

    private func sendText() {
        guard !textToSend.isEmpty else { return }
        connection.send(command: RemoteCommand.text(textToSend))
        textToSend = ""
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

#Preview {
    ControlView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
