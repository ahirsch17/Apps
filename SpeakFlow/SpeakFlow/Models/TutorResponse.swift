import Foundation

struct TutorResponse: Codable {
    let reply: String
    let corrections: [CorrectionPayload]?
    let starters: [String]?
    let suggestedUpgrade: String?
    let encouragement: String?

    struct CorrectionPayload: Codable {
        let type: String
        let original: String
        let corrected: String
        let explanation: String

        func toCorrection() -> Correction? {
            guard let correctionType = CorrectionType(rawValue: type) else { return nil }
            return Correction(
                type: correctionType,
                original: original,
                corrected: corrected,
                explanation: explanation
            )
        }
    }
}

struct StuckHelpResponse: Codable {
    let suggestedAnswer: String
    let englishGloss: String
    let tip: String
}

struct VocabularyEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let languageCode: String
    let original: String
    let corrected: String
    let explanation: String
    let correctionType: CorrectionType
    let createdAt: Date
    var timesReviewed: Int
    var lastReviewedAt: Date?

    init(
        id: UUID = UUID(),
        languageCode: String,
        original: String,
        corrected: String,
        explanation: String,
        correctionType: CorrectionType,
        createdAt: Date = Date(),
        timesReviewed: Int = 0,
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.languageCode = languageCode
        self.original = original
        self.corrected = corrected
        self.explanation = explanation
        self.correctionType = correctionType
        self.createdAt = createdAt
        self.timesReviewed = timesReviewed
        self.lastReviewedAt = lastReviewedAt
    }

    init(from correction: Correction, language: Language) {
        self.init(
            languageCode: language.rawValue,
            original: correction.original,
            corrected: correction.corrected,
            explanation: correction.explanation,
            correctionType: correction.type
        )
    }
}
