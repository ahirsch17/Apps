import AVFoundation
import Foundation
import Speech

/// Continuous listening with silence-based end-of-utterance (hands-free).
@MainActor
final class SpeechRecognitionService: ObservableObject {
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
    private var lastSnapshot = ""

    /// Seconds of unchanged transcript before we treat speech as finished.
    var silenceSeconds: TimeInterval = 1.6

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

    func startListening() throws {
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition unavailable"])
        }
        stopListening(cancel: true)
        transcript = ""
        lastSnapshot = ""
        lastChange = Date()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true
        if #available(iOS 16, *) { request.addsPunctuation = true }

        let input = engine.inputNode
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    if text != self.transcript {
                        self.transcript = text
                        self.lastSnapshot = text
                        self.lastChange = Date()
                        self.armSilenceTimer()
                    }
                    if result.isFinal {
                        self.finishUtterance()
                    }
                }
                if error != nil {
                    // Often fires on restart; ignore if empty
                }
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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func armSilenceTimer() {
        silenceTask?.cancel()
        silenceTask = Task { [weak self] in
            guard let self else { return }
            let wait = UInt64(self.silenceSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: wait)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if Date().timeIntervalSince(self.lastChange) >= self.silenceSeconds - 0.05 {
                    self.finishUtterance()
                }
            }
        }
    }

    private func finishUtterance() {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        stopListening(cancel: false)
        onUtteranceComplete?(text)
    }
}
