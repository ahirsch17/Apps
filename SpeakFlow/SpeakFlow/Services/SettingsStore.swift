import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var language: Language { didSet { persist() } }
    @Published var level: ConversationLevel { didSet { persist() } }
    @Published var topic: ConversationTopic { didSet { persist() } }
    @Published var apiKey: String {
        didSet {
            if apiKey.isEmpty { KeychainService.deleteAPIKey() }
            else { try? KeychainService.saveAPIKey(apiKey) }
        }
    }
    @Published var selectedModel: LLMModel { didSet { persist() } }
    @Published var autoSpeakResponses: Bool { didSet { persist() } }
    @Published var showCorrectionsBeforeReply: Bool { didSet { persist() } }
    @Published var reuseWeakVocab: Bool { didSet { persist() } }
    @Published var hasSeenWelcome: Bool { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let language = "language"
        static let level = "level"
        static let topic = "topic"
        static let model = "model"
        static let autoSpeak = "autoSpeak"
        static let showCorrectionsFirst = "showCorrectionsFirst"
        static let reuseWeakVocab = "reuseWeakVocab"
        static let hasSeenWelcome = "hasSeenWelcome"
    }

    init() {
        language = Language(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .spanish
        level = ConversationLevel(rawValue: defaults.string(forKey: Keys.level) ?? "") ?? .warmup
        topic = ConversationTopic(rawValue: defaults.string(forKey: Keys.topic) ?? "") ?? .freeform
        selectedModel = LLMModel(rawValue: defaults.string(forKey: Keys.model) ?? "") ?? .gpt4oMini
        autoSpeakResponses = defaults.object(forKey: Keys.autoSpeak) as? Bool ?? true
        showCorrectionsBeforeReply = defaults.object(forKey: Keys.showCorrectionsFirst) as? Bool ?? true
        reuseWeakVocab = defaults.object(forKey: Keys.reuseWeakVocab) as? Bool ?? true
        hasSeenWelcome = defaults.bool(forKey: Keys.hasSeenWelcome)
        apiKey = KeychainService.loadAPIKey() ?? ""
    }

    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func persist() {
        defaults.set(language.rawValue, forKey: Keys.language)
        defaults.set(level.rawValue, forKey: Keys.level)
        defaults.set(topic.rawValue, forKey: Keys.topic)
        defaults.set(selectedModel.rawValue, forKey: Keys.model)
        defaults.set(autoSpeakResponses, forKey: Keys.autoSpeak)
        defaults.set(showCorrectionsBeforeReply, forKey: Keys.showCorrectionsFirst)
        defaults.set(reuseWeakVocab, forKey: Keys.reuseWeakVocab)
        defaults.set(hasSeenWelcome, forKey: Keys.hasSeenWelcome)
    }
}

enum LLMModel: String, CaseIterable, Identifiable, Codable {
    case gpt4oMini = "gpt-4o-mini"
    case gpt41Mini = "gpt-4.1-mini"
    case gpt41Nano = "gpt-4.1-nano"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt4oMini: return "GPT-4o mini (recommended)"
        case .gpt41Mini: return "GPT-4.1 mini"
        case .gpt41Nano: return "GPT-4.1 nano (cheapest)"
        }
    }

    var costNote: String {
        switch self {
        case .gpt4oMini: return "~$0.001 per exchange"
        case .gpt41Mini: return "~$0.002 per exchange"
        case .gpt41Nano: return "~$0.0005 per exchange"
        }
    }
}
