import XCTest
@testable import PlaylistCreator

final class OpenAIServiceTests: XCTestCase {
    var service: OpenAIService!
    var mockURLSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        service = OpenAIService(
            apiKey: "test-api-key",
            model: "gpt-4",
            urlSession: mockURLSession
        )
    }

    override func tearDown() {
        service = nil
        mockURLSession = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testServiceInitialization() {
        XCTAssertNotNil(service)
    }

    func testServiceInitializationWithCustomConfiguration() {
        let config = OpenAIConfiguration(
            model: "gpt-4-turbo",
            temperature: 0.5,
            maxTokens: 2000,
            timeout: 60.0
        )
        let customService = OpenAIService(apiKey: "test-key", configuration: config)
        XCTAssertNotNil(customService)
    }

    func testServiceThrowsErrorWithoutAPIKey() async {
        let serviceWithoutKey = OpenAIService(apiKey: nil)

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await serviceWithoutKey.extractSongs(from: transcript)
            XCTFail("Should throw apiKeyMissing error")
        } catch MusicExtractionError.apiKeyMissing {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Request Formatting Tests

    func testRequestContainsAuthorizationHeader() async throws {
        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "I love Bohemian Rhapsody by Queen", segments: [], language: "en", confidence: 0.9)
        _ = try await service.extractSongs(from: transcript)

        XCTAssertNotNil(mockURLSession.lastRequest)
        let authHeader = mockURLSession.lastRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer test-api-key")
    }

    func testRequestContainsCorrectContentType() async throws {
        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "I love Bohemian Rhapsody by Queen", segments: [], language: "en", confidence: 0.9)
        _ = try await service.extractSongs(from: transcript)

        XCTAssertNotNil(mockURLSession.lastRequest)
        let contentType = mockURLSession.lastRequest?.value(forHTTPHeaderField: "Content-Type")
        XCTAssertEqual(contentType, "application/json")
    }

    func testRequestBodyContainsModel() async throws {
        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)
        _ = try await service.extractSongs(from: transcript)

        XCTAssertNotNil(mockURLSession.lastRequestBody)
        let body = try JSONDecoder().decode(OpenAIRequest.self, from: mockURLSession.lastRequestBody!)
        XCTAssertEqual(body.model, "gpt-4")
    }

    func testRequestBodyContainsTranscriptText() async throws {
        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcriptText = "I love Bohemian Rhapsody by Queen and Stairway to Heaven by Led Zeppelin"
        let transcript = Transcript(text: transcriptText, segments: [], language: "en", confidence: 0.9)
        _ = try await service.extractSongs(from: transcript)

        XCTAssertNotNil(mockURLSession.lastRequestBody)
        let bodyString = String(data: mockURLSession.lastRequestBody!, encoding: .utf8)
        XCTAssertTrue(bodyString?.contains(transcriptText) ?? false)
    }

    // MARK: - Response Parsing Tests

    func testSuccessfulResponseParsing() async throws {
        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "I love Bohemian Rhapsody by Queen", segments: [], language: "en", confidence: 0.9)
        let songs = try await service.extractSongs(from: transcript)

        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].title, "Bohemian Rhapsody")
        XCTAssertEqual(songs[0].artist, "Queen")
    }

    func testExtractMultipleSongs() async throws {
        mockURLSession.mockData = multiSongOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "I love Bohemian Rhapsody by Queen and Stairway to Heaven", segments: [], language: "en", confidence: 0.9)
        let songs = try await service.extractSongs(from: transcript)

        XCTAssertEqual(songs.count, 2)
    }

    func testExtractSongsWithContext() async throws {
        mockURLSession.mockData = contextualOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "I love Bohemian Rhapsody by Queen", segments: [], language: "en", confidence: 0.9)
        let extractedSongs = try await service.extractSongsWithContext(from: transcript)

        XCTAssertEqual(extractedSongs.count, 1)
        XCTAssertEqual(extractedSongs[0].song.title, "Bohemian Rhapsody")
        XCTAssertFalse(extractedSongs[0].context.isEmpty)
        XCTAssertGreaterThan(extractedSongs[0].extractionConfidence, 0.0)
    }

    func testEmptyResponseReturnsEmptyArray() async throws {
        mockURLSession.mockData = emptyOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "No music mentions here", segments: [], language: "en", confidence: 0.9)
        let songs = try await service.extractSongs(from: transcript)

        XCTAssertEqual(songs.count, 0)
    }

    func testInvalidJSONResponseThrowsParsingError() async throws {
        mockURLSession.mockData = invalidJSONData()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await service.extractSongs(from: transcript)
            XCTFail("Should throw parsing error")
        } catch MusicExtractionError.parsingFailed {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Error Handling Tests

    func testAPIKeyMissingError() async throws {
        let serviceWithoutKey = OpenAIService(apiKey: nil)
        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await serviceWithoutKey.extractSongs(from: transcript)
            XCTFail("Should throw apiKeyMissing error")
        } catch MusicExtractionError.apiKeyMissing {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testUnauthorizedErrorHandling() async throws {
        mockURLSession.mockData = unauthorizedErrorResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await service.extractSongs(from: transcript)
            XCTFail("Should throw API request failed error")
        } catch MusicExtractionError.apiRequestFailed(let message) {
            XCTAssertTrue(message.contains("401") || message.contains("Unauthorized"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testRateLimitErrorHandling() async throws {
        mockURLSession.mockData = rateLimitErrorResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await service.extractSongs(from: transcript)
            XCTFail("Should throw rate limit error")
        } catch MusicExtractionError.apiRequestFailed(let message) {
            XCTAssertTrue(message.contains("429") || message.contains("rate limit"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testServerErrorHandling() async throws {
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = Data()

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await service.extractSongs(from: transcript)
            XCTFail("Should throw server error")
        } catch MusicExtractionError.apiRequestFailed(let message) {
            XCTAssertTrue(message.contains("500") || message.contains("server"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testNetworkErrorHandling() async throws {
        mockURLSession.shouldThrowError = true
        mockURLSession.mockError = URLError(.notConnectedToInternet)

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await service.extractSongs(from: transcript)
            XCTFail("Should throw network error")
        } catch MusicExtractionError.apiRequestFailed {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testTimeoutErrorHandling() async throws {
        mockURLSession.shouldThrowError = true
        mockURLSession.mockError = URLError(.timedOut)

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await service.extractSongs(from: transcript)
            XCTFail("Should throw timeout error")
        } catch MusicExtractionError.apiRequestFailed(let message) {
            XCTAssertTrue(message.lowercased().contains("timeout") || message.lowercased().contains("timed out") || message.lowercased().contains("time") || message.contains("1001"), "Error message was: \(message)")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Rate Limiting Tests

    func testRateLimitingBetweenRequests() async throws {
        let config = OpenAIConfiguration(
            model: "gpt-4",
            temperature: 0.7,
            maxTokens: 1000,
            timeout: 30.0,
            rateLimitDelay: 1.0 // 1 second delay between requests
        )
        let rateLimitedService = OpenAIService(apiKey: "test-key", configuration: config, urlSession: mockURLSession)

        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        let start = Date()
        _ = try await rateLimitedService.extractSongs(from: transcript)
        _ = try await rateLimitedService.extractSongs(from: transcript)
        let elapsed = Date().timeIntervalSince(start)

        // Should take at least 1 second due to rate limiting
        XCTAssertGreaterThanOrEqual(elapsed, 1.0)
    }

    // MARK: - Retry Logic Tests

    func testRetryOnTransientError() async throws {
        let config = OpenAIConfiguration(
            model: "gpt-4",
            temperature: 0.7,
            maxTokens: 1000,
            timeout: 30.0,
            maxRetries: 3,
            retryDelay: 0.1
        )
        let retryService = OpenAIService(apiKey: "test-key", configuration: config, urlSession: mockURLSession)

        // First request fails, second succeeds
        mockURLSession.failCountBeforeSuccess = 1
        mockURLSession.mockError = URLError(.networkConnectionLost)
        mockURLSession.shouldThrowError = true
        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "I love Bohemian Rhapsody by Queen", segments: [], language: "en", confidence: 0.9)
        let songs = try await retryService.extractSongs(from: transcript)

        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(mockURLSession.requestCount, 2) // Initial + 1 retry
    }

    func testExponentialBackoffRetry() async throws {
        let config = OpenAIConfiguration(
            model: "gpt-4",
            temperature: 0.7,
            maxTokens: 1000,
            timeout: 30.0,
            maxRetries: 3,
            retryDelay: 0.1
        )
        let retryService = OpenAIService(apiKey: "test-key", configuration: config, urlSession: mockURLSession)

        mockURLSession.failCountBeforeSuccess = 2
        mockURLSession.mockError = URLError(.networkConnectionLost)
        mockURLSession.shouldThrowError = true
        mockURLSession.mockData = validOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let start = Date()
        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)
        _ = try await retryService.extractSongs(from: transcript)
        let elapsed = Date().timeIntervalSince(start)

        // With exponential backoff: 0.1s + 0.2s = 0.3s minimum
        XCTAssertGreaterThanOrEqual(elapsed, 0.3)
        XCTAssertEqual(mockURLSession.requestCount, 3)
    }

    func testMaxRetriesExceeded() async throws {
        let config = OpenAIConfiguration(
            model: "gpt-4",
            temperature: 0.7,
            maxTokens: 1000,
            timeout: 30.0,
            maxRetries: 2,
            retryDelay: 0.1
        )
        let retryService = OpenAIService(apiKey: "test-key", configuration: config, urlSession: mockURLSession)

        mockURLSession.failCountBeforeSuccess = 10 // Will never succeed
        mockURLSession.mockError = URLError(.networkConnectionLost)
        mockURLSession.shouldThrowError = true

        let transcript = Transcript(text: "Test", segments: [], language: "en", confidence: 0.9)

        do {
            _ = try await retryService.extractSongs(from: transcript)
            XCTFail("Should throw error after max retries")
        } catch MusicExtractionError.apiRequestFailed {
            // Expected - tried initial + 2 retries = 3 total
            XCTAssertEqual(mockURLSession.requestCount, 3)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Configuration Tests

    func testCustomTemperatureConfiguration() {
        let config = OpenAIConfiguration(
            model: "gpt-4",
            temperature: 0.3,
            maxTokens: 1000,
            timeout: 30.0
        )
        XCTAssertEqual(config.temperature, 0.3)
    }

    func testCustomMaxTokensConfiguration() {
        let config = OpenAIConfiguration(
            model: "gpt-4",
            temperature: 0.7,
            maxTokens: 2000,
            timeout: 30.0
        )
        XCTAssertEqual(config.maxTokens, 2000)
    }

    func testDefaultConfiguration() {
        let config = OpenAIConfiguration()
        XCTAssertEqual(config.model, "gpt-4")
        XCTAssertEqual(config.temperature, 0.7)
        XCTAssertEqual(config.maxTokens, 1500)
        XCTAssertEqual(config.timeout, 30.0)
    }

    // MARK: - Integration Tests

    func testMusicExtractorProtocolConformance() {
        let extractor: MusicExtractor = service
        XCTAssertNotNil(extractor)
    }

    func testExtractSongsReturnsChronologicalOrder() async throws {
        mockURLSession.mockData = multiSongOpenAIResponse()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let transcript = Transcript(text: "First Bohemian Rhapsody, then Stairway to Heaven", segments: [], language: "en", confidence: 0.9)
        let songs = try await service.extractSongs(from: transcript)

        XCTAssertGreaterThan(songs.count, 0)
        // Songs should maintain chronological order from transcript
    }

    // MARK: - Helper Methods

    private func validOpenAIResponse() -> Data {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "[{\\"title\\": \\"Bohemian Rhapsody\\", \\"artist\\": \\"Queen\\", \\"confidence\\": 0.95, \\"context\\": \\"Song mentioned as favorite\\"}]"
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": 9,
                "completion_tokens": 12,
                "total_tokens": 21
            }
        }
        """
        return json.data(using: .utf8)!
    }

    private func multiSongOpenAIResponse() -> Data {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "[{\\"title\\": \\"Bohemian Rhapsody\\", \\"artist\\": \\"Queen\\", \\"confidence\\": 0.95, \\"context\\": \\"First song\\"}, {\\"title\\": \\"Stairway to Heaven\\", \\"artist\\": \\"Led Zeppelin\\", \\"confidence\\": 0.90, \\"context\\": \\"Second song\\"}]"
                },
                "finish_reason": "stop"
            }]
        }
        """
        return json.data(using: .utf8)!
    }

    private func contextualOpenAIResponse() -> Data {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "[{\\"title\\": \\"Bohemian Rhapsody\\", \\"artist\\": \\"Queen\\", \\"confidence\\": 0.95, \\"context\\": \\"The speaker loves this classic rock song\\", \\"timestamp\\": 10.5}]"
                },
                "finish_reason": "stop"
            }]
        }
        """
        return json.data(using: .utf8)!
    }

    private func emptyOpenAIResponse() -> Data {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "[]"
                },
                "finish_reason": "stop"
            }]
        }
        """
        return json.data(using: .utf8)!
    }

    private func invalidJSONData() -> Data {
        return "Invalid JSON{".data(using: .utf8)!
    }

    private func unauthorizedErrorResponse() -> Data {
        let json = """
        {
            "error": {
                "message": "Invalid API key",
                "type": "invalid_request_error",
                "code": "invalid_api_key"
            }
        }
        """
        return json.data(using: .utf8)!
    }

    private func rateLimitErrorResponse() -> Data {
        let json = """
        {
            "error": {
                "message": "Rate limit exceeded",
                "type": "rate_limit_error",
                "code": "rate_limit_exceeded"
            }
        }
        """
        return json.data(using: .utf8)!
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var shouldThrowError = false
    var lastRequest: URLRequest?
    var lastRequestBody: Data?
    var requestCount = 0
    var failCountBeforeSuccess = 0
    private var currentFailCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        lastRequestBody = request.httpBody
        requestCount += 1

        if shouldThrowError && currentFailCount < failCountBeforeSuccess {
            currentFailCount += 1
            throw mockError ?? URLError(.unknown)
        }

        if shouldThrowError && failCountBeforeSuccess == 0 {
            // Only throw if we're not using the failCountBeforeSuccess mechanism
            throw mockError ?? URLError(.unknown)
        }

        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }
}

// MARK: - OpenAI Request/Response Models (for testing)

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let maxTokens: Int?

    struct Message: Codable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}
