import AVFoundation
import Foundation
import Speech

/// Continuous listening with adaptive silence-based end-of-utterance (hands-free).
@MainActor
final class SpeechRecognitionService: ObservableObject {
    enum SessionStyle {
        /// Call mode — voice processing / echo cancellation so the tutor speaker is less likely to get transcribed.
        case call
        /// Short drills / general capture.
        case drill
    }

    /// How long a pause has to last before the line is sent.
    enum ListenPace {
        /// Practice cards. A recognition "final" ends the line.
        case drill
        /// Hands-free talk. A short breath does not send.
        case sentence
        /// Paced chat. They may be thinking between clauses.
        case patient
    }

    @Published var transcript = ""
    @Published private(set) var isListening = false
    @Published private(set) var isAuthorized = false

    /// Fired when user seems done speaking (silence after speech).
    var onUtteranceComplete: ((String) -> Void)?
    /// Fired when the recognizer dies and a restart did not bring it back.
    var onListenFailed: ((String) -> Void)?

    private var engine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var lastChange = Date()
    private var speechBeganAt: Date?
    private var style: SessionStyle = .drill
    private var pace: ListenPace = .drill
    /// Words already accepted before the recognizer ended a segment early.
    private var carried = ""
    private var lastHints: [String] = []
    private var lastTaskHint: SFSpeechRecognitionTaskHint = .dictation
    private var finishing = false
    private var lastHold = Date.distantPast
    /// Bumps whenever a session starts or stops, so a cancelled task cannot finish the next one.
    private var generation = 0
    /// How many times this session has been restarted after an empty or failed task.
    private var restarts = 0

    func requestPermissions() async {
        let speech: Bool = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { s in c.resume(returning: s == .authorized) }
        }
        let mic: Bool = await withCheckedContinuation { c in
            AVAudioApplication.requestRecordPermission { c.resume(returning: $0) }
        }
        isAuthorized = speech && mic
    }

    func prepare(for language: Language) {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.localeID))
        if language == .tagalog, recognizer?.isAvailable != true {
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tl-PH"))
        }
    }

    func startListening(
        style: SessionStyle = .drill,
        hints: [String] = [],
        taskHint: SFSpeechRecognitionTaskHint = .dictation,
        continuing: Bool = false,
        pace: ListenPace = .drill
    ) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition unavailable"])
        }
        let saved = transcript
        let savedChange = lastChange
        let savedBegan = speechBeganAt
        stopListening(cancel: true, resetCarry: !continuing)
        let generation = generation
        self.style = style
        self.pace = continuing ? self.pace : pace
        if continuing {
            carried = saved
            transcript = saved
            lastChange = savedChange
            speechBeganAt = savedBegan
        }
        lastHints = hints
        lastTaskHint = taskHint
        finishing = false
        if !continuing {
            transcript = ""
            carried = ""
            lastChange = Date()
            speechBeganAt = nil
        }

        let session = AVAudioSession.sharedInstance()
        switch style {
        case .call:
            // voiceChat enables better echo cancellation so TTS is less likely to be heard as the user.
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        case .drill:
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        }
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true
        request.taskHint = taskHint
        let bias = hints.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !bias.isEmpty { request.contextualStrings = bias }
        if #available(iOS 16, *) { request.addsPunctuation = true }

        let input = engine.inputNode
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self, self.generation == generation, !self.finishing else { return }
                if let result {
                    let segment = result.bestTranscription.formattedString
                    let text = self.joined(segment)
                    if text != self.transcript {
                        if self.speechBeganAt == nil, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.speechBeganAt = Date()
                        }
                        self.transcript = text
                        self.lastChange = Date()
                        if !result.isFinal { self.armSilenceTimer() }
                    }
                    if result.isFinal {
                        self.handleSegmentEnd()
                        return
                    }
                }
                if error != nil, result == nil {
                    if self.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.recoverAfterEnd()
                    } else if self.pace == .drill {
                        self.finishUtterance(taskEnded: true)
                    } else {
                        self.holdAndContinue()
                    }
                }
            }
        }

        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw error
        }
        isListening = true
        if !continuing { restarts = 0 }
    }

    /// Send whatever has been said. Chat uses this when they tap Done.
    func commitUtterance() {
        finishUtterance()
    }

    func stopListening(cancel: Bool = false, resetCarry: Bool = true) {
        generation += 1
        silenceTask?.cancel()
        silenceTask = nil
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        if cancel { task?.cancel() }
        request?.endAudio()
        request = nil
        task = nil
        isListening = false
        if resetCarry {
            carried = ""
            speechBeganAt = nil
            pace = .drill
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// A one-second breath used to send the line. Talk and Chat wait out a real stop.
    private func silenceThreshold() -> TimeInterval {
        switch pace {
        case .sentence: return 2.6
        case .patient: return 3.2
        case .drill:
            let words = transcript.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
            switch words {
            case 0...1: return 2.15
            case 2...4: return 1.75
            default: return 1.4
            }
        }
    }

    private func armSilenceTimer() {
        silenceTask?.cancel()
        let wait = silenceThreshold()
        let changedAt = lastChange
        silenceTask = Task { [weak self] in
            let elapsed = Date().timeIntervalSince(changedAt)
            let remain = max(0.05, wait - elapsed)
            try? await Task.sleep(nanoseconds: UInt64(remain * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                let needed = self.silenceThreshold()
                guard Date().timeIntervalSince(self.lastChange) >= needed - 0.05 else { return }
                if let began = self.speechBeganAt, Date().timeIntervalSince(began) < 0.55 {
                    self.armSilenceTimer()
                    return
                }
                self.finishUtterance()
            }
        }
    }

    /// The recognizer often marks a segment final on a short pause. In talk and chat that is not the end of the sentence.
    private func handleSegmentEnd() {
        if pace == .drill {
            finishUtterance(taskEnded: true)
            return
        }
        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            recoverAfterEnd()
            return
        }
        holdAndContinue()
    }

    private func joined(_ segment: String) -> String {
        let piece = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = carried.trimmingCharacters(in: .whitespacesAndNewlines)
        if piece.isEmpty { return base }
        if base.isEmpty { return piece }
        if piece.hasPrefix(base) { return piece }
        return base + " " + piece
    }

    /// Keep the mic open and the words already heard. The silence clock is not reset.
    private func holdAndContinue() {
        let now = Date()
        if now.timeIntervalSince(lastHold) < 0.35 {
            let wait = 0.35 - now.timeIntervalSince(lastHold)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                guard !self.finishing, self.pace != .drill else { return }
                self.holdAndContinue()
            }
            return
        }
        lastHold = now
        let saved = transcript
        let savedChange = lastChange
        let savedBegan = speechBeganAt
        do {
            try startListening(style: style, hints: lastHints, taskHint: lastTaskHint, continuing: true, pace: pace)
            carried = saved
            transcript = saved
            lastChange = savedChange
            speechBeganAt = savedBegan
            armSilenceTimer()
        } catch {
            onListenFailed?(error.localizedDescription)
        }
    }

    private func finishUtterance(taskEnded: Bool = false) {
        guard !finishing else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = text.lowercased().trimmingCharacters(in: .punctuationCharacters)
        let fillers: Set<String> = ["um", "uh", "eh", "ah", "er", "mm", "hmm", "mhm"]
        // "um" or a blank final result used to return here and leave the task dead.
        if text.isEmpty || fillers.contains(compact) {
            if taskEnded { recoverAfterEnd() }
            return
        }
        finishing = true
        stopListening(cancel: false)
        onUtteranceComplete?(text)
    }

    /// The recognition task ended before a real line. Open the mic again, a couple of times.
    private func recoverAfterEnd() {
        guard !finishing else { return }
        restarts += 1
        if restarts > 2 {
            stopListening(cancel: true)
            onListenFailed?("The mic stopped. Try again.")
            return
        }
        let style = style
        let hints = lastHints
        let hint = lastTaskHint
        do {
            try startListening(style: style, hints: hints, taskHint: hint, continuing: true)
        } catch {
            onListenFailed?(error.localizedDescription)
        }
    }
}
