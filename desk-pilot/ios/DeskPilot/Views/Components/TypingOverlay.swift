import SwiftUI
import UIKit

struct TypingOverlay: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @FocusState private var fieldFocused: Bool
    @State private var typedBuffer = ""
    @State private var suppressTypingSync = false
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Typing on PC", systemImage: "keyboard")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                TextField("Start typing…", text: $typedBuffer, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .focused($fieldFocused)
                    .submitLabel(.return)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(14)
                    .background(AppTheme.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
                    .onSubmit { submitTyping() }
                    .onChange(of: typedBuffer) { oldValue, newValue in
                        syncLiveTyping(from: oldValue, to: newValue)
                    }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .background(AppTheme.card.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            .padding(.horizontal, 12)
            .padding(.bottom, 88)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 120)
            .allowsHitTesting(isVisible)
        }
        .allowsHitTesting(isVisible)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isVisible)
        .onChange(of: connection.keyboardFocusRequestID) { _, _ in
            presentKeyboard()
        }
    }

    private func presentKeyboard() {
        clearLocalBuffer()
        isVisible = true
        connection.setKeyboardOpen(true)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            fieldFocused = true
        }
    }

    private func dismissKeyboard() {
        fieldFocused = false
        isVisible = false
        connection.setKeyboardOpen(false)
        clearLocalBuffer()
    }

    private func syncLiveTyping(from oldValue: String, to newValue: String) {
        guard !suppressTypingSync, connection.isConnected else { return }

        if newValue.count > oldValue.count {
            let added = String(newValue.dropFirst(oldValue.count))
            connection.send(command: RemoteCommand.text(added))
            return
        }

        if newValue.count < oldValue.count {
            for _ in 0..<(oldValue.count - newValue.count) {
                connection.send(command: RemoteCommand.key("backspace"))
            }
        }
    }

    private func submitTyping() {
        connection.send(command: RemoteCommand.key("enter"))
        dismissKeyboard()
        Haptics.light(enabled: settings.hapticsEnabled)
    }

    private func clearLocalBuffer() {
        suppressTypingSync = true
        typedBuffer = ""
        suppressTypingSync = false
    }
}
