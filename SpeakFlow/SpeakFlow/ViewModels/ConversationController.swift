import Foundation

@MainActor
final class ConversationController: ObservableObject {
    enum Mode { case call, text }
    enum Phase: Equatable {
        case idle
        case connecting
        case tutorSpeaking
        case listening
        case thinking
        case report
    }

    @Published var messages: [ChatMessage] = []
    @Published var phase: Phase = .idle
    @Published var liveTranscript = ""
    @Published var error: String?
    @Published var report: CallReport?
    @Published var turnCount = 0

    let speech = SpeechRecognitionService()
    let tts = SpeechSynthesisService()
    private let api = OpenAIService()
    private var settings: SettingsStore?
    private var mode: Mode = .call
    private let maxTurnsBeforeNudge = 8

    var character: TutorCharacter { settings?.character ?? .forLanguage(.spanish) }
    var isInCall: Bool { phase != .idle && phase != .report }

    func bind(_ settings: SettingsStore) {
        self.settings = settings
        speech.prepare(for: settings.language)
        speech.onUtteranceComplete = { [weak self] text in
            Task { await self?.handleUserSpeech(text) }
        }
    }

    func prepareAudio() async {
        await speech.requestPermissions()
        speech.prepare(for: settings?.language ?? .spanish)
    }

    // MARK: - Start / End

    func startCall() async {
        mode = .call
        await beginSession(opening: true)
    }

    func startText() async {
        mode = .text
        await beginSession(opening: true)
    }

    func hangUp() async {
        speech.stopListening(cancel: true)
        tts.stop()
        await generateReport()
    }

    /// "Skip / I blanked" — send a minimal attempt so learning-by-failing still happens.
    func skipTrySomething() async {
        guard phase == .listening || phase == .tutorSpeaking else { return }
        tts.stop()
        speech.stopListening(cancel: true)
        await handleUserSpeech("[BLANK] I froze — please give me a simple starter and keep going.")
    }

    func dismissReport() {
        report = nil
        messages = []
        turnCount = 0
        phase = .idle
    }

    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await handleUserSpeech(trimmed)
    }

    // MARK: - Core loop

    private func beginSession(opening: Bool) async {
        guard let settings, settings.hasAPIKey else {
            error = "Add your OpenAI key in Profile to start."
            return
        }
        messages = []
        report = nil
        turnCount = 0
        error = nil
        phase = .connecting
        speech.prepare(for: settings.language)

        do {
            let turn = try await requestTurn(userText: "[SESSION_START] Greet me briefly as \(character.name) and ask one easy question. Keep it conversational.")
            await applyTutor(turn, speak: mode == .call || settings.autoSpeak)
        } catch {
            self.error = error.localizedDescription
            phase = .idle
        }
    }

    private func handleUserSpeech(_ text: String) async {
        guard let settings, settings.hasAPIKey else { return }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            await resumeListening()
            return
        }

        phase = .thinking
        liveTranscript = ""
        messages.append(ChatMessage(role: .user, text: cleaned == "[BLANK] I froze — please give me a simple starter and keep going." ? "…" : cleaned))
        turnCount += 1

        do {
            let turn = try await requestTurn(userText: cleaned)
            await applyTutor(turn, speak: mode == .call || settings.autoSpeak)
            if turn.shouldWrapUp == true || turnCount >= maxTurnsBeforeNudge + 2 {
                // Soft wrap — still show their last reply, then report after a beat if wrap flag set
                if turn.shouldWrapUp == true {
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    await generateReport()
                }
            }
        } catch {
            self.error = error.localizedDescription
            phase = mode == .call ? .listening : .idle
            if mode == .call { await resumeListening() }
        }
    }

    private func applyTutor(_ turn: TutorTurn, speak: Bool) async {
        let corrections = (turn.corrections ?? []).map { $0.asCorrection() }
        if let last = messages.indices.last, messages[last].role == .user, !corrections.isEmpty {
            let m = messages[last]
            messages[last] = ChatMessage(id: m.id, role: m.role, text: m.text, corrections: corrections, createdAt: m.createdAt)
        }
        messages.append(ChatMessage(role: .tutor, text: turn.reply))

        if speak {
            phase = .tutorSpeaking
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                tts.speak(turn.reply, language: settings?.language ?? .spanish) {
                    cont.resume()
                }
            }
        }

        if mode == .call && turn.shouldWrapUp != true {
            await resumeListening()
        } else if mode == .text {
            phase = .idle
        }
    }

    private func resumeListening() async {
        guard mode == .call else { return }
        phase = .listening
        liveTranscript = ""
        speech.transcript = ""
        do {
            try speech.startListening()
        } catch {
            self.error = error.localizedDescription
        }
        // Mirror live transcript
        Task {
            while phase == .listening && speech.isListening {
                liveTranscript = speech.transcript
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
    }

    private func requestTurn(userText: String) async throws -> TutorTurn {
        guard let settings else { throw OpenAIError.missingKey }
        let character = self.character
        let system = """
        You are \(character.name), a real person the learner is \(mode == .call ? "on a voice call" : "texting") with to practice \(settings.language.langLabel).
        Vibe: \(character.vibe)
        Level: \(settings.level.title) — \(settings.level.guidance)
        Topic: \(settings.topic.title)

        The learner freezes when speaking. Prefer getting them talking over perfect accuracy.
        If they send [BLANK] or "…", warmly give a short model answer they can shadow next, then ask something easier.

        After roughly \(maxTurnsBeforeNudge) learner turns, start wrapping up naturally (say goodbye soon) and set shouldWrapUp true on your final turn.

        Return ONLY JSON:
        {
          "reply": "your message in \(settings.language.langLabel) only — 1-3 short sentences, end with a question unless wrapping up",
          "corrections": [{"type":"tense|grammar|vocabulary|englishLeak|pronunciation","original":"...","corrected":"...","explanation":"short English tip"}],
          "starters": [],
          "shouldWrapUp": false,
          "encouragement": null
        }
        Empty corrections array if nothing to fix. Be kind. Never shame.
        """

        var history: [(role: String, content: String)] = []
        for m in messages.suffix(14) where m.role != .system {
            history.append((m.role == .user ? "user" : "assistant", m.text))
        }
        history.append(("user", userText))

        let content = try await api.chat(apiKey: settings.apiKey, model: settings.model, system: system, messages: history)
        return try api.decodeTurn(content)
    }

    private func generateReport() async {
        speech.stopListening(cancel: true)
        tts.stop()
        phase = .thinking
        guard let settings, settings.hasAPIKey else {
            phase = .idle
            return
        }

        let transcript = messages.map { "\($0.role == .user ? "Learner" : character.name): \($0.text)" }.joined(separator: "\n")
        let system = """
        You coach speaking practice. Given a short conversation transcript, return JSON only:
        {
          "summary": "2 sentences on how the chat went",
          "strengths": ["up to 3 short strengths"],
          "focusNext": ["up to 3 concrete things to practice"],
          "keyPhrases": ["up to 5 useful target-language phrases from the chat"],
          "scoreLabel": "one of: Getting started | Finding flow | Solid chat | Crushing it"
        }
        Be encouraging and specific. Explanations in English; keyPhrases in \(settings.language.langLabel).
        """

        do {
            let content = try await api.chat(
                apiKey: settings.apiKey,
                model: settings.model,
                system: system,
                messages: [("user", transcript.isEmpty ? "(No dialogue captured)" : transcript)],
                temperature: 0.5
            )
            report = try api.decodeReport(content)
            phase = .report
        } catch {
            // Still exit call even if report fails
            self.error = error.localizedDescription
            phase = .idle
            messages = []
        }
    }
}
