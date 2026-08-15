import Foundation

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var isLoadingHelp = false
    @Published var errorMessage: String?
    @Published var levelUpSuggestion: String?
    @Published var starters: [String] = []
    @Published var selectedStarter: String?
    @Published var stuckHelp: StuckHelpResponse?
    @Published var showStuckSheet = false
    @Published var liveTranscript = ""

    let speechRecognition = SpeechRecognitionService()
    let speechSynthesis = SpeechSynthesisService()
    private let openAI = OpenAIService()
    private var settings: SettingsStore?
    private var vocabulary: VocabularyStore?
    private var hasStarted = false

    var canSpeak: Bool {
        guard let settings else { return false }
        return settings.hasAPIKey && !isProcessing && !speechRecognition.isRecording
    }

    var lastTutorText: String { messages.last(where: { $0.role == .tutor })?.text ?? "" }

    func bind(settings: SettingsStore, vocabulary: VocabularyStore) {
        self.settings = settings
        self.vocabulary = vocabulary
        speechRecognition.prepare(for: settings.language)
    }

    func onAppear() async {
        _ = await speechRecognition.requestAuthorization()
        _ = await speechRecognition.requestMicrophonePermission()
        speechRecognition.prepare(for: settings?.language ?? .spanish)
        guard let settings, settings.hasAPIKey else { return }
        if !hasStarted && messages.isEmpty {
            hasStarted = true
            await startConversation()
        }
    }

    func onSessionSettingsChanged() {
        guard let settings else { return }
        speechRecognition.prepare(for: settings.language)
        Task { await resetConversation() }
    }

    func startConversation() async {
        guard let settings, settings.hasAPIKey else {
            errorMessage = "Add an API key in Profile to start AI Chat."
            return
        }
        isProcessing = true
        errorMessage = nil
        levelUpSuggestion = nil
        starters = []
        selectedStarter = nil
        stuckHelp = nil
        let topicHint = settings.topic == .freeform ? "Pick a natural opener." : "Stay on: \(settings.topic.displayName)."
        do {
            let response = try await openAI.sendTurn(
                apiKey: settings.apiKey, model: settings.selectedModel,
                language: settings.language, level: settings.level, topic: settings.topic,
                weakPhrases: weakPhrases(for: settings), history: [],
                userTranscript: "[SESSION_START] Greet briefly and ask the first question. \(topicHint)"
            )
            applyTutorResponse(response)
            hasStarted = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func resetConversation() async {
        messages = []
        levelUpSuggestion = nil
        errorMessage = nil
        starters = []
        selectedStarter = nil
        stuckHelp = nil
        speechSynthesis.stop()
        await startConversation()
    }

    func beginRecording() {
        guard canSpeak else { return }
        errorMessage = nil
        speechSynthesis.stop()
        liveTranscript = ""
        speechRecognition.transcript = ""
        do { try speechRecognition.startRecording() }
        catch { errorMessage = error.localizedDescription }
    }

    func endRecordingAndSend() async {
        guard speechRecognition.isRecording else { return }
        speechRecognition.stopRecording()
        liveTranscript = speechRecognition.transcript
        var text = speechRecognition.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if let starter = selectedStarter, !starter.isEmpty {
            let stem = starter.replacingOccurrences(of: "…", with: "").trimmingCharacters(in: .whitespaces)
            if !text.localizedCaseInsensitiveContains(stem) {
                text = "\(starter) \(text)".trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        guard !text.isEmpty else {
            errorMessage = "No speech detected — hold the mic and try again."
            return
        }
        speechRecognition.transcript = text
        await sendTranscript()
    }

    func selectStarter(_ starter: String) {
        selectedStarter = starter
        if let settings { speechSynthesis.speak(starter, language: settings.language) }
    }

    func clearStarter() { selectedStarter = nil }

    func requestStuckHelp() async {
        guard let settings, settings.hasAPIKey else { return }
        guard !lastTutorText.isEmpty else { return }
        isLoadingHelp = true
        errorMessage = nil
        defer { isLoadingHelp = false }
        do {
            let help = try await openAI.requestStuckHelp(
                apiKey: settings.apiKey, model: settings.selectedModel,
                language: settings.language, level: settings.level, topic: settings.topic,
                lastTutorPrompt: lastTutorText, history: messages
            )
            stuckHelp = help
            showStuckSheet = true
            speechSynthesis.speak(help.suggestedAnswer, language: settings.language)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func practiceStuckAnswer() {
        guard let help = stuckHelp, let settings else { return }
        speechSynthesis.speak(help.suggestedAnswer, language: settings.language)
    }

    func useStuckAnswerAsStarter() {
        selectedStarter = stuckHelp?.suggestedAnswer
        showStuckSheet = false
    }

    func sendTranscript() async {
        guard let settings, settings.hasAPIKey else { return }
        let text = speechRecognition.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        liveTranscript = ""
        starters = []
        stuckHelp = nil
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        selectedStarter = nil
        do {
            let response = try await openAI.sendTurn(
                apiKey: settings.apiKey, model: settings.selectedModel,
                language: settings.language, level: settings.level, topic: settings.topic,
                weakPhrases: weakPhrases(for: settings), history: messages, userTranscript: text
            )
            applyTutorResponse(response)
        } catch {
            errorMessage = error.localizedDescription
            messages.removeAll { $0.id == userMessage.id }
        }
        isProcessing = false
    }

    func acceptLevelUp() {
        guard let settings else { return }
        switch settings.level {
        case .warmup: settings.level = .beginner
        case .beginner: settings.level = .intermediate
        case .intermediate: settings.level = .advanced
        case .advanced: break
        }
        levelUpSuggestion = nil
        Task { await resetConversation() }
    }

    func dismissLevelUp() { levelUpSuggestion = nil }

    func replayLastTutorMessage() {
        guard let settings, !lastTutorText.isEmpty else { return }
        speechSynthesis.speak(lastTutorText, language: settings.language)
    }

    private func weakPhrases(for settings: SettingsStore) -> [String] {
        guard settings.reuseWeakVocab, let vocabulary else { return [] }
        return vocabulary.weakPhraseHints(for: settings.language)
    }

    private func applyTutorResponse(_ response: TutorResponse) {
        guard let settings else { return }
        let corrections = (response.corrections ?? []).compactMap { $0.toCorrection() }
        vocabulary?.add(from: corrections, language: settings.language)
        if settings.showCorrectionsBeforeReply, !corrections.isEmpty,
           let lastUserIndex = messages.lastIndex(where: { $0.role == .user }) {
            let user = messages[lastUserIndex]
            messages[lastUserIndex] = ChatMessage(id: user.id, role: user.role, text: user.text, corrections: corrections, createdAt: user.createdAt)
        }
        messages.append(ChatMessage(role: .tutor, text: response.reply))
        starters = (response.starters ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        selectedStarter = nil
        if settings.autoSpeakResponses { speechSynthesis.speak(response.reply, language: settings.language) }
        if let suggestion = response.suggestedUpgrade, !suggestion.isEmpty { levelUpSuggestion = suggestion }
    }
}
