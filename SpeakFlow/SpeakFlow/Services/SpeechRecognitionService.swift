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

    enum SpeechError: LocalizedError {
        case unsupported(Language), unavailable, notAuthorized, noMicrophone

        var errorDescription: String? {
            switch self {
            case .unsupported(let language):
                return "Apple speech recognition doesn't support \(language.displayName) yet — use Text mode or Reveal instead."
            case .unavailable:
                return "Speech recognition is offline right now. Check your connection and try again."
            case .notAuthorized:
                return "Turn on Microphone and Speech Recognition for SpeakFlow in Settings."
            case .noMicrophone:
                return "Couldn't open the microphone. Unplug or reconnect headphones and try again."
            }
        }
    }

    @Published var transcript = ""
    @Published private(set) var isListening = false
    @Published private(set) var isAuthorized = false

    /// Fired when user seems done speaking (silence after speech).
    var onUtteranceComplete: ((String) -> Void)?
    /// Fired when recognition dies with nothing usable captured (timeout, network drop, no speech).
    var onError: ((String) -> Void)?

    private var engine = AVAudioEngine()
    private var language: Language = .spanish
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var lastChange = Date()
    private var speechBeganAt: Date?
    private var style: SessionStyle = .drill
    private var finishing = false
    private var tapInstalled = false
    /// Bumped on every start/stop so late callbacks from an old recognition task are ignored.
    private var generation = 0

    nonisolated static func supports(_ language: Language) -> Bool {
        if SFSpeechRecognizer(locale: Locale(identifier: language.localeID)) != nil { return true }
        return language == .tagalog && SFSpeechRecognizer(locale: Locale(identifier: "tl-PH")) != nil
    }

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
        self.language = language
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.localeID))
        if language == .tagalog, recognizer?.isAvailable != true {
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tl-PH")) ?? recognizer
        }
    }

    /// One audio configuration for the whole call so tutor speech and listening don't flip the session every turn.
    func activateCallAudio() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }

    func endAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func startListening(style: SessionStyle = .drill) throws {
        guard let recognizer else { throw SpeechError.unsupported(language) }
        guard isAuthorized else { throw SpeechError.notAuthorized }
        guard recognizer.isAvailable else { throw SpeechError.unavailable }
        stopListening(cancel: true)
        self.style = style
        finishing = false
        transcript = ""
        lastChange = Date()
        speechBeganAt = nil

        let session = AVAudioSession.sharedInstance()
        switch style {
        case .call:
            // voiceChat enables better echo cancellation so TTS is less likely to be heard as the user.
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        case .drill:
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        }
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // A fresh engine picks up the current route's input format (avoids tap format crashes after route changes).
        engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw SpeechError.noMicrophone }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        // On-device avoids the ~1 minute server limit and keeps practice audio on the phone.
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        generation += 1
        let gen = generation
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self, gen == self.generation, !self.finishing else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    if text != self.transcript {
                        if self.speechBeganAt == nil, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.speechBeganAt = Date()
                        }
                        self.transcript = text
                        self.lastChange = Date()
                        self.armSilenceTimer()
                    }
                    if result.isFinal {
                        self.finishUtterance(force: true)
                        return
                    }
                }
                if error != nil {
                    self.handleRecognitionFailure()
                }
            }
        }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        tapInstalled = true
        engine.prepare()
        do {
            try engine.start()
        } catch {
            stopListening(cancel: true)
            throw error
        }
        isListening = true
    }

    func stopListening(cancel: Bool = false) {
        generation += 1
        let wasCapturing = isListening || tapInstalled
        silenceTask?.cancel()
        silenceTask = nil
        if engine.isRunning {
            engine.stop()
        }
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        if cancel { task?.cancel() }
        request?.endAudio()
        request = nil
        task = nil
        isListening = false
        speechBeganAt = nil
        // Calls keep the session up between turns; the controller ends it on hang up.
        if wasCapturing, style == .drill {
            endAudioSession()
        }
    }

    private func handleRecognitionFailure() {
        guard isListening, !finishing else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty, !isFiller(text) {
            finishUtterance(force: true)
            return
        }
        stopListening(cancel: true)
        onError?("Didn't catch anything — try again.")
    }

    /// Adaptive pause: wait longer after short starts so people aren't cut off mid-thought;
    /// settle a bit faster once they've already said several words.
    private func silenceThreshold() -> TimeInterval {
        let words = transcript.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        switch words {
        case 0...1: return 2.15
        case 2...4: return 1.75
        default: return 1.4
        }
    }

    private func armSilenceTimer() {
        silenceTask?.cancel()
        let wait = silenceThreshold()
        silenceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                let needed = self.silenceThreshold()
                guard Date().timeIntervalSince(self.lastChange) >= needed - 0.05 else { return }
                // Ignore ultra-short blips (mic bump / "uh") unless recognition marked final.
                if let began = self.speechBeganAt, Date().timeIntervalSince(began) < 0.55 {
                    self.armSilenceTimer()
                    return
                }
                self.finishUtterance()
            }
        }
    }

    private func isFiller(_ text: String) -> Bool {
        let fillers: Set<String> = ["um", "uh", "eh", "ah", "er", "mm", "hmm", "mhm"]
        let compact = text.lowercased().trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        return fillers.contains(compact)
    }

    /// `force` is used when the recognizer has already ended the task — a lone filler can't keep listening then.
    private func finishUtterance(force: Bool = false) {
        guard !finishing else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || isFiller(text) {
            // Single filler tokens are usually accidents — keep listening while the task is alive.
            guard force else { return }
            stopListening(cancel: true)
            onError?("Didn't catch that — try again.")
            return
        }
        finishing = true
        stopListening(cancel: false)
        onUtteranceComplete?(text)
    }
}
