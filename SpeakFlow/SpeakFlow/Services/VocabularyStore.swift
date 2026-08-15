import Foundation

@MainActor
final class VocabularyStore: ObservableObject {
    @Published private(set) var entries: [VocabularyEntry] = []
    private let defaults = UserDefaults.standard
    private let storageKey = "vocabularyEntries"

    init() { load() }

    func entries(for language: Language) -> [VocabularyEntry] {
        entries.filter { $0.languageCode == language.rawValue }.sorted { $0.createdAt > $1.createdAt }
    }

    func add(from corrections: [Correction], language: Language) {
        for correction in corrections {
            let trimmed = correction.corrected.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if entries.contains(where: {
                $0.languageCode == language.rawValue
                    && $0.corrected.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
            }) { continue }
            entries.insert(VocabularyEntry(from: correction, language: language), at: 0)
        }
        persist()
    }

    func markReviewed(_ entry: VocabularyEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].timesReviewed += 1
        entries[index].lastReviewedAt = Date()
        persist()
    }

    func delete(_ entry: VocabularyEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func weakPhraseHints(for language: Language, limit: Int = 8) -> [String] {
        Array(
            entries(for: language)
                .sorted { $0.timesReviewed < $1.timesReviewed }
                .prefix(limit)
                .map(\.corrected)
        )
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([VocabularyEntry].self, from: data) else { return }
        entries = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
