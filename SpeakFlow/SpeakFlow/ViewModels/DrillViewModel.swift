import Foundation

@MainActor
final class DrillViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var showAnswer = false
    @Published var isRecording = false
    @Published var userAttempt = ""
    @Published var feedback: DrillFeedback?
    @Published var completedCount = 0

    let speechRecognition = SpeechRecognitionService()
    let speechSynthesis = SpeechSynthesisService()
    private(set) var deck: [DrillPhrase] = []
    private var language: Language = .spanish

    struct DrillFeedback: Equatable {
        let isClose: Bool
        let message: String
    }

    var current: DrillPhrase? {
        deck.indices.contains(currentIndex) ? deck[currentIndex] : nil
    }

    var progressLabel: String {
        deck.isEmpty ? "0 / 0" : "\(min(currentIndex + 1, deck.count)) / \(deck.count)"
    }

    func configure(language: Language, level: ConversationLevel, topic: ConversationTopic) {
        self.language = language
        speechRecognition.prepare(for: language)
        var phrases = PhraseBank.phrases(for: language, level: level, topic: topic)
        if phrases.isEmpty { phrases = PhraseBank.phrases(for: language, level: level) }
        if phrases.isEmpty { phrases = PhraseBank.phrases(for: language) }
        deck = phrases.shuffled()
        currentIndex = 0
        showAnswer = false
        userAttempt = ""
        feedback = nil
        completedCount = 0
    }

    func onAppear() async {
        _ = await speechRecognition.requestAuthorization()
        _ = await speechRecognition.requestMicrophonePermission()
        speechRecognition.prepare(for: language)
    }

    func speakTarget() {
        guard let current else { return }
        speechSynthesis.speak(current.targetPhrase, language: language)
    }

    func revealAnswer() {
        showAnswer = true
        speakTarget()
    }

    func toggleRecording() async {
        if speechRecognition.isRecording {
            speechRecognition.stopRecording()
            isRecording = false
            userAttempt = speechRecognition.transcript
            evaluateAttempt()
        } else {
            feedback = nil
            userAttempt = ""
            speechRecognition.transcript = ""
            speechSynthesis.stop()
            do {
                try speechRecognition.startRecording()
                isRecording = true
            } catch {
                feedback = DrillFeedback(isClose: false, message: error.localizedDescription)
            }
        }
    }

    func next() {
        guard !deck.isEmpty else { return }
        if currentIndex < deck.count - 1 { currentIndex += 1 }
        else { deck.shuffle(); currentIndex = 0 }
        showAnswer = false
        userAttempt = ""
        feedback = nil
        speechSynthesis.stop()
    }

    func markDone() {
        completedCount += 1
        next()
    }

    private func evaluateAttempt() {
        guard let current else { return }
        let attempt = normalize(userAttempt)
        let target = normalize(current.targetPhrase)
        if attempt.isEmpty {
            feedback = DrillFeedback(isClose: false, message: "No speech detected — try again.")
            return
        }
        if attempt == target || target.contains(attempt) || attempt.contains(target) {
            feedback = DrillFeedback(isClose: true, message: "Nice — that matches well.")
            showAnswer = true
            return
        }
        let overlap = Set(attempt.split(separator: " ").map(String.init))
            .intersection(Set(target.split(separator: " ").map(String.init))).count
        let ratio = Double(overlap) / Double(max(target.split(separator: " ").count, 1))
        feedback = DrillFeedback(
            isClose: ratio >= 0.5,
            message: ratio >= 0.5 ? "Close! Check the phrase and try once more." : "Not quite — reveal, listen, then shadow it."
        )
        showAnswer = true
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
