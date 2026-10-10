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
    /// Slower tutor voice everywhere (Call, Text, Learn).
    @Published var slowSpeech: Bool { didSet { save() } }
    /// Show an English gloss under tutor lines.
    @Published var showTranslations: Bool { didSet { save() } }
    @Published var hasSeenWelcome: Bool { didSet { save() } }
    /// One-time soft coach on the first Call — not a settings toggle.
    @Published var hasSeenCallCoach: Bool { didSet { save() } }
    @Published var completedLessonIDs: Set<String> { didSet { save() } }
    @Published var xp: Int { didSet { save() } }
    @Published private(set) var streakDays: Int { didSet { save() } }
    @Published private(set) var lastPracticeDay: Date? { didSet { save() } }

    private let d = UserDefaults.standard

    init() {
        language = Language(rawValue: d.string(forKey: "lang") ?? "") ?? .spanish
        level = ConversationLevel(rawValue: d.string(forKey: "level") ?? "") ?? .warmup
        topic = ConversationTopic(rawValue: d.string(forKey: "topic") ?? "") ?? .freeform
        model = d.string(forKey: "model") ?? "gpt-4o-mini"
        autoSpeak = d.object(forKey: "autoSpeak") as? Bool ?? true
        slowSpeech = d.bool(forKey: "slowSpeech")
        showTranslations = d.object(forKey: "showTranslations") as? Bool ?? true
        hasSeenWelcome = d.bool(forKey: "welcome")
        hasSeenCallCoach = d.bool(forKey: "callCoach")
        completedLessonIDs = Set(d.stringArray(forKey: "lessons") ?? [])
        xp = d.integer(forKey: "xp")
        streakDays = d.integer(forKey: "streak")
        lastPracticeDay = d.object(forKey: "lastPractice") as? Date
        apiKey = KeychainService.load() ?? ""
    }

    var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var character: TutorCharacter { .forLanguage(language) }

    /// Streak still alive if they practiced today or yesterday.
    var currentStreak: Int {
        guard let last = lastPracticeDay else { return 0 }
        let cal = Calendar.current
        let gap = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: .now)).day ?? 0
        return gap <= 1 ? streakDays : 0
    }

    var practicedToday: Bool {
        guard let last = lastPracticeDay else { return false }
        return Calendar.current.isDateInToday(last)
    }

    func completeLesson(_ id: String) {
        recordPractice()
        guard !completedLessonIDs.contains(id) else { return }
        completedLessonIDs.insert(id)
        xp += 20
    }

    func recordPractice(now: Date = .now) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        if let last = lastPracticeDay {
            let lastDay = cal.startOfDay(for: last)
            if lastDay == today { return }
            let gap = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            streakDays = gap == 1 ? streakDays + 1 : 1
        } else {
            streakDays = 1
        }
        lastPracticeDay = today
    }

    private func save() {
        d.set(language.rawValue, forKey: "lang")
        d.set(level.rawValue, forKey: "level")
        d.set(topic.rawValue, forKey: "topic")
        d.set(model, forKey: "model")
        d.set(autoSpeak, forKey: "autoSpeak")
        d.set(slowSpeech, forKey: "slowSpeech")
        d.set(showTranslations, forKey: "showTranslations")
        d.set(hasSeenWelcome, forKey: "welcome")
        d.set(hasSeenCallCoach, forKey: "callCoach")
        d.set(Array(completedLessonIDs), forKey: "lessons")
        d.set(xp, forKey: "xp")
        d.set(streakDays, forKey: "streak")
        d.set(lastPracticeDay, forKey: "lastPractice")
    }
}
