import SwiftUI
import UIKit

struct ControlView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @FocusState private var typeFieldFocused: Bool
    @State private var scrollMode = false
    @State private var typedBuffer = ""
    @State private var suppressTypingSync = false
    @State private var showTypingBar = false
    @State private var showOptions = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ConnectionBanner()

                TrackpadSurface(scrollMode: $scrollMode)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: showTypingBar ? 120 : .infinity)
                    .animation(.easeInOut(duration: 0.2), value: showTypingBar)

                if showTypingBar {
                    typingBar
                }

                HStack(spacing: 8) {
                    clickButton("Left", button: "left")
                    clickButton("Right", button: "right")
                    Button(scrollMode ? "Track" : "Scroll") {
                        scrollMode.toggle()
                    }
                    .buttonStyle(PrimaryButtonStyle(isActive: scrollMode))
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
            .onChange(of: connection.keyboardFocusRequestID) { _, _ in
                openPhoneKeyboard()
            }
        }
    }

    private var typingBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Typing on your PC")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Button("Done") {
                    showTypingBar = false
                    typeFieldFocused = false
                    clearLocalBuffer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            }

            TextField("Start typing…", text: $typedBuffer, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .focused($typeFieldFocused)
                .submitLabel(.return)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
                )
                .onSubmit { submitTyping() }
                .onChange(of: typedBuffer) { oldValue, newValue in
                    syncLiveTyping(from: oldValue, to: newValue)
                }
        }
        .padding(12)
        .cardStyle()
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

    private func openPhoneKeyboard() {
        clearLocalBuffer()
        showTypingBar = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            typeFieldFocused = true
        }
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

    private func syncLiveTyping(from oldValue: String, to newValue: String) {
        guard !suppressTypingSync, connection.isConnected else { return }

        if newValue.count > oldValue.count {
            let added = String(newValue.dropFirst(oldValue.count))
            if added.count == 1, let char = added.first {
                connection.send(command: RemoteCommand.key(String(char)))
            } else {
                connection.send(command: RemoteCommand.text(added))
            }
            return
        }

        if newValue.count < oldValue.count {
            let deletes = oldValue.count - newValue.count
            for _ in 0..<deletes {
                connection.send(command: RemoteCommand.key("backspace"))
            }
        }
    }

    private func submitTyping() {
        connection.send(command: RemoteCommand.key("enter"))
        clearLocalBuffer()
        showTypingBar = false
        typeFieldFocused = false
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func clearLocalBuffer() {
        suppressTypingSync = true
        typedBuffer = ""
        suppressTypingSync = false
    }
}

#Preview {
    ControlView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
