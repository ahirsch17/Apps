import Foundation
import UIKit

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
    /// Corrections for the learner's last turn — Call UI surfaces these without extra chrome.
    @Published var latestCorrections: [Correction] = []
    @Published var mode: Mode = .call

    let speech = SpeechRecognitionService()
    let tts = SpeechSynthesisService()
    private let api = OpenAIService()
    private var settings: SettingsStore?

    private var callMessages: [ChatMessage] = []
    private var textMessages: [ChatMessage] = []
    private var callTurnCount = 0
    private var textTurnCount = 0
    private var handlingSpeech = false
    /// Bumped to invalidate in-flight tutor speech / listen loops (hang up, mode switch).
    private var sessionEpoch = 0
    private let maxTurnsBeforeNudge = 8
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var character: TutorCharacter { settings?.character ?? .forLanguage(.spanish) }
    var isInCall: Bool { mode == .call && phase != .idle && phase != .report }
    /// Text tab should not yank an active call into a new session.
    var isCallBlockingText: Bool { isInCall }

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
        haptic.prepare()
    }

    // MARK: - Start / End

    func startCall() async {
        persistActiveBuffer()
        mode = .call
        messages = callMessages
        turnCount = callTurnCount
        latestCorrections = []
        await beginSession(opening: true)
    }

    func startText() async {
        guard !isCallBlockingText else {
            error = "Finish or end your call first — then Text is free to use."
            return
        }
        persistActiveBuffer()
        mode = .text
        messages = textMessages
        turnCount = textTurnCount
        latestCorrections = []
        await beginSession(opening: true)
    }

    /// Used by Text tab on appear — won't clobber an active call or restart a live text chat.
    func startTextIfNeeded() async {
        if isCallBlockingText { return }
        if mode == .text, phase == .thinking || phase == .tutorSpeaking || phase == .connecting { return }
        if mode == .text, phase == .listening { return }

        if mode != .text {
            persistActiveBuffer()
            mode = .text
            messages = textMessages
            turnCount = textTurnCount
            latestCorrections = []
            error = nil
            phase = .idle
        }

        if !messages.isEmpty { return }
        await startText()
    }

    func hangUp() async {
        handlingSpeech = false
        sessionEpoch += 1
        speech.stopListening(cancel: true)
        tts.stop(invokeFinish: false)
        await generateReport()
    }

    /// Tap-to-jump-in during tutor speech — no extra button.
    func interruptTutor() {
        guard phase == .tutorSpeaking else { return }
        // Finishes the speak await so the normal path starts listening.
        tts.stop(invokeFinish: true)
    }

    /// "Skip / I blanked" — send a minimal attempt so learning-by-failing still happens.
    func skipTrySomething() async {
        guard phase == .listening || phase == .tutorSpeaking else { return }
        sessionEpoch += 1
        tts.stop(invokeFinish: false)
        speech.stopListening(cancel: true)
        await handleUserSpeech("[BLANK] I froze — please give me a simple starter and keep going.")
    }

    func dismissReport() {
        report = nil
        if mode == .call {
            callMessages = []
            callTurnCount = 0
        } else {
            textMessages = []
            textTurnCount = 0
        }
        messages = []
        turnCount = 0
        latestCorrections = []
        phase = .idle
        handlingSpeech = false
    }

    func sendText(_ text: String) async {
        guard !isCallBlockingText else { return }
        if mode != .text {
            persistActiveBuffer()
            mode = .text
            messages = textMessages
            turnCount = textTurnCount
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await handleUserSpeech(trimmed)
    }

    // MARK: - Core loop

    private func persistActiveBuffer() {
        if mode == .call {
            callMessages = messages
            callTurnCount = turnCount
        } else {
            textMessages = messages
            textTurnCount = turnCount
        }
    }

    private func beginSession(opening: Bool) async {
        guard let settings, settings.hasAPIKey else {
            error = "Add your OpenAI key in Profile to start."
            return
        }
        messages = []
        if mode == .call { callMessages = []; callTurnCount = 0 }
        else { textMessages = []; textTurnCount = 0 }
        report = nil
        turnCount = 0
        latestCorrections = []
        error = nil
        handlingSpeech = false
        sessionEpoch += 1
        let epoch = sessionEpoch
        phase = .connecting
        speech.prepare(for: settings.language)

        do {
            let turn = try await requestTurn(userText: "[SESSION_START] Greet me briefly as \(character.name) and ask one easy question. Keep it conversational.")
            guard epoch == sessionEpoch else { return }
            await applyTutor(turn, speak: mode == .call || settings.autoSpeak, epoch: epoch)
        } catch {
            guard epoch == sessionEpoch else { return }
            self.error = error.localizedDescription
            phase = .idle
        }
    }

    private func handleUserSpeech(_ text: String) async {
        guard let settings, settings.hasAPIKey else { return }
        guard !handlingSpeech else { return }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            if mode == .call { await resumeListening(epoch: sessionEpoch) }
            return
        }

        handlingSpeech = true
        defer { handlingSpeech = false }

        let epoch = sessionEpoch
        phase = .thinking
        liveTranscript = ""
        latestCorrections = []

        let blank = cleaned.hasPrefix("[BLANK]")
        messages.append(ChatMessage(role: .user, text: blank ? "…" : cleaned))
        turnCount += 1
        persistActiveBuffer()

        do {
            let turn = try await requestTurn(userText: cleaned)
            guard epoch == sessionEpoch else { return }
            await applyTutor(turn, speak: mode == .call || settings.autoSpeak, epoch: epoch)
            if turn.shouldWrapUp == true, epoch == sessionEpoch {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard epoch == sessionEpoch else { return }
                await generateReport()
            }
        } catch {
            guard epoch == sessionEpoch else { return }
            self.error = error.localizedDescription
            phase = mode == .call ? .listening : .idle
            if mode == .call { await resumeListening(epoch: epoch) }
        }
    }

    private func applyTutor(_ turn: TutorTurn, speak: Bool, epoch: Int) async {
        guard epoch == sessionEpoch else { return }
        let corrections = (turn.corrections ?? []).map { $0.asCorrection() }
        if let last = messages.indices.last, messages[last].role == .user, !corrections.isEmpty {
            let m = messages[last]
            messages[last] = ChatMessage(id: m.id, role: m.role, text: m.text, corrections: corrections, createdAt: m.createdAt)
        }
        latestCorrections = corrections
        messages.append(ChatMessage(role: .tutor, text: turn.reply))
        persistActiveBuffer()

        if speak {
            phase = .tutorSpeaking
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                tts.speak(turn.reply, language: settings?.language ?? .spanish) {
                    cont.resume()
                }
            }
        }

        guard epoch == sessionEpoch else { return }
        if mode == .call && turn.shouldWrapUp != true && phase != .report {
            await resumeListening(epoch: epoch)
        } else if mode == .text {
            phase = .idle
        }
    }

    private func resumeListening(epoch: Int) async {
        guard mode == .call else { return }
        guard epoch == sessionEpoch else { return }
        guard phase != .report else { return }
        phase = .listening
        liveTranscript = ""
        speech.transcript = ""
        haptic.impactOccurred()
        do {
            try speech.startListening(style: .call)
        } catch {
            self.error = error.localizedDescription
        }
        Task {
            while epoch == sessionEpoch && phase == .listening && speech.isListening {
                liveTranscript = speech.transcript
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
    }

    private func requestTurn(userText: String) async throws -> TutorTurn {
        guard let settings else { throw OpenAIError.missingKey }
        let character = self.character
        let channel = mode == .call ? "on a voice call" : "texting"
        let system = """
        You are \(character.name), a real person the learner is \(channel) with to practice \(settings.language.langLabel).
        Vibe: \(character.vibe)
        Level: \(settings.level.title) — \(settings.level.guidance)
        Topic: \(settings.topic.title)

        Teaching style:
        - Prefer getting them talking over perfect accuracy. Never shame.
        - Keep replies short (1–3 sentences in \(settings.language.langLabel) only). End with one clear question unless wrapping up.
        - Corrections are for LEARNING: only include mistakes that matter (wrong tense, englishLeak, key vocab). Max 2. Skip nitpicks.
        - For each correction, explanation must be one short English tip the learner can reuse next turn.
        - If they were close, still correct the important bit — silent perfectionism teaches nothing.
        - If they send [BLANK] or "…", warmly give a short model answer they can shadow, then ask something easier.

        After roughly \(maxTurnsBeforeNudge) learner turns, start wrapping up naturally and set shouldWrapUp true on your final turn.

        Return ONLY JSON:
        {
          "reply": "your message in \(settings.language.langLabel) only",
          "corrections": [{"type":"tense|grammar|vocabulary|englishLeak|pronunciation","original":"...","corrected":"...","explanation":"short English tip"}],
          "starters": [],
          "shouldWrapUp": false,
          "encouragement": null
        }
        Empty corrections array only when the learner's line was solid.
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
        tts.stop(invokeFinish: false)
        phase = .thinking
        persistActiveBuffer()
        guard let settings, settings.hasAPIKey else {
            phase = .idle
            return
        }

        let transcript = messages.map { "\($0.role == .user ? "Learner" : character.name): \($0.text)" }.joined(separator: "\n")
        let correctionNotes = messages.flatMap(\.corrections).prefix(6).map {
            "\($0.original) → \($0.corrected) (\($0.explanation))"
        }.joined(separator: "; ")

        let system = """
        You coach speaking practice. Given a short conversation transcript, return JSON only:
        {
          "summary": "2 sentences on how the chat went",
          "strengths": ["up to 3 short strengths"],
          "focusNext": ["up to 3 concrete things to practice next time — actionable"],
          "keyPhrases": ["up to 5 useful target-language phrases from the chat they should reuse"],
          "scoreLabel": "one of: Getting started | Finding flow | Solid chat | Crushing it"
        }
        Be encouraging and specific. Explanations in English; keyPhrases in \(settings.language.langLabel).
        Noted corrections this session: \(correctionNotes.isEmpty ? "none logged" : correctionNotes)
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
            self.error = error.localizedDescription
            phase = .idle
            messages = []
            if mode == .call { callMessages = []; callTurnCount = 0 }
            else { textMessages = []; textTurnCount = 0 }
        }
    }
}
