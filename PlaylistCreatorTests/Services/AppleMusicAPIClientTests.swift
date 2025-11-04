import XCTest
@testable import PlaylistCreator

@available(macOS 12.0, *)
final class AppleMusicAPIClientTests: XCTestCase {
    var apiClient: AppleMusicAPIClient!
    var mockHTTPClient: MockHTTPClient!
    var mockTokenGenerator: MockDeveloperTokenGenerator!
    var mockMusicKitWrapper: MockMusicKitWrapper!

    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        mockTokenGenerator = MockDeveloperTokenGenerator()
        mockMusicKitWrapper = MockMusicKitWrapper()

        apiClient = AppleMusicAPIClient(
            httpClient: mockHTTPClient,
            developerTokenGenerator: mockTokenGenerator,
            musicKitWrapper: mockMusicKitWrapper
        )
    }

    override func tearDown() {
        apiClient = nil
        mockHTTPClient = nil
        mockTokenGenerator = nil
        mockMusicKitWrapper = nil
        super.tearDown()
    }

    // MARK: - Developer Token Tests

    func testDeveloperTokenGeneration() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "test.developer.token"

        // When
        let token = try await apiClient.getDeveloperToken()

        // Then
        XCTAssertEqual(token, "test.developer.token")
        XCTAssertTrue(mockTokenGenerator.generateTokenCalled)
    }

    func testDeveloperTokenCaching() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "cached.token"

        // When
        let token1 = try await apiClient.getDeveloperToken()
        let token2 = try await apiClient.getDeveloperToken()

        // Then
        XCTAssertEqual(token1, token2)
        XCTAssertEqual(mockTokenGenerator.generateTokenCallCount, 1, "Token should be cached")
    }

    func testDeveloperTokenExpiration() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "expired.token"
        mockTokenGenerator.tokenExpiresIn = 0 // Expired immediately

        // When
        _ = try await apiClient.getDeveloperToken()

        // Advance time (simulated by clearing cache)
        apiClient.clearTokenCache()

        mockTokenGenerator.tokenToReturn = "new.token"
        let newToken = try await apiClient.getDeveloperToken()

        // Then
        XCTAssertEqual(newToken, "new.token")
        XCTAssertEqual(mockTokenGenerator.generateTokenCallCount, 2)
    }

    // MARK: - User Token Tests

    func testUserTokenRetrieval() async throws {
        // Given
        mockMusicKitWrapper.userToken = "user.music.token"

        // When
        let token = try await apiClient.getUserToken()

        // Then
        XCTAssertEqual(token, "user.music.token")
    }

    func testUserTokenFailsWhenNotAuthorized() async throws {
        // Given
        mockMusicKitWrapper.authorizationStatus = .denied
        mockMusicKitWrapper.userToken = nil

        // When/Then
        do {
            _ = try await apiClient.getUserToken()
            XCTFail("Should throw error when not authorized")
        } catch {
            XCTAssertTrue(error is AppleMusicAPIError)
        }
    }

    // MARK: - Create Playlist Tests

    func testCreatePlaylistSuccess() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized

        let responseJSON = """
        {
            "data": [{
                "id": "pl.u-test123",
                "type": "library-playlists",
                "href": "/v1/me/library/playlists/pl.u-test123",
                "attributes": {
                    "name": "Test Playlist",
                    "canEdit": true
                }
            }]
        }
        """
        mockHTTPClient.responseData = responseJSON.data(using: .utf8)
        mockHTTPClient.statusCode = 201

        // When
        let result = try await apiClient.createPlaylist(
            name: "Test Playlist",
            description: "Test Description",
            songIDs: ["1234567890", "0987654321"]
        )

        // Then
        XCTAssertEqual(result.id, "pl.u-test123")
        XCTAssertNotNil(result.url)
        XCTAssertTrue(mockHTTPClient.requestCalled)
        XCTAssertEqual(mockHTTPClient.lastMethod, "POST")
        XCTAssertTrue(mockHTTPClient.lastURL?.absoluteString.contains("/v1/me/library/playlists") ?? false)
    }

    func testCreatePlaylistRequestFormat() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized

        mockHTTPClient.responseData = """
        {"data": [{"id": "pl.test", "type": "library-playlists", "attributes": {"name": "Test"}}]}
        """.data(using: .utf8)
        mockHTTPClient.statusCode = 201

        // When
        _ = try await apiClient.createPlaylist(
            name: "My Playlist",
            description: "My Description",
            songIDs: ["123", "456"]
        )

        // Then
        XCTAssertNotNil(mockHTTPClient.lastBody)

        let json = try JSONSerialization.jsonObject(with: mockHTTPClient.lastBody!) as? [String: Any]
        XCTAssertNotNil(json)

        let attributes = (json?["attributes"] as? [String: Any])
        XCTAssertEqual(attributes?["name"] as? String, "My Playlist")
        XCTAssertEqual(attributes?["description"] as? String, "My Description")

        let tracks = (json?["relationships"] as? [String: Any])?["tracks"] as? [String: Any]
        let trackData = (tracks?["data"] as? [[String: Any]])
        XCTAssertEqual(trackData?.count, 2)
    }

    func testCreatePlaylistWithHeaders() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token.123"
        mockMusicKitWrapper.userToken = "user.token.456"
        mockMusicKitWrapper.authorizationStatus = .authorized

        mockHTTPClient.responseData = """
        {"data": [{"id": "pl.test", "type": "library-playlists", "attributes": {"name": "Test"}}]}
        """.data(using: .utf8)
        mockHTTPClient.statusCode = 201

        // When
        _ = try await apiClient.createPlaylist(
            name: "Test",
            description: nil,
            songIDs: []
        )

        // Then
        XCTAssertEqual(mockHTTPClient.lastHeaders?["Authorization"], "Bearer dev.token.123")
        XCTAssertEqual(mockHTTPClient.lastHeaders?["Music-User-Token"], "user.token.456")
        XCTAssertEqual(mockHTTPClient.lastHeaders?["Content-Type"], "application/json")
    }

    func testCreatePlaylistFailsWithBadStatus() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized

        mockHTTPClient.statusCode = 400
        mockHTTPClient.responseData = """
        {"errors": [{"status": "400", "title": "Bad Request"}]}
        """.data(using: .utf8)

        // When/Then
        do {
            _ = try await apiClient.createPlaylist(
                name: "Test",
                description: nil,
                songIDs: []
            )
            XCTFail("Should throw error on bad status")
        } catch let error as AppleMusicAPIError {
            XCTAssertEqual(error, .invalidResponse)
        }
    }

    // MARK: - Add Songs Tests

    func testAddSongsToPlaylist() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized

        mockHTTPClient.statusCode = 204

        // When
        try await apiClient.addSongs(
            to: "pl.u-test123",
            songIDs: ["song1", "song2", "song3"]
        )

        // Then
        XCTAssertTrue(mockHTTPClient.requestCalled)
        XCTAssertEqual(mockHTTPClient.lastMethod, "POST")
        XCTAssertTrue(mockHTTPClient.lastURL?.absoluteString.contains("pl.u-test123/tracks") ?? false)
    }

    func testAddSongsRequestFormat() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockHTTPClient.statusCode = 204

        // When
        try await apiClient.addSongs(
            to: "pl.test",
            songIDs: ["123", "456"]
        )

        // Then
        let json = try JSONSerialization.jsonObject(with: mockHTTPClient.lastBody!) as? [String: Any]
        let data = (json?["data"] as? [[String: Any]])

        XCTAssertEqual(data?.count, 2)
        XCTAssertEqual(data?[0]["id"] as? String, "123")
        XCTAssertEqual(data?[0]["type"] as? String, "songs")
        XCTAssertEqual(data?[1]["id"] as? String, "456")
    }

    // MARK: - Error Handling Tests

    func testNetworkError() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized

        mockHTTPClient.shouldThrowError = true
        mockHTTPClient.errorToThrow = URLError(.notConnectedToInternet)

        // When/Then
        do {
            _ = try await apiClient.createPlaylist(
                name: "Test",
                description: nil,
                songIDs: []
            )
            XCTFail("Should throw network error")
        } catch let error as AppleMusicAPIError {
            XCTAssertEqual(error, .networkError)
        }
    }

    func testUnauthorizedError() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized

        mockHTTPClient.statusCode = 401

        // When/Then
        do {
            _ = try await apiClient.createPlaylist(
                name: "Test",
                description: nil,
                songIDs: []
            )
            XCTFail("Should throw unauthorized error")
        } catch let error as AppleMusicAPIError {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testRateLimitError() async throws {
        // Given
        mockTokenGenerator.tokenToReturn = "dev.token"
        mockMusicKitWrapper.userToken = "user.token"
        mockMusicKitWrapper.authorizationStatus = .authorized

        mockHTTPClient.statusCode = 429

        // When/Then
        do {
            _ = try await apiClient.createPlaylist(
                name: "Test",
                description: nil,
                songIDs: []
            )
            XCTFail("Should throw rate limit error")
        } catch let error as AppleMusicAPIError {
            XCTAssertEqual(error, .rateLimitExceeded)
        }
    }
}

// MARK: - Mock HTTP Client

class MockHTTPClient: HTTPClient {
    var requestCalled = false
    var lastURL: URL?
    var lastMethod: String?
    var lastHeaders: [String: String]?
    var lastBody: Data?

    var responseData: Data?
    var statusCode: Int = 200
    var shouldThrowError = false
    var errorToThrow: Error?

    func request(
        url: URL,
        method: String,
        headers: [String: String]?,
        body: Data?
    ) async throws -> (Data, HTTPURLResponse) {
        requestCalled = true
        lastURL = url
        lastMethod = method
        lastHeaders = headers
        lastBody = body

        if shouldThrowError {
            throw errorToThrow ?? URLError(.unknown)
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        return (responseData ?? Data(), response)
    }
}

// MARK: - Mock Developer Token Generator

class MockDeveloperTokenGenerator: DeveloperTokenGenerator {
    var generateTokenCalled = false
    var generateTokenCallCount = 0
    var tokenToReturn = "mock.developer.token"
    var tokenExpiresIn: TimeInterval = 3600

    func generateToken() throws -> (token: String, expiresAt: Date) {
        generateTokenCalled = true
        generateTokenCallCount += 1
        return (tokenToReturn, Date().addingTimeInterval(tokenExpiresIn))
    }
}
