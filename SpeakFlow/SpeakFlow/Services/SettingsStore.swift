import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var language: Language {
        didSet {
            guard !applyingBook, language != oldValue else { return }
            switchLanguage(from: oldValue)
        }
    }
    @Published var level: ConversationLevel { didSet { if !applyingBook { save() } } }
    @Published var topic: ConversationTopic { didSet { save() } }
    @Published var apiKey: String {
        didSet {
            if apiKey.isEmpty { KeychainService.delete() } else { try? KeychainService.save(apiKey) }
        }
    }
    @Published var model: String { didSet { save() } }
    @Published var autoSpeak: Bool { didSet { save() } }
    @Published var hasSeenWelcome: Bool { didSet { save() } }
    /// One-time soft coach on the first Call — not a settings toggle.
    @Published var hasSeenCallCoach: Bool { didSet { save() } }
    @Published var completedLessonIDs: Set<String> { didSet { if !applyingBook { save() } } }
    @Published var xp: Int { didSet { if !applyingBook { save() } } }
    /// Correct spoken repeats for the active language. Three checks a phrase off.
    @Published var phraseReps: [String: Int] { didSet { if !applyingBook { save() } } }
    /// Topic ids whose short conversation was passed, for the active language.
    @Published var passedScenes: Set<String> { didSet { if !applyingBook { save() } } }
    /// One spoken line to try next time. Saved per language. No extra API call to show it.
    @Published var lastCoach: String { didSet { if !applyingBook { save() } } }

    private let d = UserDefaults.standard
    private var books: [String: LanguageProgress] = [:]
    private var applyingBook = false

    init() {
        let storedLanguage = Language(rawValue: d.string(forKey: "lang") ?? "") ?? .spanish
        let storedLevel = ConversationLevel(rawValue: d.string(forKey: "level") ?? "") ?? .warmup
        let loaded = Self.loadBooks(from: d, language: storedLanguage, fallbackLevel: storedLevel)
        let active = loaded[storedLanguage.rawValue] ?? LanguageProgress()

        language = storedLanguage
        level = ConversationLevel(rawValue: active.level) ?? storedLevel
        topic = ConversationTopic(rawValue: d.string(forKey: "topic") ?? "") ?? .freeform
        model = d.string(forKey: "model") ?? "gpt-4o-mini"
        autoSpeak = d.object(forKey: "autoSpeak") as? Bool ?? true
        hasSeenWelcome = d.bool(forKey: "welcome")
        hasSeenCallCoach = d.bool(forKey: "callCoach")
        completedLessonIDs = Set(d.stringArray(forKey: "lessons") ?? [])
        xp = active.xp
        phraseReps = active.phraseReps
        passedScenes = Set(active.passedScenes)
        lastCoach = active.lastCoach
        books = loaded
        apiKey = KeychainService.load() ?? ""
    }

    private func switchLanguage(from old: Language) {
        applyingBook = true
        books[old.rawValue] = capture(into: books[old.rawValue])
        let next = books[language.rawValue] ?? LanguageProgress()
        phraseReps = next.phraseReps
        passedScenes = Set(next.passedScenes)
        xp = next.xp
        lastCoach = next.lastCoach
        level = ConversationLevel(rawValue: next.level) ?? .warmup
        applyingBook = false
        save()
    }

    /// Snapshot of the fields currently on screen. `language` may already be the new one, so callers pass the book to update.
    private func capture(into existing: LanguageProgress?) -> LanguageProgress {
        var book = existing ?? LanguageProgress()
        book.phraseReps = phraseReps
        book.passedScenes = Array(passedScenes).sorted()
        book.level = level.rawValue
        book.xp = xp
        book.lastCoach = lastCoach
        return book
    }

    func rememberCoach(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lastCoach = String(trimmed.prefix(180))
    }

    /// Lines they have already checked off, so a call stays inside what they can say.
    var spokenSoFar: String {
        let lines = SpeakPath.topics(for: language)
            .flatMap(\.phrases)
            .filter { reps(for: $0.id) >= SpeakPath.repsToPass }
            .map(\.line)
        if lines.isEmpty { return "Nothing checked off yet. Greet them and ask one very short question." }
        return lines.joined(separator: "; ")
    }

    func reps(for phraseID: String) -> Int {
        min(SpeakPath.repsToPass, phraseReps[phraseID] ?? 0)
    }

    /// Records one clean repeat. Returns the new count, capped at the check-off line.
    @discardableResult
    func notePhraseRep(_ phraseID: String) -> Int {
        let current = phraseReps[phraseID] ?? 0
        guard current < SpeakPath.repsToPass else { return current }
        let next = current + 1
        phraseReps[phraseID] = next
        if next == SpeakPath.repsToPass { xp += 5 }
        return next
    }

    func phrasesReady(_ topic: PathTopic) -> Bool {
        topic.phrases.allSatisfy { reps(for: $0.id) >= SpeakPath.repsToPass }
    }

    /// First topic that still needs repeats or a passed conversation, in the active language.
    var currentTopic: PathTopic? {
        SpeakPath.topics(for: language).first { !phrasesReady($0) || !passedScenes.contains($0.id) }
    }

    func topicLocked(_ topic: PathTopic) -> Bool {
        let topics = SpeakPath.topics(for: language)
        guard let idx = topics.firstIndex(where: { $0.id == topic.id }), idx > 0 else { return false }
        let previous = topics[idx - 1]
        return !(phrasesReady(previous) && passedScenes.contains(previous.id))
    }

    var freeTalkUnlocked: Bool { passedScenes.count >= SpeakPath.scenesBeforeFreeTalk }

    /// How hard Talk and Chat should be, from the lines actually checked off.
    var dialogueLevel: ConversationLevel {
        let known = SpeakPath.topics(for: language)
            .flatMap(\.phrases)
            .filter { reps(for: $0.id) >= SpeakPath.repsToPass }
            .count
        if known < 6 { return .warmup }
        if known < 14 { return .beginner }
        if known < 22 { return .intermediate }
        return .advanced
    }

    /// The easier of the measured level and the level chosen in You.
    var talkLevel: ConversationLevel {
        let order: [ConversationLevel] = [.warmup, .beginner, .intermediate, .advanced]
        guard let measured = order.firstIndex(of: dialogueLevel),
              let chosen = order.firstIndex(of: level) else { return dialogueLevel }
        return order[min(measured, chosen)]
    }

    /// How many of their turns a hands-free talk runs before it closes.
    var turnBudget: Int {
        switch talkLevel {
        case .warmup: return 4
        case .beginner: return 6
        case .intermediate: return 8
        case .advanced: return 12
        }
    }

    func passScene(_ topicID: String) {
        guard !passedScenes.contains(topicID) else { return }
        passedScenes.insert(topicID)
        xp += 30
        if passedScenes.count >= 6 { bumpLevel(to: .intermediate) }
        else if passedScenes.count >= 3 { bumpLevel(to: .beginner) }
    }

    private func bumpLevel(to new: ConversationLevel) {
        let order: [ConversationLevel] = [.warmup, .beginner, .intermediate, .advanced]
        guard let current = order.firstIndex(of: level), let next = order.firstIndex(of: new), next > current else { return }
        level = new
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
        d.set(hasSeenCallCoach, forKey: "callCoach")
        d.set(Array(completedLessonIDs), forKey: "lessons")
        books[language.rawValue] = capture(into: books[language.rawValue])
        if let data = try? JSONEncoder().encode(books) {
            d.set(data, forKey: "progressByLanguage")
        }
    }

    private static func loadBooks(from d: UserDefaults, language: Language, fallbackLevel: ConversationLevel) -> [String: LanguageProgress] {
        if let data = d.data(forKey: "progressByLanguage"),
           let decoded = try? JSONDecoder().decode([String: LanguageProgress].self, from: data) {
            return decoded
        }
        var legacyReps: [String: Int] = [:]
        if let data = d.data(forKey: "phraseReps"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            legacyReps = decoded
        }
        let legacyScenes = d.stringArray(forKey: "scenes") ?? []
        var books: [String: LanguageProgress] = [:]
        var spanish = LanguageProgress()
        spanish.phraseReps = legacyReps
        spanish.passedScenes = legacyScenes
        spanish.level = d.string(forKey: "level") ?? fallbackLevel.rawValue
        spanish.xp = d.integer(forKey: "xp")
        books["es"] = spanish
        if language != .spanish, books[language.rawValue] == nil {
            books[language.rawValue] = LanguageProgress(level: fallbackLevel.rawValue)
        }
        return books
    }
}

struct LanguageProgress: Codable, Equatable {
    var phraseReps: [String: Int] = [:]
    var passedScenes: [String] = []
    var level: String = ConversationLevel.warmup.rawValue
    var xp: Int = 0
    var lastCoach: String = ""
}
