import AVFoundation
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
    /// Short things the learner could say next (shown as hints / tap-to-fill chips).
    @Published var latestStarters: [String] = []
    /// Phrases saved to the review deck this session (shown on the recap).
    @Published private(set) var savedThisSession = 0
    @Published var mode: Mode = .call

    let speech = SpeechRecognitionService()
    let tts = SpeechSynthesisService()
    private let api = OpenAIService()
    private var settings: SettingsStore?
    private var phrasebook: PhrasebookStore?

    private var callMessages: [ChatMessage] = []
    private var textMessages: [ChatMessage] = []
    private var callTurnCount = 0
    private var textTurnCount = 0
    /// Epoch of the learner turn being processed; bumping `sessionEpoch` frees it, so Blanked / hang up never get stuck behind an old turn.
    private var handlingEpoch: Int?
    /// Bumped to invalidate in-flight tutor speech / listen loops (hang up, mode switch).
    private var sessionEpoch = 0
    /// Consecutive recognition failures in a call — a few are normal (silence timeouts), many means the mic is gone.
    private var listenFailures = 0
    private let maxListenRetries = 3
    private let maxTurnsBeforeNudge = 8
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private var interruptionObserver: NSObjectProtocol?

    var character: TutorCharacter { settings?.character ?? .forLanguage(.spanish) }
    var isInCall: Bool { mode == .call && phase != .idle && phase != .report }
    /// Text tab should not yank an active call into a new session.
    var isCallBlockingText: Bool { isInCall }
    var canReplayInCall: Bool { mode == .call && phase == .listening && messages.contains { $0.role == .tutor } }

    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            Task { @MainActor in self?.handleAudioInterruption() }
        }
    }

    func bind(_ settings: SettingsStore, phrasebook: PhrasebookStore) {
        self.settings = settings
        self.phrasebook = phrasebook
        speech.prepare(for: settings.language)
        speech.onUtteranceComplete = { [weak self] text in
            Task { await self?.handleUserSpeech(text) }
        }
        speech.onError = { [weak self] message in
            Task { await self?.handleListeningFailure(message) }
        }
        haptic.prepare()
    }

    /// Switching language mid-chat would mix languages in history — start both modes fresh.
    func languageDidChange() {
        guard let settings else { return }
        sessionEpoch += 1
        handlingEpoch = nil
        speech.stopListening(cancel: true)
        tts.stop(invokeFinish: true)
        speech.endAudioSession()
        speech.prepare(for: settings.language)
        callMessages = []; textMessages = []
        callTurnCount = 0; textTurnCount = 0
        messages = []
        turnCount = 0
        latestCorrections = []
        latestStarters = []
        liveTranscript = ""
        report = nil
        error = nil
        phase = .idle
    }

    // MARK: - Start / End

    func startCall() async {
        guard let settings else { return }
        guard SpeechRecognitionService.supports(settings.language) else {
            error = SpeechRecognitionService.SpeechError.unsupported(settings.language).localizedDescription
            return
        }
        await speech.requestPermissions()
        guard speech.isAuthorized else {
            error = SpeechRecognitionService.SpeechError.notAuthorized.localizedDescription
            return
        }
        persistActiveBuffer()
        mode = .call
        messages = callMessages
        turnCount = callTurnCount
        latestCorrections = []
        latestStarters = []
        listenFailures = 0
        do {
            try speech.activateCallAudio()
        } catch {
            self.error = SpeechRecognitionService.SpeechError.noMicrophone.localizedDescription
            return
        }
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
        latestStarters = []
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
            latestStarters = []
            error = nil
            phase = .idle
        }

        if !messages.isEmpty { return }
        await startText()
    }

    func hangUp() async {
        handlingEpoch = nil
        sessionEpoch += 1
        speech.stopListening(cancel: true)
        tts.stop(invokeFinish: true)
        speech.endAudioSession()
        // Nothing said yet — no recap worth paying for.
        guard messages.contains(where: { $0.role == .user }) else {
            resetActiveSession()
            return
        }
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
        let canSkip: Bool
        switch mode {
        case .call: canSkip = phase == .listening || phase == .tutorSpeaking
        case .text: canSkip = (phase == .idle || phase == .tutorSpeaking) && !messages.isEmpty
        }
        guard canSkip else { return }
        sessionEpoch += 1
        tts.stop(invokeFinish: true)
        speech.stopListening(cancel: true)
        await handleUserSpeech("[BLANK] I froze — please give me a simple starter and keep going.")
    }

    /// "Say that again" in a call — replays the tutor's last line slower, then listens again.
    func replayLastTutorLine() async {
        guard canReplayInCall, let last = messages.last(where: { $0.role == .tutor }) else { return }
        let epoch = sessionEpoch
        speech.stopListening(cancel: true)
        phase = .tutorSpeaking
        await speak(last.text, slow: true)
        guard epoch == sessionEpoch else { return }
        await resumeListening(epoch: epoch)
    }

    /// Text mode: tap the speaker on a bubble.
    func speakMessage(_ message: ChatMessage) {
        guard mode == .text, let settings else { return }
        tts.speak(message.text, language: settings.language, slow: settings.slowSpeech)
    }

    func dismissReport() {
        report = nil
        resetActiveSession()
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

    private func resetActiveSession() {
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
        latestStarters = []
        liveTranscript = ""
        savedThisSession = 0
        phase = .idle
        handlingEpoch = nil
    }

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
        latestStarters = []
        savedThisSession = 0
        error = nil
        handlingEpoch = nil
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
            if mode == .call { speech.endAudioSession() }
        }
    }

    private func handleUserSpeech(_ text: String) async {
        guard let settings, settings.hasAPIKey else { return }
        guard handlingEpoch != sessionEpoch else { return }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            if mode == .call { await resumeListening(epoch: sessionEpoch) }
            return
        }

        let epoch = sessionEpoch
        handlingEpoch = epoch
        defer { if handlingEpoch == epoch { handlingEpoch = nil } }

        phase = .thinking
        liveTranscript = ""
        latestCorrections = []
        latestStarters = []
        listenFailures = 0
        error = nil

        let blank = cleaned.hasPrefix("[BLANK]")
        messages.append(ChatMessage(role: .user, text: blank ? "…" : cleaned))
        turnCount += 1
        persistActiveBuffer()
        if !blank { settings.recordPractice() }

        do {
            let turn = try await requestTurn(userText: cleaned)
            guard epoch == sessionEpoch else { return }
            await applyTutor(turn, speak: mode == .call || settings.autoSpeak, epoch: epoch)
            if turn.shouldWrapUp == true, epoch == sessionEpoch {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard epoch == sessionEpoch else { return }
                if mode == .call { speech.endAudioSession() }
                await generateReport()
            }
        } catch {
            guard epoch == sessionEpoch else { return }
            self.error = error.localizedDescription
            if mode == .call {
                await resumeListening(epoch: epoch)
            } else {
                phase = .idle
            }
        }
    }

    private func applyTutor(_ turn: TutorTurn, speak shouldSpeak: Bool, epoch: Int) async {
        guard epoch == sessionEpoch, let settings else { return }
        let corrections = (turn.corrections ?? []).map { $0.asCorrection() }
        if let last = messages.indices.last, messages[last].role == .user, !corrections.isEmpty {
            let m = messages[last]
            messages[last] = ChatMessage(id: m.id, role: m.role, text: m.text, corrections: corrections, createdAt: m.createdAt)
        }
        latestCorrections = corrections
        for c in corrections {
            saveToReview(phrase: c.corrected, prompt: "You said: “\(c.original)”", note: c.explanation, source: .correction)
        }

        let translation = turn.translation?.trimmingCharacters(in: .whitespacesAndNewlines)
        messages.append(ChatMessage(role: .tutor, text: turn.reply, translation: translation?.isEmpty == false ? translation : nil))
        latestStarters = Array((turn.starters ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2))
        persistActiveBuffer()

        if shouldSpeak {
            phase = .tutorSpeaking
            await speak(turn.reply, slow: settings.slowSpeech)
        }

        guard epoch == sessionEpoch else { return }
        if mode == .call && turn.shouldWrapUp != true && phase != .report {
            await resumeListening(epoch: epoch)
        } else if mode == .text {
            phase = .idle
        }
    }

    private func speak(_ text: String, slow: Bool) async {
        let language = settings?.language ?? .spanish
        let inCall = mode == .call
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            tts.speak(text, language: language, slow: slow, configuresSession: !inCall) {
                cont.resume()
            }
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
            await handleListeningFailure(error.localizedDescription)
            return
        }
        Task {
            while epoch == sessionEpoch && phase == .listening && speech.isListening {
                liveTranscript = speech.transcript
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
    }

    /// Recognition ended without usable speech (silence timeout, network blip). Quietly retry a few times, then stop.
    private func handleListeningFailure(_ message: String) async {
        guard mode == .call, phase == .listening else { return }
        listenFailures += 1
        if listenFailures <= maxListenRetries {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard phase == .listening else { return }
            await resumeListening(epoch: sessionEpoch)
            return
        }
        let note = "The mic stopped picking you up (\(message)) — call ended so you can try again."
        await hangUp()
        error = note
    }

    private func handleAudioInterruption() {
        guard isInCall else { return }
        sessionEpoch += 1
        handlingEpoch = nil
        speech.stopListening(cancel: true)
        tts.stop(invokeFinish: true)
        speech.endAudioSession()
        liveTranscript = ""
        phase = .idle
        error = "Call paused by another app or phone call. Start a new call when you're ready."
    }

    private func saveToReview(phrase: String, prompt: String, note: String, source: SavedPhrase.Source) {
        guard let settings, let phrasebook else { return }
        if phrasebook.add(phrase: phrase, prompt: prompt, note: note, language: settings.language, source: source) {
            savedThisSession += 1
        }
    }

    private func requestTurn(userText: String) async throws -> TutorTurn {
        guard let settings else { throw OpenAIError.missingKey }
        let character = self.character
        let isCall = mode == .call
        let channel = isCall ? "on a voice call" : "texting"
        let lang = settings.language.langLabel
        let starterRule: String
        switch settings.level {
        case .warmup, .beginner:
            starterRule = "Always give 2 very short starters the learner could say next."
        case .intermediate, .advanced:
            starterRule = "Give starters only after [BLANK] or when they're clearly stuck; otherwise []."
        }
        let transcriptNote = isCall
            ? "- The learner's lines are speech-to-text transcripts: ignore punctuation, capitalization and missing accent marks, and assume an odd word may be a mis-hearing. You cannot hear pronunciation — never correct it."
            : "- Ignore missing accent marks and capitalization unless they change the meaning."

        let system = """
        You are \(character.name), a real person the learner is \(channel) with to practice \(lang).
        Vibe: \(character.vibe)
        Level: \(settings.level.title) — \(settings.level.guidance)
        Topic: \(settings.topic.title)

        Teaching style:
        - Prefer getting them talking over perfect accuracy. Never shame.
        - Keep replies short (1–3 sentences in \(lang) only). End with one clear question unless wrapping up.
        - Corrections are for LEARNING: only include mistakes that matter (wrong tense, englishLeak, key vocab). Max 2. Skip nitpicks.
        - For each correction, "corrected" is the learner's whole sentence fixed, and explanation is one short English tip they can reuse next turn.
        - If they were close, still correct the important bit — silent perfectionism teaches nothing.
        - If they send [BLANK] or "…", warmly give a short model answer they can shadow, then ask something easier.
        \(transcriptNote)

        After roughly \(maxTurnsBeforeNudge) learner turns, start wrapping up naturally and set shouldWrapUp true on your final turn.

        Return ONLY JSON:
        {
          "reply": "your message in \(lang) only",
          "translation": "natural English translation of reply",
          "corrections": [{"type":"tense|grammar|vocabulary|englishLeak","original":"...","corrected":"...","explanation":"short English tip"}],
          "starters": ["short reply idea in \(lang)"],
          "shouldWrapUp": false,
          "encouragement": null
        }
        Empty corrections array only when the learner's line was solid. \(starterRule)
        """

        var prior = messages.filter { $0.role != .system }
        // The newest learner line is already in `messages` for the UI (as "…" for [BLANK]); it's sent once below as `userText`.
        if let last = prior.last, last.role == .user {
            prior.removeLast()
        }
        var history: [(role: String, content: String)] = prior.suffix(14).map {
            ($0.role == .user ? "user" : "assistant", $0.text)
        }
        history.append(("user", userText))

        let content = try await api.chat(apiKey: settings.apiKey, model: settings.model, system: system, messages: history)
        return try api.decodeTurn(content)
    }

    private func generateReport() async {
        speech.stopListening(cancel: true)
        tts.stop(invokeFinish: true)
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
          "keyPhrases": [{"phrase": "useful \(settings.language.langLabel) phrase from the chat", "meaning": "short English meaning"}],
          "scoreLabel": "one of: Getting started | Finding flow | Solid chat | Crushing it"
        }
        Up to 5 keyPhrases they should reuse. Be encouraging and specific. Explanations in English.
        Noted corrections this session: \(correctionNotes.isEmpty ? "none logged" : correctionNotes)
        """

        do {
            let content = try await api.chat(
                apiKey: settings.apiKey,
                model: settings.model,
                system: system,
                messages: [("user", transcript)],
                temperature: 0.5
            )
            let decoded = try api.decodeReport(content)
            for p in decoded.keyPhrases.prefix(5) {
                saveToReview(phrase: p.phrase, prompt: p.meaning ?? "Phrase from your chat", note: "", source: .recap)
            }
            report = decoded
            phase = .report
        } catch {
            // Keep the conversation — losing the whole chat because the recap failed is worse than no recap.
            self.error = "Couldn't build the recap (\(error.localizedDescription)). Your chat is still here."
            phase = .idle
        }
    }
}
