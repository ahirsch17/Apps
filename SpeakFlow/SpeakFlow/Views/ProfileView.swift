import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var keyDraft = ""
    @State private var showKey = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Text(settings.character.emoji).font(.system(size: 44))
                        VStack(alignment: .leading) {
                            Text(settings.character.name)
                                .font(.system(.headline, design: .rounded))
                            Text(settings.character.vibe)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker("Language", selection: $settings.language) {
                        ForEach(Language.allCases) { Text("\($0.flag) \($0.displayName)").tag($0) }
                    }
                    Picker("Call level", selection: $settings.level) {
                        ForEach(ConversationLevel.allCases) { Text($0.title).tag($0) }
                    }
                    Text(settings.level.blurb).font(.caption).foregroundStyle(.secondary)
                    Picker("Topic vibe", selection: $settings.topic) {
                        ForEach(ConversationTopic.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                } header: {
                    Text("Your tutor")
                }

                Section {
                    if settings.hasAPIKey {
                        Label("Call & Text unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(SF.mint)
                    } else {
                        Text("Optional. Learn works forever free. Add a key only when you want live Call / Text.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Group {
                            if showKey {
                                TextField("sk-…", text: $keyDraft)
                            } else {
                                SecureField("sk-…", text: $keyDraft)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))

                        Button { showKey.toggle() } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    Button("Save key") {
                        settings.apiKey = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        saved = true
                    }
                    .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if settings.hasAPIKey {
                        Button("Remove key", role: .destructive) {
                            settings.apiKey = ""
                            keyDraft = ""
                            saved = false
                        }
                    }

                    if saved && settings.hasAPIKey {
                        Label("Saved on-device (Keychain)", systemImage: "lock.fill")
                            .font(.caption).foregroundStyle(SF.mint)
                    }

                    Link("Get a key → platform.openai.com", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)

                    Picker("Model", selection: $settings.model) {
                        Text("GPT-4o mini (~$0.001)").tag("gpt-4o-mini")
                        Text("GPT-4.1 nano (cheapest)").tag("gpt-4.1-nano")
                        Text("GPT-4.1 mini").tag("gpt-4.1-mini")
                    }
                    Toggle("Speak replies in Text mode", isOn: $settings.autoSpeak)
                } header: {
                    Text("AI Call & Text (optional)")
                } footer: {
                    Text("You pay OpenAI directly — SpeakFlow is the interface. Typical 10-min call is pennies.")
                }

                Section("How it works") {
                    labeled("Call", "FaceTime-style. Hands-free. Blanked button if you freeze. Recap at the end.")
                    labeled("Text", "iMessage-style with the same tutor.")
                    labeled("Learn", "Level path, offline. Fail on purpose — that's the point.")
                }
            }
            .navigationTitle("Profile")
            .onAppear { keyDraft = settings.apiKey }
        }
    }

    private func labeled(_ t: String, _ b: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t).font(.system(.subheadline, design: .rounded).weight(.semibold))
            Text(b).font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
