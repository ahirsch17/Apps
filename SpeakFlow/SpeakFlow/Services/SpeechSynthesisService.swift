import AVFoundation
import Foundation

@MainActor
final class SpeechSynthesisService: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: Language) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestVoice(for: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        isSpeaking = false
    }

    private func bestVoice(for language: Language) -> AVSpeechSynthesisVoice? {
        let locale = language.speechLocaleIdentifier
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(language.rawValue) }
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) { return enhanced }
        if let preferred = voices.first(where: { $0.language == locale }) { return preferred }
        return AVSpeechSynthesisVoice(language: locale)
    }
}

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = false }
    }
}
