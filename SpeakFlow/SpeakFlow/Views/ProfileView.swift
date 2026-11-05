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
                        TutorMark(name: settings.character.name, size: 56)
                        VStack(alignment: .leading) {
                            Text(settings.character.name)
                                .font(SF.uiBold(17))
                            Text(settings.character.vibe)
                                .font(SF.ui(13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker("Language", selection: $settings.language) {
                        ForEach(Language.allCases) { Text("\($0.flag) \($0.displayName)").tag($0) }
                    }
                    Picker("Level cap", selection: $settings.level) {
                        ForEach(ConversationLevel.allCases) { Text($0.title).tag($0) }
                    }
                    Text(settings.level.blurb).font(.caption).foregroundStyle(.secondary)
                    Picker("Topic vibe", selection: $settings.topic) {
                        ForEach(ConversationTopic.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                } header: {
                    Text("Your tutor")
                } footer: {
                    Text("Each language keeps its own phrases. Talk uses \(settings.talkLevel.title) from the lines checked off, and will not go past this cap.")
                }

                Section {
                    if settings.hasAPIKey {
                        Label("Chat and Talk unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(SF.mint)
                    } else {
                        Text("Practice works with no key. A key lets \(settings.character.name) read a missed conversation, and it unlocks Chat and Talk once four rounds are done.")
                            .font(SF.ui(15))
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
                        .font(.custom("Menlo", size: 15))

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
                    Text("Call and Text")
                } footer: {
                    Text("You pay OpenAI directly — SpeakFlow is the interface. Typical 10-min call is pennies.")
                }

                Section("How it works") {
                    labeled("Practice", "Hear a line, answer it until it is checked off, then use it when \(settings.character.name) asks.")
                    labeled("Path", "The topic you are on, and which lines are familiar.")
                    labeled("Chat", "One line at a time. The note stays on screen, and you tap Speak when you want to go on.")
                    labeled("Talk", "Back and forth, no button. Questions stay with the lines you know. The recap waits until the end.")
                }

                if settings.freeTalkUnlocked && settings.hasAPIKey {
                    Section("Leave the script") {
                        NavigationLink("Chat") { TextHomeView(onNeedKey: {}) }
                        NavigationLink("Talk") { CallHomeView(onNeedKey: {}) }
                    }
                } else if settings.freeTalkUnlocked {
                    Section("Leave the script") {
                        Text("Four conversations are done. Save a key above and Chat and Talk show up here.")
                            .font(SF.ui(15))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("You")
            .font(SF.ui(16))
            .onAppear { keyDraft = settings.apiKey }
        }
    }

    private func labeled(_ t: String, _ b: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t).font(SF.uiBold(15))
            Text(b).font(SF.ui(13)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
