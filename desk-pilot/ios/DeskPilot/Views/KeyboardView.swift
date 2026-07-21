import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var textToSend = ""
    @State private var stickyCtrl = false
    @State private var stickyAlt = false
    @State private var stickyShift = false
    @State private var stickyWin = false
    @State private var showFunctionKeys = false

    private let essentials: [(String, String)] = [
        ("Esc", "escape"),
        ("Tab", "tab"),
        ("Enter", "enter"),
        ("⌫", "backspace"),
        ("Del", "delete"),
        ("Space", "space")
    ]

    private let functionKeys = (1...12).map { ("F\($0)", "f\($0)") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ConnectionBanner()

                    typeSection
                    modifierSection
                    essentialsSection
                    arrowSection
                    functionKeysSection
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Keyboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type on PC")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            TextField("Text to send…", text: $textToSend, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(12)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder))

            Button("Send to PC") {
                guard !textToSend.isEmpty else { return }
                connection.send(command: RemoteCommand.text(textToSend))
                textToSend = ""
            }
            .buttonStyle(PrimaryButtonStyle(isActive: true))
            .disabled(!connection.isConnected || textToSend.isEmpty)
        }
        .padding(16)
        .cardStyle()
    }

    private var modifierSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modifiers")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 8) {
                modifierToggle("Ctrl", active: $stickyCtrl)
                modifierToggle("Alt", active: $stickyAlt)
                modifierToggle("Shift", active: $stickyShift)
                modifierToggle("Win", active: $stickyWin)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var essentialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Essentials")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(essentials, id: \.1) { label, key in
                        keyButton(label, key: key)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var arrowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Arrows")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 8) {
                keyButton("↑", key: "up")
                HStack(spacing: 8) {
                    keyButton("←", key: "left")
                    keyButton("↓", key: "down")
                    keyButton("→", key: "right")
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var functionKeysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showFunctionKeys.toggle() }
            } label: {
                HStack {
                    Text("Function Keys")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: showFunctionKeys ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if showFunctionKeys {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(functionKeys, id: \.1) { label, key in
                        keyButton(label, key: key)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func modifierToggle(_ title: String, active: Binding<Bool>) -> some View {
        Button(title) {
            active.wrappedValue.toggle()
        }
        .buttonStyle(PrimaryButtonStyle(isActive: active.wrappedValue))
    }

    private func keyButton(_ title: String, key: String) -> some View {
        Button(title) {
            connection.send(command: RemoteCommand.key(key, modifiers: activeModifiers()))
            clearStickyIfNeeded()
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!connection.isConnected)
    }

    private func activeModifiers() -> [String] {
        var mods: [String] = []
        if stickyCtrl { mods.append("ctrl") }
        if stickyAlt { mods.append("alt") }
        if stickyShift { mods.append("shift") }
        if stickyWin { mods.append("win") }
        return mods
    }

    private func clearStickyIfNeeded() {
        stickyCtrl = false
        stickyAlt = false
        stickyShift = false
        stickyWin = false
    }
}

#Preview {
    KeyboardView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
