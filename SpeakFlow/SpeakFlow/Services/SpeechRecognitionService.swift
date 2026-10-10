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

    @Published var transcript = ""
    @Published private(set) var isListening = false
    @Published private(set) var isAuthorized = false

    /// Fired when user seems done speaking (silence after speech).
    var onUtteranceComplete: ((String) -> Void)?

    private var engine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var lastChange = Date()
    private var speechBeganAt: Date?
    private var style: SessionStyle = .drill
    private var finishing = false

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

    func startListening(style: SessionStyle = .drill) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition unavailable"])
        }
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

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true
        if #available(iOS 16, *) { request.addsPunctuation = true }

        let input = engine.inputNode
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self, !self.finishing else { return }
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
                        self.finishUtterance()
                    }
                }
                _ = error
            }
        }

        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        try engine.start()
        isListening = true
    }

    func stopListening(cancel: Bool = false) {
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
        speechBeganAt = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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

    private func finishUtterance() {
        guard !finishing else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        // Single filler tokens are usually accidents — keep listening.
        let fillers: Set<String> = ["um", "uh", "eh", "ah", "er", "mm", "hmm", "mhm"]
        let compact = text.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if fillers.contains(compact) {
            return
        }
        finishing = true
        stopListening(cancel: false)
        onUtteranceComplete?(text)
    }
}
