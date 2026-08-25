import SwiftUI

struct CallHomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var conversation: ConversationController
    var onNeedKey: () -> Void

    var body: some View {
        Group {
            if conversation.phase == .report, conversation.report != nil {
                CallReportView()
            } else if conversation.isInCall || conversation.phase == .connecting {
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
                    chip(settings.level.title)
                    chip(settings.topic.title)
                }

                if let err = conversation.error {
                    Text(err).font(.footnote).foregroundStyle(SF.coral).padding(.horizontal)
                }

                Spacer()

                if settings.hasAPIKey {
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

                PulseAvatar(
                    emoji: settings.character.emoji,
                    color: settings.character.color,
                    isActive: conversation.phase == .tutorSpeaking || conversation.phase == .listening,
                    size: 160
                )
                Text(settings.character.name)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                // Last tutor line
                if let last = conversation.messages.last(where: { $0.role == .tutor }) {
                    Text(last.text)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
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
                        Text("Pause when you're done — it'll catch it")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } else if conversation.phase == .thinking || conversation.phase == .connecting {
                    ProgressView().tint(SF.mint)
                }

                // Latest correction peek
                if let corr = conversation.messages.last(where: { !$0.corrections.isEmpty })?.corrections.first {
                    Text("↳ \(corr.original) → \(corr.corrected)")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(SF.coral)
                        .padding(.horizontal, 20)
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
        }
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
                        section("Steal these phrases", r.keyPhrases, SF.teal)
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

    private func section(_ title: String, _ items: [String], _ color: Color) -> some View {
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
