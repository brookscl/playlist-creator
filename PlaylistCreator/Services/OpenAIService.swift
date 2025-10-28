import Foundation

// MARK: - URL Session Protocol

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Configuration

struct OpenAIConfiguration {
    let model: String
    let temperature: Double
    let maxTokens: Int
    let timeout: TimeInterval
    let maxRetries: Int
    let retryDelay: TimeInterval
    let rateLimitDelay: TimeInterval

    init(model: String = "gpt-4",
         temperature: Double = 0.7,
         maxTokens: Int = 1500,
         timeout: TimeInterval = 30.0,
         maxRetries: Int = 3,
         retryDelay: TimeInterval = 1.0,
         rateLimitDelay: TimeInterval = 0.0) {
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.rateLimitDelay = rateLimitDelay
    }
}

// MARK: - OpenAI Service

class OpenAIService: MusicExtractor {
    private let apiKey: String?
    private let configuration: OpenAIConfiguration
    private let urlSession: URLSessionProtocol
    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    private var lastRequestTime: Date?

    init(apiKey: String?,
         model: String = "gpt-4",
         urlSession: URLSessionProtocol = URLSession.shared) {
        self.apiKey = apiKey
        self.configuration = OpenAIConfiguration(model: model)
        self.urlSession = urlSession
    }

    init(apiKey: String?,
         configuration: OpenAIConfiguration,
         urlSession: URLSessionProtocol = URLSession.shared) {
        self.apiKey = apiKey
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - MusicExtractor Protocol

    func extractSongs(from transcript: Transcript) async throws -> [Song] {
        let extractedSongs = try await extractSongsWithContext(from: transcript)
        return extractedSongs.map { $0.song }
    }

    func extractSongsWithContext(from transcript: Transcript) async throws -> [ExtractedSong] {
        guard apiKey != nil else {
            throw MusicExtractionError.apiKeyMissing
        }

        // Apply rate limiting
        await applyRateLimit()

        // Build and send request with retry logic
        let response = try await sendRequestWithRetry(transcript: transcript)

        // Parse response
        return try parseResponse(response)
    }

    // MARK: - Rate Limiting

    private func applyRateLimit() async {
        guard configuration.rateLimitDelay > 0 else { return }

        if let lastRequest = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastRequest)
            let remaining = configuration.rateLimitDelay - elapsed

            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
        }

        lastRequestTime = Date()
    }

    // MARK: - Request Building

    private func buildRequest(transcript: Transcript) throws -> URLRequest {
        guard let url = URL(string: apiEndpoint) else {
            throw MusicExtractionError.apiRequestFailed("Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = configuration.timeout

        let requestBody = OpenAIRequestBody(
            model: configuration.model,
            messages: [
                OpenAIMessage(
                    role: "system",
                    content: buildSystemPrompt()
                ),
                OpenAIMessage(
                    role: "user",
                    content: buildUserPrompt(transcript: transcript)
                )
            ],
            temperature: configuration.temperature,
            maxTokens: configuration.maxTokens
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)

        return request
    }

    private func buildSystemPrompt() -> String {
        return """
        You are a music extraction assistant. Your task is to identify and extract all music mentions (songs, artists, albums) from transcripts.

        Return results as a JSON array of objects with these fields:
        - title: Song title (string)
        - artist: Artist name (string)
        - confidence: Confidence score 0.0-1.0 (number)
        - context: Brief context of the mention (string)
        - timestamp: Optional timestamp in seconds (number or null)

        Extract ALL music mentions, even casual references. Preserve chronological order. Be thorough but accurate.
        Return only the JSON array, no additional text.
        """
    }

    private func buildUserPrompt(transcript: Transcript) -> String {
        var prompt = "Extract all music mentions from this transcript:\n\n"
        prompt += transcript.text

        if !transcript.segments.isEmpty {
            prompt += "\n\nTimestamps are available for context."
        }

        return prompt
    }

    // MARK: - Request Sending with Retry

    private func sendRequestWithRetry(transcript: Transcript, attempt: Int = 0) async throws -> OpenAIResponse {
        do {
            let request = try buildRequest(transcript: transcript)
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MusicExtractionError.apiRequestFailed("Invalid response type")
            }

            // Handle HTTP errors
            try validateHTTPResponse(httpResponse, data: data)

            // Parse successful response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(OpenAIResponse.self, from: data)

        } catch let error as MusicExtractionError {
            // Don't retry on certain errors
            if case .apiKeyMissing = error {
                throw error
            }

            // Retry on transient errors
            if attempt < configuration.maxRetries {
                let delay = configuration.retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await sendRequestWithRetry(transcript: transcript, attempt: attempt + 1)
            }

            throw error

        } catch {
            // Retry on network errors
            if attempt < configuration.maxRetries {
                let delay = configuration.retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await sendRequestWithRetry(transcript: transcript, attempt: attempt + 1)
            }

            throw MusicExtractionError.apiRequestFailed(error.localizedDescription)
        }
    }

    private func validateHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return

        case 401:
            throw MusicExtractionError.apiRequestFailed("Unauthorized: Invalid API key (401)")

        case 429:
            let message = parseErrorMessage(from: data) ?? "Rate limit exceeded"
            throw MusicExtractionError.apiRequestFailed("Rate limit exceeded (429): \(message)")

        case 500...599:
            let message = parseErrorMessage(from: data) ?? "Server error"
            throw MusicExtractionError.apiRequestFailed("Server error (\(response.statusCode)): \(message)")

        default:
            let message = parseErrorMessage(from: data) ?? "Unknown error"
            throw MusicExtractionError.apiRequestFailed("API error (\(response.statusCode)): \(message)")
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }

    // MARK: - Response Parsing

    private func parseResponse(_ response: OpenAIResponse) throws -> [ExtractedSong] {
        guard let firstChoice = response.choices.first else {
            return []
        }

        let content = firstChoice.message.content

        // Parse JSON array from content
        guard let jsonData = content.data(using: .utf8) else {
            throw MusicExtractionError.parsingFailed("Failed to encode content as UTF-8")
        }

        do {
            let extractedItems = try JSONDecoder().decode([ExtractedMusicItem].self, from: jsonData)
            return extractedItems.map { item in
                let song = Song(
                    title: item.title,
                    artist: item.artist,
                    appleID: nil,
                    confidence: item.confidence
                )

                return ExtractedSong(
                    song: song,
                    context: item.context ?? "",
                    timestamp: item.timestamp,
                    extractionConfidence: item.confidence
                )
            }
        } catch {
            throw MusicExtractionError.parsingFailed("Failed to parse music items: \(error.localizedDescription)")
        }
    }
}

// MARK: - Request/Response Models

private struct OpenAIRequestBody: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]

    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String

        struct Message: Codable {
            let role: String
            let content: String
        }
    }
}

private struct ExtractedMusicItem: Codable {
    let title: String
    let artist: String
    let confidence: Double
    let context: String?
    let timestamp: TimeInterval?
}
