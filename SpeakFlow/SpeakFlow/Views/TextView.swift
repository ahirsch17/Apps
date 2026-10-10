import SwiftUI

struct TextHomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var conversation: ConversationController
    @State private var draft = ""
    var onNeedKey: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if !settings.hasAPIKey {
                    locked
                } else if conversation.isCallBlockingText {
                    callBusy
                } else if conversation.phase == .report, conversation.mode == .text {
                    CallReportView()
                } else {
                    chat
                }
            }
            .navigationTitle(settings.character.name)
            .toolbar {
                if settings.hasAPIKey && !conversation.isCallBlockingText {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("New chat") { Task { await conversation.startText() } }
                            Button("End & recap", role: .destructive) { Task { await conversation.hangUp() } }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
            }
            .task {
                if settings.hasAPIKey {
                    await conversation.startTextIfNeeded()
                }
            }
        }
    }

    private var locked: some View {
        VStack(spacing: 16) {
            Text(settings.character.emoji).font(.system(size: 64))
            Text("Text \(settings.character.name)")
                .font(.system(.title2, design: .rounded).weight(.bold))
            Text("Same tutor as Call, message-style. Needs an API key in Profile.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Open Profile", action: onNeedKey)
                .buttonStyle(.borderedProminent)
                .tint(SF.coral)
        }
    }

    private var callBusy: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.fill")
                .font(.system(size: 40))
                .foregroundStyle(SF.mint)
            Text("You're on a call")
                .font(.system(.title2, design: .rounded).weight(.bold))
            Text("Hang up on the Call tab when you're done — Text keeps its own chat so nothing gets mixed up.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var chat: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if conversation.messages.isEmpty && conversation.phase == .idle {
                            emptyChat
                        }
                        ForEach(conversation.messages) { msg in
                            bubble(msg).id(msg.id)
                        }
                        if conversation.phase == .thinking || conversation.phase == .connecting {
                            ProgressView().padding().id("load")
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation.messages.count) { _, _ in
                    if let last = conversation.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if let err = conversation.error {
                Text(err).font(.caption).foregroundStyle(SF.coral).padding(.horizontal)
            }

            if !conversation.latestStarters.isEmpty, conversation.phase == .idle || conversation.phase == .tutorSpeaking {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(conversation.latestStarters, id: \.self) { starter in
                            Button {
                                draft = starter
                            } label: {
                                Text(starter)
                                    .font(.system(.footnote, design: .rounded).weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(SF.teal.opacity(0.18))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.top, 6)
            }

            HStack(spacing: 10) {
                Button {
                    Task { await conversation.skipTrySomething() }
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(width: 40, height: 40)
                        .background(SF.card)
                        .clipShape(Circle())
                }
                .disabled(conversation.messages.isEmpty || conversation.phase == .thinking || conversation.phase == .connecting)
                .accessibilityLabel("I blanked")

                TextField("Message in \(settings.language.displayName)…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(SF.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    let t = draft
                    draft = ""
                    Task { await conversation.sendText(t) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(SF.teal)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || conversation.phase == .thinking)
            }
            .padding(12)
        }
    }

    private var emptyChat: some View {
        VStack(spacing: 12) {
            Text(settings.character.emoji).font(.system(size: 48))
            Text("Start a chat with \(settings.character.name)")
                .font(.system(.headline, design: .rounded))
            Button("Say hi") { Task { await conversation.startText() } }
                .buttonStyle(.borderedProminent)
                .tint(SF.teal)
        }
        .padding(.top, 60)
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 6) {
            if msg.role == .tutor {
                HStack(spacing: 6) {
                    Text(settings.character.name)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Button {
                        conversation.speakMessage(msg)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption2)
                            .foregroundStyle(SF.teal)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Play message")
                }
            }
            Text(msg.text)
                .font(.system(.body, design: .rounded))
                .padding(12)
                .background(msg.role == .user ? SF.teal : SF.card)
                .foregroundStyle(msg.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)

            if msg.role == .tutor, settings.showTranslations, let translation = msg.translation {
                Text(translation)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(msg.corrections) { c in
                Text("\(c.original) → \(c.corrected)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(SF.coral)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(c.explanation)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
