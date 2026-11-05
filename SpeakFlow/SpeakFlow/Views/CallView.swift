import SwiftUI

struct CallHomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var conversation: ConversationController
    var onNeedKey: () -> Void

    var body: some View {
        Group {
            if conversation.phase == .report, conversation.report != nil, conversation.mode == .call {
                CallReportView()
            } else if conversation.isInCall || (conversation.mode == .call && conversation.phase == .connecting) {
                ActiveCallView()
            } else {
                preCall
            }
        }
    }

    private var preCall: some View {
        ZStack {
            SF.ink.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                TutorMark(name: settings.character.name, size: 140)
                Text(settings.character.name)
                    .font(SF.display(34))
                    .foregroundStyle(.white)
                Text(settings.character.vibe)
                    .font(SF.ui(17))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                Text("\(settings.language.displayName)  ·  \(settings.talkLevel.title)  ·  \(settings.topic.title)")
                    .font(SF.ui(15))
                    .foregroundStyle(.white.opacity(0.72))
                Text(settings.talkLevel.blurb)
                    .font(SF.ui(13))
                    .foregroundStyle(.white.opacity(0.45))

                if let err = conversation.error {
                    Text(err).font(.footnote).foregroundStyle(SF.coral).padding(.horizontal)
                }

                Spacer()

                if settings.hasAPIKey {
                    Button("Start talk") {
                        Task { await conversation.startCall() }
                    }
                    .buttonStyle(StampButton())
                    .padding(.horizontal, 32)
                    Text("No button after this. A short pause stays with you. Notes wait until the end.")
                        .font(SF.ui(13))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 12) {
                        Text("Call needs your OpenAI key")
                            .font(SF.uiBold(17))
                            .foregroundStyle(.white)
                        Text("Practice works with no key. Paste a key in You to unlock live calls.")
                            .font(SF.ui(15))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        Button("Open You", action: onNeedKey)
                            .buttonStyle(StampButton(filled: false))
                    }
                    .padding(.horizontal, 24)
                }
                Spacer().frame(height: 24)
            }
        }
    }

}

struct ActiveCallView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var conversation: ConversationController
    @State private var showCoach = false

    var body: some View {
        ZStack {
            SF.ink.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text(statusLabel)
                        .font(SF.uiBold(15))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(conversation.turnCount) turns")
                        .font(SF.ui(13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                Button {
                    conversation.interruptTutor()
                } label: {
                    TutorMark(
                        name: settings.character.name,
                        active: conversation.phase == .tutorSpeaking || conversation.phase == .listening,
                        size: 160
                    )
                }
                .buttonStyle(.plain)
                .disabled(conversation.phase != .tutorSpeaking)
                .accessibilityLabel(conversation.phase == .tutorSpeaking ? "Tap to jump in" : settings.character.name)

                Text(settings.character.name)
                    .font(SF.display(28))
                    .foregroundStyle(.white)

                if conversation.phase == .tutorSpeaking {
                    Text("Tap them to jump in")
                        .font(SF.ui(13))
                        .foregroundStyle(.white.opacity(0.45))
                        .transition(.opacity)
                }

                if let last = conversation.messages.last(where: { $0.role == .tutor }) {
                    Text(last.text)
                        .font(SF.display(20))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .transition(.opacity)
                }

                if conversation.phase == .listening {
                    VStack(spacing: 8) {
                        Text(conversation.liveTranscript.isEmpty ? "Listening… just talk" : conversation.liveTranscript)
                            .font(SF.ui(17))
                            .foregroundStyle(SF.mint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .animation(.easeInOut, value: conversation.liveTranscript)
                        Text("A short pause stays open")
                            .font(SF.ui(11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } else if conversation.phase == .thinking || conversation.phase == .connecting {
                    ProgressView().tint(SF.mint)
                }

                Spacer()

                HStack(spacing: 36) {
                    Button {
                        Task { await conversation.skipTrySomething() }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .frame(width: 64, height: 64)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                            Text("Blanked").font(SF.ui(11))
                        }
                        .foregroundStyle(.white)
                    }

                    Button {
                        Task { await conversation.hangUp() }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "phone.down.fill")
                                .font(.title)
                                .frame(width: 76, height: 76)
                                .background(SF.coral)
                                .clipShape(Circle())
                            Text("End").font(SF.ui(11))
                        }
                        .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 36)
            }

            if showCoach {
                callCoach
            }
        }
        .animation(.easeOut(duration: 0.25), value: conversation.latestCorrections)
        .animation(.easeOut(duration: 0.2), value: conversation.phase)
        .onAppear {
            if !settings.hasSeenCallCoach {
                showCoach = true
            }
        }
        .onChange(of: conversation.phase) { _, phase in
            // Auto-dismiss coach once they reach their first listening turn.
            if phase == .listening, showCoach {
                dismissCoach()
            }
        }
    }

    private var callCoach: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { dismissCoach() }

            VStack(spacing: 14) {
                Text("Quick tip")
                    .font(SF.label(12))
                    .foregroundStyle(SF.mint)
                Text("Talk naturally. A short pause stays open, and it sends when the sentence is done.\nFrozen? Hit Blanked. Jump in anytime by tapping \(settings.character.name).")
                    .font(SF.ui(17))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Tap anywhere")
                    .font(SF.ui(15))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(SF.ink)
            .overlay(Rectangle().stroke(SF.line, lineWidth: 1))
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }

    private func dismissCoach() {
        withAnimation(.easeOut(duration: 0.2)) { showCoach = false }
        settings.hasSeenCallCoach = true
    }

    private var statusLabel: String {
        switch conversation.phase {
        case .connecting: return "Connecting…"
        case .tutorSpeaking: return "\(settings.character.name) is talking"
        case .listening: return "Your turn — speak"
        case .thinking: return "Thinking…"
        default: return "On call"
        }
    }
}

struct CallReportView: View {
    @EnvironmentObject private var conversation: ConversationController

    var body: some View {
        NavigationStack {
            ScrollView {
                if let r = conversation.report {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(r.scoreLabel)
                            .font(SF.display(40))
                            .foregroundStyle(SF.mint)
                        Text(r.summary)
                            .font(SF.ui(17))
                            .foregroundStyle(.secondary)

                        section("What worked", r.strengths, SF.mint)
                        section("Practice next", r.focusNext, SF.coral)
                        section("Steal these phrases", r.keyPhrases.map { item in
                            if let meaning = item.meaning, !meaning.isEmpty {
                                return "\(item.phrase) — \(meaning)"
                            }
                            return item.phrase
                        }, SF.teal)
                    }
                    .padding()
                }
            }
            .background(SF.tealDeep.ignoresSafeArea())
            .navigationTitle("Recap")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { conversation.dismissReport() }
                }
            }
        }
    }

    private func section(_ title: String, _ items: [String], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(SF.uiBold(17)).foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(SF.ui(17))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }
}
