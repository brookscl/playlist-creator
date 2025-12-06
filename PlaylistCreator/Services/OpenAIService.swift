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

    init(model: String = "gpt-4o-mini",
         temperature: Double = 0.7,
         maxTokens: Int = 4096,
         timeout: TimeInterval = 120.0,
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
    private let settingsManager: SettingsManager
    private let configuration: OpenAIConfiguration
    private let urlSession: URLSessionProtocol
    private let normalizer: MusicDataNormalizer
    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    private var lastRequestTime: Date?

    init(apiKey: String?,
         model: String = "gpt-4",
         urlSession: URLSessionProtocol = URLSession.shared,
         normalizer: MusicDataNormalizer = MusicDataNormalizer()) {
        // For backwards compatibility with tests
        self.settingsManager = SettingsManager()
        self.configuration = OpenAIConfiguration(model: model)
        self.urlSession = urlSession
        self.normalizer = normalizer

        // Store the provided API key if given
        if let apiKey = apiKey {
            try? settingsManager.saveAPIKey(apiKey)
        }
    }

    init(apiKey: String?,
         configuration: OpenAIConfiguration,
         urlSession: URLSessionProtocol = URLSession.shared,
         normalizer: MusicDataNormalizer = MusicDataNormalizer()) {
        // For backwards compatibility with tests
        self.settingsManager = SettingsManager()
        self.configuration = configuration
        self.urlSession = urlSession
        self.normalizer = normalizer

        // Store the provided API key if given
        if let apiKey = apiKey {
            try? settingsManager.saveAPIKey(apiKey)
        }
    }

    // Convenience initializer using SettingsManager (RECOMMENDED)
    convenience init(settingsManager: SettingsManager = .shared,
                     urlSession: URLSessionProtocol = URLSession.shared,
                     normalizer: MusicDataNormalizer = MusicDataNormalizer()) {
        let configuration = OpenAIConfiguration(
            model: settingsManager.openAIModel,
            temperature: settingsManager.openAITemperature,
            maxTokens: settingsManager.openAIMaxTokens
        )
        self.init(settingsManager: settingsManager, configuration: configuration, urlSession: urlSession, normalizer: normalizer)
    }

    // Primary initializer that stores SettingsManager reference
    init(settingsManager: SettingsManager,
         configuration: OpenAIConfiguration,
         urlSession: URLSessionProtocol = URLSession.shared,
         normalizer: MusicDataNormalizer = MusicDataNormalizer()) {
        self.settingsManager = settingsManager
        self.configuration = configuration
        self.urlSession = urlSession
        self.normalizer = normalizer
    }

    // MARK: - MusicExtractor Protocol

    func extractSongs(from transcript: Transcript) async throws -> [Song] {
        let extractedSongs = try await extractSongsWithContext(from: transcript)
        return extractedSongs.map { $0.song }
    }

    func extractSongsWithContext(from transcript: Transcript) async throws -> [ExtractedSong] {
        // Get API key from settings at time of use (not cached at initialization)
        guard let apiKey = try? settingsManager.getAPIKey(), !apiKey.isEmpty else {
            print("❌ OpenAI API key not found in settings")
            throw MusicExtractionError.apiKeyMissing
        }

        print("✅ Retrieved OpenAI API key from settings")

        // Check if transcript is very large and needs chunking
        let maxChunkSize = 15000 // characters (~3750 tokens)
        if transcript.text.count > maxChunkSize {
            print("⚠️ Large transcript detected (\(transcript.text.count) chars), processing in chunks...")
            return try await extractSongsFromLargeTranscript(transcript, apiKey: apiKey, chunkSize: maxChunkSize)
        }

        // Apply rate limiting
        await applyRateLimit()

        // Build and send request with retry logic
        let response = try await sendRequestWithRetry(transcript: transcript, apiKey: apiKey)

        // Parse response
        return try parseResponse(response)
    }

    private func extractSongsFromLargeTranscript(_ transcript: Transcript, apiKey: String, chunkSize: Int) async throws -> [ExtractedSong] {
        // Split transcript into chunks
        let chunks = splitTranscriptIntoChunks(transcript, maxSize: chunkSize)
        print("📦 Split transcript into \(chunks.count) chunks")

        var allSongs: [ExtractedSong] = []

        // Process each chunk
        for (index, chunk) in chunks.enumerated() {
            print("🔄 Processing chunk \(index + 1)/\(chunks.count)...")

            // Apply rate limiting between chunks
            await applyRateLimit()

            // Send request for this chunk
            let response = try await sendRequestWithRetry(transcript: chunk, apiKey: apiKey)

            // Parse and collect songs
            let songs = try parseResponse(response)
            allSongs.append(contentsOf: songs)

            print("✅ Chunk \(index + 1) complete: found \(songs.count) songs")
        }

        // Remove duplicates across chunks
        var uniqueSongs: [ExtractedSong] = []
        for song in allSongs {
            if !uniqueSongs.contains(where: { normalizer.areLikelyDuplicates($0.song, song.song) }) {
                uniqueSongs.append(song)
            }
        }

        print("✅ Total unique songs found: \(uniqueSongs.count)")
        return uniqueSongs
    }

    private func splitTranscriptIntoChunks(_ transcript: Transcript, maxSize: Int) -> [Transcript] {
        let text = transcript.text
        guard text.count > maxSize else {
            return [transcript]
        }

        var chunks: [Transcript] = []
        var currentStart = text.startIndex

        while currentStart < text.endIndex {
            // Calculate chunk end
            let remainingCount = text.distance(from: currentStart, to: text.endIndex)
            let chunkLength = min(maxSize, remainingCount)
            var currentEnd = text.index(currentStart, offsetBy: chunkLength)

            // Try to break at sentence boundary if not at the end
            if currentEnd < text.endIndex {
                // Look back up to 500 characters for a sentence boundary
                let lookbackDistance = min(500, chunkLength)
                let lookbackStart = text.index(currentEnd, offsetBy: -lookbackDistance)

                if let lastPeriod = text[lookbackStart..<currentEnd].lastIndex(where: { $0 == "." || $0 == "!" || $0 == "?" }) {
                    currentEnd = text.index(after: lastPeriod)
                }
            }

            // Extract chunk text
            let chunkText = String(text[currentStart..<currentEnd])

            // Create chunk transcript (without segments for simplicity)
            let chunkTranscript = Transcript(
                text: chunkText,
                segments: [],
                language: transcript.language,
                confidence: transcript.confidence
            )

            chunks.append(chunkTranscript)
            currentStart = currentEnd
        }

        return chunks
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

    private func buildRequest(transcript: Transcript, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: apiEndpoint) else {
            throw MusicExtractionError.apiRequestFailed("Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
        You are an expert music extraction assistant specializing in identifying song and artist mentions from conversational transcripts.

        TASK: Extract ALL music mentions (songs with artists) from the provided transcript.

        EXTRACTION RULES:
        1. Extract EVERY song mention, including casual references, recommendations, and discussions
        2. Always provide both song title AND artist name - never extract one without the other
        3. If only a song title is mentioned, use context to infer the artist (if possible)
        4. If only an artist is mentioned without specific songs, DO NOT extract
        5. Preserve the chronological order from the transcript
        6. Handle various formats: "Song by Artist", "Artist's Song", "Song - Artist", etc.
        7. Clean up formatting but preserve proper capitalization

        CONFIDENCE SCORING (0.0-1.0):
        - 0.9-1.0: Explicit mention with clear song + artist
        - 0.7-0.89: Clear mention but requires minor context inference
        - 0.5-0.69: Implied mention with reasonable context support
        - Below 0.5: Uncertain or ambiguous

        OUTPUT FORMAT - JSON array with these exact fields:
        - title: Song title (string, properly capitalized)
        - artist: Artist name (string, properly capitalized)
        - confidence: Score 0.0-1.0 (number)
        - context: Brief quote showing the mention (string, max 100 chars)
        - timestamp: Time in seconds if available (number or null)

        IMPORTANT: Return ONLY the JSON array, no markdown, no explanations, no additional text.
        If no songs found, return empty array: []
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

    private func sendRequestWithRetry(transcript: Transcript, apiKey: String, attempt: Int = 0) async throws -> OpenAIResponse {
        do {
            let request = try buildRequest(transcript: transcript, apiKey: apiKey)
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

        } catch let error as DecodingError {
            // JSON parsing errors shouldn't be retried
            throw MusicExtractionError.parsingFailed(error.localizedDescription)

        } catch let error as MusicExtractionError {
            // Don't retry on certain errors
            if case .apiKeyMissing = error {
                throw error
            }

            // Retry on transient errors
            if attempt < configuration.maxRetries {
                let delay = configuration.retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await sendRequestWithRetry(transcript: transcript, apiKey: apiKey, attempt: attempt + 1)
            }

            throw error

        } catch {
            // Retry on network errors
            if attempt < configuration.maxRetries {
                let delay = configuration.retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await sendRequestWithRetry(transcript: transcript, apiKey: apiKey, attempt: attempt + 1)
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

    private func stripMarkdownCodeBlocks(from content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code block markers (```json ... ``` or ``` ... ```)
        if cleaned.hasPrefix("```") {
            // Find the first newline after ```
            if let firstNewline = cleaned.firstIndex(of: "\n") {
                cleaned = String(cleaned[cleaned.index(after: firstNewline)...])
            }

            // Remove trailing ```
            if cleaned.hasSuffix("```") {
                cleaned = String(cleaned.dropLast(3))
            }

            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    private func parseResponse(_ response: OpenAIResponse) throws -> [ExtractedSong] {
        guard let firstChoice = response.choices.first else {
            return []
        }

        let content = firstChoice.message.content

        // Clean the content - remove markdown code blocks if present
        let cleanedContent = stripMarkdownCodeBlocks(from: content)

        // Parse JSON array from content
        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw MusicExtractionError.parsingFailed("Failed to encode content as UTF-8")
        }

        do {
            let extractedItems = try JSONDecoder().decode([ExtractedMusicItem].self, from: jsonData)
            var processedSongs: [ExtractedSong] = []

            for item in extractedItems {
                // Normalize title and artist
                let normalizedTitle = normalizer.normalizeSongTitle(item.title)
                let normalizedArtist = normalizer.normalizeArtistName(item.artist)

                // Adjust confidence based on data quality
                let adjustedConfidence = normalizer.adjustConfidence(
                    item.confidence,
                    title: normalizedTitle,
                    artist: normalizedArtist
                )

                let song = Song(
                    title: normalizedTitle,
                    artist: normalizedArtist,
                    appleID: nil,
                    confidence: adjustedConfidence
                )

                let extractedSong = ExtractedSong(
                    song: song,
                    context: item.context ?? "",
                    timestamp: item.timestamp,
                    extractionConfidence: adjustedConfidence
                )

                // Check for duplicates before adding
                if !processedSongs.contains(where: { normalizer.areLikelyDuplicates($0.song, song) }) {
                    processedSongs.append(extractedSong)
                }
            }

            return processedSongs
        } catch {
            // Log the actual content for debugging
            print("❌ Failed to parse OpenAI response")
            print("📄 Raw content: \(content)")
            print("🧹 Cleaned content: \(cleanedContent)")
            print("⚠️ Error: \(error)")
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
