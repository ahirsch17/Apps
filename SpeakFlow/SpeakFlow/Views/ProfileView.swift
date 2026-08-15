import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var apiKeyDraft = ""
    @State private var showAPIKey = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Language", selection: $settings.language) {
                        ForEach(Language.allCases) { language in
                            Text("\(language.flag)  \(language.displayName)").tag(language)
                        }
                    }
                    Picker("Chat level", selection: $settings.level) {
                        ForEach(ConversationLevel.allCases) { Text($0.displayName).tag($0) }
                    }
                    Text(settings.level.subtitle).font(.caption).foregroundStyle(.secondary)
                    Picker("Chat topic", selection: $settings.topic) {
                        ForEach(ConversationTopic.allCases) { Label($0.displayName, systemImage: $0.icon).tag($0) }
                    }
                } header: {
                    Text("You")
                } footer: {
                    Text("Language applies everywhere. Level and topic are for AI Chat.")
                }

                Section {
                    if settings.hasAPIKey {
                        Label("AI Chat is on", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("Optional — Learn works without this. Add a key only if you want a live conversation tutor.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        if showAPIKey {
                            TextField("sk-…", text: $apiKeyDraft)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-…", text: $apiKeyDraft)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        }
                        Button { showAPIKey.toggle() } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    Button("Save key") {
                        settings.apiKey = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        saved = true
                    }
                    .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if settings.hasAPIKey {
                        Button("Remove key", role: .destructive) {
                            settings.apiKey = ""
                            apiKeyDraft = ""
                            saved = false
                        }
                    }

                    if saved && settings.hasAPIKey {
                        Label("Saved on this device (Keychain)", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Link("Get a key at platform.openai.com", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)

                    Picker("Model", selection: $settings.selectedModel) {
                        ForEach(LLMModel.allCases) { Text($0.displayName).tag($0) }
                    }
                    Text(settings.selectedModel.costNote).font(.caption).foregroundStyle(.secondary)
                } header: {
                    Text("AI Chat (optional)")
                } footer: {
                    Text("You pay OpenAI directly — no SpeakFlow subscription. Typical practice is under $0.10 for 15 minutes.")
                }

                Section {
                    Toggle("Speak tutor replies aloud", isOn: $settings.autoSpeakResponses)
                    Toggle("Show corrections on my message", isOn: $settings.showCorrectionsBeforeReply)
                    Toggle("Reuse weak vocab in chat", isOn: $settings.reuseWeakVocab)
                } header: {
                    Text("Chat behavior")
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        labeled("Learn", "Words, phrases, and later your mistakes. Free. Offline.")
                        labeled("Chat", "Live tutor. Hold to talk. Starters + Stuck. Needs a key.")
                        labeled("Profile", "Language and optional API key live here.")
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("How to use SpeakFlow")
                }
            }
            .navigationTitle("Profile")
            .onAppear { apiKeyDraft = settings.apiKey }
        }
    }

    private func labeled(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(body).font(.caption).foregroundStyle(.secondary)
        }
    }
}
