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
            TutorMark(name: settings.character.name, size: 88)
            Text("Text \(settings.character.name)")
                .font(SF.display(26))
            Text("One line at a time with \(settings.character.name). Needs an API key in You.")
                .font(SF.ui(15))
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
                .font(SF.display(26))
            Text("Hang up on the Call tab when you're done — Text keeps its own chat so nothing gets mixed up.")
                .font(SF.ui(15))
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
                        ForEach(conversation.messages) { msg in
                            bubble(msg).id(msg.id)
                        }
                        if conversation.phase == .thinking {
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

            if conversation.phase == .listening {
                Text(conversation.liveTranscript.isEmpty ? "Listening" : conversation.liveTranscript)
                    .font(SF.ui(16))
                    .foregroundStyle(SF.teal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                Text("A short pause stays open.")
                    .font(SF.ui(13))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            Button(conversation.phase == .listening ? "Done" : "Speak") {
                if conversation.phase == .listening {
                    conversation.commitChatTurn()
                } else {
                    Task { await conversation.listenForChatTurn() }
                }
            }
            .buttonStyle(StampButton(filled: conversation.phase == .listening))
            .disabled(conversation.phase == .thinking || conversation.phase == .connecting || conversation.phase == .tutorSpeaking)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if conversation.phase != .listening {
                Text("Read the note, then speak. A one-second pause will not send.")
                    .font(SF.ui(13))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
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
                .accessibilityLabel("I blanked")

                TextField("Message in \(settings.language.displayName)…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(SF.card)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

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

    private func bubble(_ msg: ChatMessage) -> some View {
        VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 6) {
            if msg.role == .tutor {
                Text(settings.character.name)
                    .font(SF.label(11))
                    .foregroundStyle(.secondary)
            }
            Text(msg.text)
                .font(SF.ui(17))
                .padding(12)
                .background(msg.role == .user ? SF.coral : Color.white.opacity(0.06))
                .foregroundStyle(msg.role == .user ? SF.ink : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)

            ForEach(msg.corrections) { c in
                Text("\(c.original) → \(c.corrected)")
                    .font(SF.label(13))
                    .foregroundStyle(SF.coral)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(c.explanation)
                    .font(SF.ui(11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
