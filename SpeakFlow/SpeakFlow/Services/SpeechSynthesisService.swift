import AVFoundation
import Foundation

@MainActor
final class SpeechSynthesisService: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false
    private let synth = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String, language: Language, onFinish: (() -> Void)? = nil) {
        stop(invokeFinish: false)
        self.onFinish = onFinish
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: language.localeID)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        isSpeaking = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        synth.speak(u)
    }

    /// Stops speech. By default still fires `onFinish` so awaiting call-loop continuations never hang.
    func stop(invokeFinish: Bool = true) {
        let finish = onFinish
        onFinish = nil
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        isSpeaking = false
        if invokeFinish { finish?() }
    }
}

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            let finish = onFinish
            onFinish = nil
            finish?()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // `stop(invokeFinish:)` already handles the callback when we cancel intentionally.
        Task { @MainActor in
            isSpeaking = false
        }
    }
}
