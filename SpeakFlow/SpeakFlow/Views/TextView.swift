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
                } else if conversation.phase == .report {
                    CallReportView()
                } else {
                    chat
                }
            }
            .navigationTitle(settings.character.name)
            .toolbar {
                if settings.hasAPIKey {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("New chat") { Task { await conversation.startText() } }
                            Button("End & recap", role: .destructive) { Task { await conversation.hangUp() } }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
            }
            .task {
                if settings.hasAPIKey && conversation.messages.isEmpty && conversation.phase == .idle {
                    await conversation.startText()
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

            HStack(spacing: 10) {
                Button {
                    Task { await conversation.skipTrySomething() }
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(width: 40, height: 40)
                        .background(SF.card)
                        .clipShape(Circle())
                }

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

    private func bubble(_ msg: ChatMessage) -> some View {
        VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 6) {
            if msg.role == .tutor {
                Text(settings.character.name)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(msg.text)
                .font(.system(.body, design: .rounded))
                .padding(12)
                .background(msg.role == .user ? SF.teal : SF.card)
                .foregroundStyle(msg.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)

            ForEach(msg.corrections) { c in
                Text("\(c.original) → \(c.corrected)")
                    .font(.system(.caption, design: .rounded))
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
