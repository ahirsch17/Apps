import Foundation

enum OpenAIError: LocalizedError {
    case missingKey, badResponse, api(String)
    var errorDescription: String? {
        switch self {
        case .missingKey: return "Add an API key in Profile to unlock Call & Text."
        case .badResponse: return "Couldn't read the tutor response."
        case .api(let m): return m
        }
    }
}

struct OpenAIService {
    func chat(
        apiKey: String,
        model: String,
        system: String,
        messages: [(role: String, content: String)],
        temperature: Double = 0.7
    ) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw OpenAIError.missingKey }

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var payloadMessages: [[String: String]] = [["role": "system", "content": system]]
        payloadMessages += messages.map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "temperature": temperature,
            "response_format": ["type": "json_object"],
            "messages": payloadMessages
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = j["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw OpenAIError.api(msg)
            }
            throw OpenAIError.api("HTTP \(http.statusCode)")
        }
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw OpenAIError.badResponse }
        return content
    }

    func decodeTurn(_ content: String) throws -> TutorTurn {
        guard let data = content.data(using: .utf8) else { throw OpenAIError.badResponse }
        return try JSONDecoder().decode(TutorTurn.self, from: data)
    }

    func decodeReport(_ content: String) throws -> CallReport {
        guard let data = content.data(using: .utf8) else { throw OpenAIError.badResponse }
        return try JSONDecoder().decode(CallReport.self, from: data)
    }
}
