import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var language: Language { didSet { save() } }
    @Published var level: ConversationLevel { didSet { save() } }
    @Published var topic: ConversationTopic { didSet { save() } }
    @Published var apiKey: String {
        didSet {
            if apiKey.isEmpty { KeychainService.delete() } else { try? KeychainService.save(apiKey) }
        }
    }
    @Published var model: String { didSet { save() } }
    @Published var autoSpeak: Bool { didSet { save() } }
    @Published var hasSeenWelcome: Bool { didSet { save() } }
    @Published var completedLessonIDs: Set<String> { didSet { save() } }
    @Published var xp: Int { didSet { save() } }

    private let d = UserDefaults.standard

    init() {
        language = Language(rawValue: d.string(forKey: "lang") ?? "") ?? .spanish
        level = ConversationLevel(rawValue: d.string(forKey: "level") ?? "") ?? .warmup
        topic = ConversationTopic(rawValue: d.string(forKey: "topic") ?? "") ?? .freeform
        model = d.string(forKey: "model") ?? "gpt-4o-mini"
        autoSpeak = d.object(forKey: "autoSpeak") as? Bool ?? true
        hasSeenWelcome = d.bool(forKey: "welcome")
        completedLessonIDs = Set(d.stringArray(forKey: "lessons") ?? [])
        xp = d.integer(forKey: "xp")
        apiKey = KeychainService.load() ?? ""
    }

    var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var character: TutorCharacter { .forLanguage(language) }

    func completeLesson(_ id: String) {
        guard !completedLessonIDs.contains(id) else { return }
        completedLessonIDs.insert(id)
        xp += 20
    }

    private func save() {
        d.set(language.rawValue, forKey: "lang")
        d.set(level.rawValue, forKey: "level")
        d.set(topic.rawValue, forKey: "topic")
        d.set(model, forKey: "model")
        d.set(autoSpeak, forKey: "autoSpeak")
        d.set(hasSeenWelcome, forKey: "welcome")
        d.set(Array(completedLessonIDs), forKey: "lessons")
        d.set(xp, forKey: "xp")
    }
}
