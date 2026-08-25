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
        stop()
        self.onFinish = onFinish
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: language.localeID)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        isSpeaking = true
        synth.speak(u)
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        isSpeaking = false
    }
}

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            onFinish?()
            onFinish = nil
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = false; onFinish = nil }
    }
}
