import XCTest
import MusicKit
@testable import PlaylistCreator

@available(macOS 12.0, *)
final class AppleMusicSearchServiceTests: XCTestCase {

    var service: AppleMusicSearchService<MockMusicKitClient>!
    var mockMusicKitClient: MockMusicKitClient!

    override func setUp() {
        super.setUp()
        mockMusicKitClient = MockMusicKitClient()
        service = AppleMusicSearchService(musicKitClient: mockMusicKitClient)
    }

    override func tearDown() {
        service = nil
        mockMusicKitClient = nil
        super.tearDown()
    }

    // MARK: - Basic Search Tests

    func testSearchReturnsResultsForValidSong() async throws {
        // Arrange
        let song = Song(title: "Bohemian Rhapsody", artist: "Queen", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "12345", title: "Bohemian Rhapsody", artist: "Queen")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.song.title, "Bohemian Rhapsody")
        XCTAssertEqual(results.first?.song.artist, "Queen")
        XCTAssertEqual(results.first?.appleMusicID, "12345")
        XCTAssertGreaterThan(results.first?.matchConfidence ?? 0, 0.8)
    }

    func testSearchReturnsMultipleResults() async throws {
        // Arrange
        let song = Song(title: "Imagine", artist: "John Lennon", appleID: nil, confidence: 0.85)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Imagine", artist: "John Lennon"),
            createMockSong(id: "2", title: "Imagine - Live", artist: "John Lennon"),
            createMockSong(id: "3", title: "Imagine", artist: "John Lennon & The Plastic Ono Band")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.song.title.contains("Imagine") })
    }

    func testSearchOrdersResultsByConfidence() async throws {
        // Arrange
        let song = Song(title: "Yesterday", artist: "The Beatles", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Yesterday - Remastered 2009", artist: "The Beatles"),
            createMockSong(id: "2", title: "Yesterday", artist: "The Beatles"),
            createMockSong(id: "3", title: "Yesterday - Live", artist: "The Beatles")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThanOrEqual(results.count, 2)
        // Exact match should have highest confidence
        XCTAssertEqual(results.first?.appleMusicID, "2")
        XCTAssertGreaterThan(results.first?.matchConfidence ?? 0, results.last?.matchConfidence ?? 1)
    }

    func testSearchHandlesNoResults() async throws {
        // Arrange
        let song = Song(title: "NonexistentSong12345", artist: "UnknownArtist", appleID: nil, confidence: 0.5)
        mockMusicKitClient.mockSearchResults = []

        // Act & Assert
        do {
            _ = try await service.search(for: song)
            XCTFail("Expected noResultsFound error")
        } catch MusicSearchError.noResultsFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Authorization Tests

    func testSearchRequiresAuthorization() async throws {
        // Arrange
        mockMusicKitClient.isAuthorized = false
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: nil, confidence: 0.8)

        // Act & Assert
        do {
            _ = try await service.search(for: song)
            XCTFail("Expected authenticationRequired error")
        } catch MusicSearchError.authenticationRequired {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServiceHandlesAuthorizationFlow() async throws {
        // Arrange
        mockMusicKitClient.isAuthorized = false
        mockMusicKitClient.shouldGrantAuthorization = true

        // Act
        try await service.requestAuthorization()

        // Assert
        XCTAssertTrue(mockMusicKitClient.authorizationRequested)
    }

    func testServiceHandlesDeniedAuthorization() async throws {
        // Arrange
        mockMusicKitClient.isAuthorized = false
        mockMusicKitClient.shouldGrantAuthorization = false

        // Act & Assert
        do {
            try await service.requestAuthorization()
            XCTFail("Expected authenticationRequired error")
        } catch MusicSearchError.authenticationRequired {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Query Optimization Tests

    func testSearchUsesMultipleQueryStrategies() async throws {
        // Arrange
        let song = Song(title: "Let It Be", artist: "Beatles", appleID: nil, confidence: 0.85)
        mockMusicKitClient.trackQueryStrategies = true
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Let It Be", artist: "The Beatles")
        ]

        // Act
        _ = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThan(mockMusicKitClient.queriesAttempted.count, 0)
        // Should try "Beatles" and "The Beatles"
        XCTAssertTrue(mockMusicKitClient.queriesAttempted.contains { $0.contains("Beatles") })
    }

    func testSearchHandlesSpecialCharacters() async throws {
        // Arrange
        let song = Song(title: "R.E.M.'s \"Losing My Religion\"", artist: "R.E.M.", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Losing My Religion", artist: "R.E.M.")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThanOrEqual(results.count, 1)
        // Verify special characters were handled properly
        XCTAssertTrue(mockMusicKitClient.lastQuery?.contains("Losing My Religion") ?? false)
    }

    func testSearchNormalizesArtistNames() async throws {
        // Arrange
        let song = Song(title: "Smells Like Teen Spirit", artist: "nirvana", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Smells Like Teen Spirit", artist: "Nirvana")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThanOrEqual(results.count, 1)
        XCTAssertEqual(results.first?.song.artist, "Nirvana")
    }

    // MARK: - Result Filtering Tests

    func testSearchFiltersLowQualityResults() async throws {
        // Arrange
        let song = Song(title: "Hotel California", artist: "Eagles", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Hotel California", artist: "Eagles"),
            createMockSong(id: "2", title: "Hotel California Karaoke Version", artist: "Karaoke Stars"),
            createMockSong(id: "3", title: "Hotel California - Tribute", artist: "Various Artists")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        // Should filter out karaoke and tribute versions in favor of original
        XCTAssertTrue(results.first?.appleMusicID == "1")
        XCTAssertGreaterThan(results.first?.matchConfidence ?? 0, 0.8)
    }

    func testSearchPrioritizesExactMatches() async throws {
        // Arrange
        let song = Song(title: "Wonderwall", artist: "Oasis", appleID: nil, confidence: 0.95)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Wonderwall - Remastered", artist: "Oasis"),
            createMockSong(id: "2", title: "Wonderwall", artist: "Oasis"),
            createMockSong(id: "3", title: "Wonderwall - Live", artist: "Oasis")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertEqual(results.first?.appleMusicID, "2")
        XCTAssertGreaterThanOrEqual(results.first?.matchConfidence ?? 0, 0.9)
    }

    // MARK: - Batch Search Tests

    func testBatchSearchProcessesMultipleSongs() async throws {
        // Arrange
        let songs = [
            Song(title: "Song 1", artist: "Artist 1", appleID: nil, confidence: 0.8),
            Song(title: "Song 2", artist: "Artist 2", appleID: nil, confidence: 0.85),
            Song(title: "Song 3", artist: "Artist 3", appleID: nil, confidence: 0.9)
        ]
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Song 1", artist: "Artist 1")
        ]

        // Act
        let results = try await service.searchBatch(songs)

        // Assert
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.keys.contains(songs[0]))
        XCTAssertTrue(results.keys.contains(songs[1]))
        XCTAssertTrue(results.keys.contains(songs[2]))
    }

    func testBatchSearchHandlesPartialFailures() async throws {
        // Arrange
        let songs = [
            Song(title: "Valid Song", artist: "Valid Artist", appleID: nil, confidence: 0.9),
            Song(title: "Invalid Song", artist: "Invalid Artist", appleID: nil, confidence: 0.3)
        ]
        mockMusicKitClient.shouldFailForQuery = "Invalid Song"
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Valid Song", artist: "Valid Artist")
        ]

        // Act
        let results = try await service.searchBatch(songs)

        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertGreaterThan(results[songs[0]]?.count ?? 0, 0)
        XCTAssertEqual(results[songs[1]]?.count ?? -1, 0) // Failed search returns empty array
    }

    func testBatchSearchRespectsRateLimits() async throws {
        // Arrange
        let songs = Array(repeating: Song(title: "Test", artist: "Test", appleID: nil, confidence: 0.8), count: 10)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Test", artist: "Test")
        ]
        let startTime = Date()

        // Act
        _ = try await service.searchBatch(songs)
        let duration = Date().timeIntervalSince(startTime)

        // Assert
        // With rate limiting, should take some time (at least 100ms for 10 requests)
        XCTAssertGreaterThan(duration, 0.05)
    }

    // MARK: - Top Match Tests

    func testGetTopMatchReturnsHighestConfidence() async throws {
        // Arrange
        let song = Song(title: "Stairway to Heaven", artist: "Led Zeppelin", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Stairway to Heaven - Remastered", artist: "Led Zeppelin"),
            createMockSong(id: "2", title: "Stairway to Heaven", artist: "Led Zeppelin")
        ]

        // Act
        let topMatch = try await service.getTopMatch(for: song)

        // Assert
        XCTAssertNotNil(topMatch)
        XCTAssertEqual(topMatch?.appleMusicID, "2") // Exact match should be top
    }

    func testGetTopMatchReturnsNilForLowConfidence() async throws {
        // Arrange
        let song = Song(title: "Ambiguous Song", artist: "Unknown Artist", appleID: nil, confidence: 0.3)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Different Song", artist: "Different Artist")
        ]

        // Act
        let topMatch = try await service.getTopMatch(for: song)

        // Assert
        XCTAssertNil(topMatch) // Low confidence should return nil
    }

    // MARK: - Error Handling Tests

    func testSearchHandlesNetworkErrors() async throws {
        // Arrange
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: nil, confidence: 0.8)
        mockMusicKitClient.shouldThrowNetworkError = true

        // Act & Assert
        do {
            _ = try await service.search(for: song)
            XCTFail("Expected searchFailed error")
        } catch MusicSearchError.searchFailed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSearchHandlesRateLimitErrors() async throws {
        // Arrange
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: nil, confidence: 0.8)
        mockMusicKitClient.shouldThrowRateLimitError = true

        // Act & Assert
        do {
            _ = try await service.search(for: song)
            XCTFail("Expected rateLimitExceeded error")
        } catch MusicSearchError.rateLimitExceeded {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSearchHandlesInvalidResponses() async throws {
        // Arrange
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: nil, confidence: 0.8)
        mockMusicKitClient.mockSearchResults = [] // Empty results

        // Act & Assert
        do {
            _ = try await service.search(for: song)
            XCTFail("Expected noResultsFound error")
        } catch MusicSearchError.noResultsFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Edge Cases

    func testSearchHandlesFeaturedArtists() async throws {
        // Arrange
        let song = Song(title: "Old Town Road", artist: "Lil Nas X ft. Billy Ray Cyrus", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Old Town Road (feat. Billy Ray Cyrus)", artist: "Lil Nas X")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThanOrEqual(results.count, 1)
        XCTAssertGreaterThan(results.first?.matchConfidence ?? 0, 0.7)
    }

    func testSearchHandlesRemixesAndLiveVersions() async throws {
        // Arrange
        let song = Song(title: "Closer", artist: "The Chainsmokers", appleID: nil, confidence: 0.85)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Closer", artist: "The Chainsmokers"),
            createMockSong(id: "2", title: "Closer - Remix", artist: "The Chainsmokers"),
            createMockSong(id: "3", title: "Closer - Live", artist: "The Chainsmokers")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThanOrEqual(results.count, 3)
        // Original should be first
        XCTAssertEqual(results.first?.appleMusicID, "1")
    }

    func testSearchHandlesUnicodeCharacters() async throws {
        // Arrange
        let song = Song(title: "Señorita", artist: "Camila Cabello", appleID: nil, confidence: 0.9)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Señorita", artist: "Camila Cabello")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThanOrEqual(results.count, 1)
        XCTAssertEqual(results.first?.song.title, "Señorita")
    }

    func testSearchHandlesVeryLongTitles() async throws {
        // Arrange
        let longTitle = "This Is A Very Long Song Title That Might Cause Issues With Some Search APIs"
        let song = Song(title: longTitle, artist: "Test Artist", appleID: nil, confidence: 0.8)
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: longTitle, artist: "Test Artist")
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertGreaterThanOrEqual(results.count, 1)
    }

    // MARK: - Preview URL Tests

    func testSearchIncludesPreviewURLs() async throws {
        // Arrange
        let song = Song(title: "Shape of You", artist: "Ed Sheeran", appleID: nil, confidence: 0.9)
        let mockURL = URL(string: "https://audio-ssl.itunes.apple.com/preview.m4a")!
        mockMusicKitClient.mockSearchResults = [
            createMockSong(id: "1", title: "Shape of You", artist: "Ed Sheeran", previewURL: mockURL)
        ]

        // Act
        let results = try await service.search(for: song)

        // Assert
        XCTAssertNotNil(results.first?.previewURL)
        XCTAssertEqual(results.first?.previewURL, mockURL)
    }

    // MARK: - Helper Methods

    private func createMockSong(id: String, title: String, artist: String, previewURL: URL? = nil) -> MockMusicKitSong {
        return MockMusicKitSong(id: id, title: title, artistName: artist, previewURL: previewURL)
    }
}

// MARK: - Mock Objects

struct MockMusicKitSong: MusicKitSongProtocol {
    let id: String
    let title: String
    let artistName: String
    let previewURL: URL?
}

class MockMusicKitClient: MusicKitClientProtocol {
    typealias SongType = MockMusicKitSong

    var isAuthorized = true
    var shouldGrantAuthorization = true
    var authorizationRequested = false
    var mockSearchResults: [MockMusicKitSong] = []
    var shouldThrowNetworkError = false
    var shouldThrowRateLimitError = false
    var shouldFailForQuery: String?
    var trackQueryStrategies = false
    var queriesAttempted: [String] = []
    var lastQuery: String?

    func requestAuthorization() async throws {
        authorizationRequested = true
        if !shouldGrantAuthorization {
            throw MusicSearchError.authenticationRequired
        }
        isAuthorized = true
    }

    func search(term: String) async throws -> [MockMusicKitSong] {
        lastQuery = term

        if trackQueryStrategies {
            queriesAttempted.append(term)
        }

        if !isAuthorized {
            throw MusicSearchError.authenticationRequired
        }

        if shouldThrowNetworkError {
            throw MusicSearchError.searchFailed("Network error")
        }

        if shouldThrowRateLimitError {
            throw MusicSearchError.rateLimitExceeded
        }

        if let failQuery = shouldFailForQuery, term.contains(failQuery) {
            throw MusicSearchError.searchFailed("Query failed")
        }

        return mockSearchResults
    }
}
