import Foundation

/// A phrase the learner should see again — from a correction, a call recap, or a missed Learn prompt.
struct SavedPhrase: Identifiable, Codable, Equatable {
    enum Source: String, Codable {
        case correction, recap, lesson

        var label: String {
            switch self {
            case .correction: return "Correction"
            case .recap: return "From a call"
            case .lesson: return "Learn"
            }
        }
    }

    let id: UUID
    let language: Language
    /// Target-language phrase the learner should be able to say.
    let phrase: String
    /// What the review card shows first (English meaning, or the learner's original slip).
    let prompt: String
    let note: String
    let source: Source
    let createdAt: Date
    var box: Int
    var dueAt: Date
}

/// On-device review deck with simple Leitner spacing (again → 10 min, then 1 / 3 / 7 / 16 / 35 days).
@MainActor
final class PhrasebookStore: ObservableObject {
    @Published private(set) var phrases: [SavedPhrase] = []

    private let storageKey = "phrasebook.v1"
    private let maxPhrases = 600
    private static let intervals: [TimeInterval] = [0, 1, 3, 7, 16, 35].map { $0 * 86_400 }

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SavedPhrase].self, from: data) {
            phrases = decoded
        }
    }

    func phrases(for language: Language) -> [SavedPhrase] {
        phrases.filter { $0.language == language }.sorted { $0.createdAt > $1.createdAt }
    }

    func dueCount(for language: Language, now: Date = .now) -> Int {
        phrases.filter { $0.language == language && $0.dueAt <= now }.count
    }

    func dueDeck(for language: Language, limit: Int = 12, now: Date = .now) -> [SavedPhrase] {
        Array(
            phrases
                .filter { $0.language == language && $0.dueAt <= now }
                .sorted { $0.dueAt < $1.dueAt }
                .prefix(limit)
        )
    }

    @discardableResult
    func add(phrase: String, prompt: String, note: String, language: Language, source: SavedPhrase.Source) -> Bool {
        let clean = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = PhraseText.normalize(clean)
        guard key.count >= 2, clean.count <= 140 else { return false }
        guard !phrases.contains(where: { $0.language == language && PhraseText.normalize($0.phrase) == key }) else {
            return false
        }
        phrases.append(SavedPhrase(
            id: UUID(),
            language: language,
            phrase: clean,
            prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            source: source,
            createdAt: .now,
            box: 0,
            dueAt: .now
        ))
        trimIfNeeded()
        save()
        return true
    }

    func record(_ id: UUID, remembered: Bool, now: Date = .now) {
        guard let i = phrases.firstIndex(where: { $0.id == id }) else { return }
        if remembered {
            let next = min(phrases[i].box + 1, Self.intervals.count - 1)
            phrases[i].box = next
            phrases[i].dueAt = now.addingTimeInterval(Self.intervals[next])
        } else {
            phrases[i].box = 0
            phrases[i].dueAt = now.addingTimeInterval(10 * 60)
        }
        save()
    }

    func remove(_ id: UUID) {
        phrases.removeAll { $0.id == id }
        save()
    }

    private func trimIfNeeded() {
        guard phrases.count > maxPhrases else { return }
        // Drop the best-known, oldest phrases first.
        phrases.sort { ($0.box, $1.createdAt) > ($1.box, $0.createdAt) }
        phrases.removeFirst(phrases.count - maxPhrases)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(phrases) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

enum PhraseText {
    static func normalize(_ s: String) -> String {
        let folded = s.lowercased()
            .replacingOccurrences(of: "ß", with: "ss")
            .folding(options: .diacriticInsensitive, locale: .current)
        let mapped = folded.map { ch -> Character in
            if ch.isLetter || ch.isNumber || ch.isWhitespace { return ch }
            return " "
        }
        return String(mapped)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

/// Forgiving speech-attempt grading for Learn and Review.
enum PhraseGrader {
    struct Result {
        let message: String
        let passed: Bool
    }

    static func grade(attempt: String, target: String) -> Result {
        let a = PhraseText.normalize(attempt)
        guard !a.isEmpty else { return Result(message: "Didn't catch that — try again, or Reveal.", passed: false) }

        var bestOverlap = 0.0
        for variant in variants(of: target) {
            let parts = templateParts(variant)
            if parts.count > 1 || variant.contains("…") || variant.contains("...") {
                if containsInOrder(a, parts) {
                    return Result(message: "Nailed it. Now make it yours.", passed: true)
                }
            } else if a == parts.first {
                return Result(message: "Nailed it. Steal that phrasing.", passed: true)
            }
            let tw = Set(parts.joined(separator: " ").split(separator: " "))
            guard !tw.isEmpty else { continue }
            let aw = Set(a.split(separator: " "))
            bestOverlap = max(bestOverlap, Double(aw.intersection(tw).count) / Double(tw.count))
        }

        if bestOverlap >= 0.75 { return Result(message: "Close enough — lock in the exact words.", passed: true) }
        if bestOverlap >= 0.4 { return Result(message: "Got the idea. Compare & lock the words.", passed: false) }
        return Result(message: "Nice try. Compare & steal the phrase.", passed: false)
    }

    /// "nervioso/a" → nervioso, nerviosa · "din/rin" → din, rin
    static func variants(of target: String) -> [String] {
        var results = [""]
        for token in target.split(separator: " ").map(String.init) {
            var options = [token]
            if let slash = token.firstIndex(of: "/"), slash != token.startIndex {
                let base = String(token[..<slash])
                let alt = String(token[token.index(after: slash)...])
                if alt.isEmpty {
                    options = [base]
                } else if alt.count >= base.count {
                    options = [base, alt]
                } else {
                    options = [base, String(base.dropLast(alt.count)) + alt]
                }
            }
            results = results.flatMap { prefix in options.map { prefix.isEmpty ? $0 : prefix + " " + $0 } }
        }
        return results
    }

    /// Splits fill-in-the-blank phrases ("Ich habe … gespielt") into the fixed parts.
    private static func templateParts(_ target: String) -> [String] {
        target
            .replacingOccurrences(of: "...", with: "…")
            .components(separatedBy: "…")
            .map(PhraseText.normalize)
            .filter { !$0.isEmpty }
    }

    private static func containsInOrder(_ text: String, _ parts: [String]) -> Bool {
        guard !parts.isEmpty else { return false }
        var searchRange = text.startIndex..<text.endIndex
        for part in parts {
            guard let found = text.range(of: part, range: searchRange) else { return false }
            searchRange = found.upperBound..<text.endIndex
        }
        return true
    }
}
