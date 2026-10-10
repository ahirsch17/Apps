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

    nonisolated static func voice(for language: Language) -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(language: language.localeID)
            ?? AVSpeechSynthesisVoice(language: language.rawValue)
            ?? (language == .tagalog ? AVSpeechSynthesisVoice(language: "tl-PH") : nil)
    }

    /// - Parameter configuresSession: false during a call, where the controller owns one play-and-record session.
    func speak(
        _ text: String,
        language: Language,
        slow: Bool = false,
        configuresSession: Bool = true,
        onFinish: (() -> Void)? = nil
    ) {
        // Finish (not drop) any previous utterance so callers awaiting it never hang.
        stop(invokeFinish: true)
        self.onFinish = onFinish
        let u = AVSpeechUtterance(string: text)
        u.voice = Self.voice(for: language)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * (slow ? 0.72 : 0.92)
        isSpeaking = true

        if configuresSession {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try? session.setActive(true, options: .notifyOthersOnDeactivation)
        }

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
