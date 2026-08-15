import Foundation

enum OpenAIError: LocalizedError {
    case missingAPIKey, invalidResponse, apiError(String), decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Add your OpenAI API key in Profile to unlock AI Chat."
        case .invalidResponse: return "Unexpected response from OpenAI."
        case .apiError(let message): return message
        case .decodingFailed(let detail): return "Could not parse tutor response: \(detail)"
        }
    }
}

struct OpenAIService {
    private let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func sendTurn(
        apiKey: String, model: LLMModel, language: Language, level: ConversationLevel,
        topic: ConversationTopic, weakPhrases: [String], history: [ChatMessage], userTranscript: String
    ) async throws -> TutorResponse {
        let messages = buildTurnMessages(language: language, level: level, topic: topic, weakPhrases: weakPhrases, history: history, userTranscript: userTranscript)
        return try decode(TutorResponse.self, from: try await chatCompletion(apiKey: apiKey, model: model, messages: messages))
    }

    func requestStuckHelp(
        apiKey: String, model: LLMModel, language: Language, level: ConversationLevel,
        topic: ConversationTopic, lastTutorPrompt: String, history: [ChatMessage]
    ) async throws -> StuckHelpResponse {
        var messages: [ChatCompletionMessage] = [
            ChatCompletionMessage(role: "system", content: """
            You help a learner who froze while answering in \(language.languageInstruction). \
            Give one natural, level-appropriate answer they can say out loud right now.
            LEVEL: \(level.displayName). TOPIC: \(topic.displayName).
            Return ONLY JSON: {"suggestedAnswer":"...","englishGloss":"...","tip":"..."}
            """)
        ]
        for message in history.suffix(6) where message.role != .system {
            messages.append(ChatCompletionMessage(role: message.role == .user ? "user" : "assistant", content: message.text))
        }
        messages.append(ChatCompletionMessage(role: "user", content: "The tutor just said: \"\(lastTutorPrompt)\". The learner is stuck. Provide a ready-to-say answer."))
        return try decode(StuckHelpResponse.self, from: try await chatCompletion(apiKey: apiKey, model: model, messages: messages, temperature: 0.5))
    }

    private func chatCompletion(apiKey: String, model: LLMModel, messages: [ChatCompletionMessage], temperature: Double = 0.7) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw OpenAIError.missingAPIKey }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ChatCompletionRequest(model: model.rawValue, messages: messages, temperature: temperature, response_format: ResponseFormat(type: "json_object")))
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let apiError = try? JSONDecoder().decode(OpenAIAPIErrorEnvelope.self, from: data) {
                throw OpenAIError.apiError(apiError.error.message)
            }
            throw OpenAIError.apiError("HTTP \(http.statusCode)")
        }
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else { throw OpenAIError.invalidResponse }
        return content
    }

    private func buildTurnMessages(language: Language, level: ConversationLevel, topic: ConversationTopic, weakPhrases: [String], history: [ChatMessage], userTranscript: String) -> [ChatCompletionMessage] {
        var messages = [ChatCompletionMessage(role: "system", content: systemPrompt(language: language, level: level, topic: topic, weakPhrases: weakPhrases))]
        for message in history.suffix(12) where message.role != .system {
            messages.append(ChatCompletionMessage(role: message.role == .user ? "user" : "assistant", content: message.text))
        }
        messages.append(ChatCompletionMessage(role: "user", content: "The learner just said (speech recognition, may contain errors): \"\(userTranscript)\". Analyze and respond in JSON only."))
        return messages
    }

    private func systemPrompt(language: Language, level: ConversationLevel, topic: ConversationTopic, weakPhrases: [String]) -> String {
        let weakBlock = weakPhrases.isEmpty
            ? "No saved weak phrases yet."
            : "When natural, nudge reuse of: \(weakPhrases.map { "\"\($0)\"" }.joined(separator: ", "))."
        return """
        You are \(language.tutorName), a warm \(language.languageInstruction) conversation tutor. \
        The learner understands from reading/listening but freezes when speaking.

        LEVEL: \(level.displayName). \(level.systemGuidance)
        TOPIC: \(topic.displayName). \(topic.tutorGuidance)
        WEAK VOCAB: \(weakBlock)

        Each turn return JSON:
        {
          "reply": "response in \(language.languageInstruction) ending with a question",
          "starters": ["2-3 sentence stems in target language"],
          "corrections": [{"type":"tense|grammar|vocabulary|englishLeak|pronunciation","original":"...","corrected":"...","explanation":"..."}],
          "suggestedUpgrade": null,
          "encouragement": null
        }
        Reply and starters in \(language.languageInstruction) only. Explanations in English. Be kind. Stay on topic.
        """
    }

    private func decode<T: Decodable>(_ type: T.Type, from content: String) throws -> T {
        guard let data = content.data(using: .utf8) else { throw OpenAIError.decodingFailed("Invalid UTF-8") }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw OpenAIError.decodingFailed(error.localizedDescription) }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatCompletionMessage]
    let temperature: Double
    let response_format: ResponseFormat
}
private struct ChatCompletionMessage: Encodable { let role: String; let content: String }
private struct ResponseFormat: Encodable { let type: String }
private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable { let message: Message }
    struct Message: Decodable { let content: String? }
}
private struct OpenAIAPIErrorEnvelope: Decodable {
    let error: OpenAIAPIError
    struct OpenAIAPIError: Decodable { let message: String }
}
