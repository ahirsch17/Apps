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
            LinearGradient(colors: [settings.character.color.opacity(0.35), SF.tealDeep, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                PulseAvatar(emoji: settings.character.emoji, color: settings.character.color, isActive: false, size: 150)
                Text(settings.character.name)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(settings.character.vibe)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                HStack(spacing: 10) {
                    chip(settings.language.flag + " " + settings.language.displayName)
                    Menu {
                        Picker("Level", selection: $settings.level) {
                            ForEach(ConversationLevel.allCases) { Text("\($0.title) — \($0.blurb)").tag($0) }
                        }
                    } label: {
                        chip(settings.level.title + " ▾")
                    }
                    Menu {
                        Picker("Topic", selection: $settings.topic) {
                            ForEach(ConversationTopic.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                        }
                    } label: {
                        chip(settings.topic.title + " ▾")
                    }
                }

                if let err = conversation.error {
                    Text(err).font(.footnote).foregroundStyle(SF.coral).padding(.horizontal)
                }

                Spacer()

                if !speechSupported {
                    VStack(spacing: 8) {
                        Text("Voice calls aren't available for \(settings.language.displayName) yet")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Apple's speech recognition doesn't support it on iPhone. Text \(settings.character.name) instead — same tutor, same corrections.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 24)
                } else if settings.hasAPIKey {
                    Button {
                        Task { await conversation.startCall() }
                    } label: {
                        Label("Start call", systemImage: "phone.fill")
                            .font(.system(.headline, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(SF.mint)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 32)
                    Text("Hands-free — just talk. Silence sends.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                } else {
                    VStack(spacing: 12) {
                        Text("Call needs your OpenAI key")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Learn tab works free. Paste a key in Profile to unlock live calls.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        Button("Open Profile", action: onNeedKey)
                            .buttonStyle(.borderedProminent)
                            .tint(SF.coral)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 24)
                }
                Spacer().frame(height: 24)
            }
        }
    }

    private var speechSupported: Bool { SpeechRecognitionService.supports(settings.language) }

    private func chip(_ t: String) -> some View {
        Text(t)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.12))
            .clipShape(Capsule())
            .foregroundStyle(.white)
    }
}

struct ActiveCallView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var conversation: ConversationController
    @State private var showCoach = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [settings.character.color.opacity(0.45), SF.tealDeep, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text(statusLabel)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(conversation.turnCount) turns")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                Button {
                    conversation.interruptTutor()
                } label: {
                    PulseAvatar(
                        emoji: settings.character.emoji,
                        color: settings.character.color,
                        isActive: conversation.phase == .tutorSpeaking || conversation.phase == .listening,
                        size: 160
                    )
                }
                .buttonStyle(.plain)
                .disabled(conversation.phase != .tutorSpeaking)
                .accessibilityLabel(conversation.phase == .tutorSpeaking ? "Tap to jump in" : settings.character.name)

                Text(settings.character.name)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                if conversation.phase == .tutorSpeaking {
                    Text("Tap them to jump in")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .transition(.opacity)
                }

                if let last = conversation.messages.last(where: { $0.role == .tutor }) {
                    VStack(spacing: 6) {
                        Text(last.text)
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        if settings.showTranslations, let translation = last.translation {
                            Text(translation)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .transition(.opacity)
                }

                if conversation.phase == .listening {
                    VStack(spacing: 8) {
                        Text(conversation.liveTranscript.isEmpty ? "Listening… just talk" : conversation.liveTranscript)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(SF.mint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .animation(.easeInOut, value: conversation.liveTranscript)
                        if conversation.liveTranscript.isEmpty, let starter = conversation.latestStarters.first {
                            Text("Try: “\(starter)”")
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        Text("Pause when you're done — it'll catch it")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } else if conversation.phase == .thinking || conversation.phase == .connecting {
                    ProgressView().tint(SF.mint)
                }

                if !conversation.latestCorrections.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try next time")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundStyle(SF.coral.opacity(0.9))
                        ForEach(conversation.latestCorrections.prefix(2)) { c in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(c.original) → \(c.corrected)")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(c.explanation)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                HStack(spacing: 28) {
                    Button {
                        Task { await conversation.replayLastTutorLine() }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "gobackward")
                                .font(.title2)
                                .frame(width: 64, height: 64)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                            Text("Say again").font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(.white)
                    }
                    .disabled(!conversation.canReplayInCall)
                    .opacity(conversation.canReplayInCall ? 1 : 0.4)
                    .accessibilityLabel("Repeat that slower")

                    Button {
                        Task { await conversation.skipTrySomething() }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .frame(width: 64, height: 64)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                            Text("Blanked").font(.system(.caption2, design: .rounded))
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
                                .shadow(color: SF.coral.opacity(0.5), radius: 12)
                            Text("End").font(.system(.caption2, design: .rounded))
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
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(SF.mint)
                Text("Talk naturally. When you pause, it sends.\nFrozen? Hit Blanked. Missed it? Say again replays slower. Jump in anytime by tapping \(settings.character.name).")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Tap anywhere")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundStyle(SF.mint)
                        Text(r.summary)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)

                        section("What worked", r.strengths, SF.mint)
                        section("Practice next", r.focusNext, SF.coral)
                        section("Steal these phrases", r.keyPhrases.map { (p: KeyPhrase) -> String in
                            if let meaning = p.meaning, !meaning.isEmpty { return "\(p.phrase) — \(meaning)" }
                            return p.phrase
                        }, SF.teal)

                        if conversation.savedThisSession > 0 {
                            Label(
                                "\(conversation.savedThisSession) phrase\(conversation.savedThisSession == 1 ? "" : "s") saved to Review in the Learn tab",
                                systemImage: "rectangle.stack.badge.plus"
                            )
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(SF.mint)
                        }
                    }
                    .padding()
                }
            }
            .background(SF.tealDeep.ignoresSafeArea())
            .navigationTitle("Call recap")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { conversation.dismissReport() }
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [String], _ color: Color) -> some View {
        if !items.isEmpty {
            sectionCard(title, items, color)
        }
    }

    private func sectionCard(_ title: String, _ items: [String], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(.headline, design: .rounded)).foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
