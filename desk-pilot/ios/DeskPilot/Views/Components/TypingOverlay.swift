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

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Typing on your PC")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                        .font(.caption.weight(.semibold))
                }

                TextField("Start typing…", text: $typedBuffer, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .focused($fieldFocused)
                    .submitLabel(.return)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onSubmit { submitTyping() }
                    .onChange(of: typedBuffer) { oldValue, newValue in
                        syncLiveTyping(from: oldValue, to: newValue)
                    }
            }
            .padding(16)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 120)
            .allowsHitTesting(isVisible)
        }
        .allowsHitTesting(isVisible)
        .animation(.easeOut(duration: 0.2), value: isVisible)
        .onChange(of: connection.keyboardFocusRequestID) { _, _ in
            presentKeyboard()
        }
    }

    private func presentKeyboard() {
        clearLocalBuffer()
        isVisible = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            fieldFocused = true
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !fieldFocused {
                fieldFocused = true
            }
        }
    }

    private func dismissKeyboard() {
        fieldFocused = false
        isVisible = false
        clearLocalBuffer()
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
            for _ in 0..<(oldValue.count - newValue.count) {
                connection.send(command: RemoteCommand.key("backspace"))
            }
        }
    }

    private func submitTyping() {
        connection.send(command: RemoteCommand.key("enter"))
        dismissKeyboard()
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
