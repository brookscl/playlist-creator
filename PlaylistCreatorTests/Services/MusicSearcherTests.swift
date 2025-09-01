import XCTest
@testable import PlaylistCreator

final class MusicSearcherTests: XCTestCase {
    var mockSearcher: MockMusicSearcher!
    
    override func setUp() {
        super.setUp()
        mockSearcher = MockMusicSearcher()
    }
    
    override func tearDown() {
        mockSearcher = nil
        super.tearDown()
    }
    
    // MARK: - SearchResult Tests
    
    func testSearchResultInitialization() throws {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "12345")
        let result = SearchResult(song: song, matchConfidence: 0.95, appleMusicID: "12345")
        
        XCTAssertEqual(result.song, song)
        XCTAssertEqual(result.matchConfidence, 0.95)
        XCTAssertEqual(result.appleMusicID, "12345")
        XCTAssertNil(result.previewURL)
    }
    
    func testSearchResultWithPreviewURL() throws {
        let song = Song(title: "Preview Song", artist: "Preview Artist", appleID: "67890")
        let previewURL = URL(string: "https://example.com/preview.m4a")!
        let result = SearchResult(song: song, matchConfidence: 0.88, appleMusicID: "67890", previewURL: previewURL)
        
        XCTAssertEqual(result.song, song)
        XCTAssertEqual(result.matchConfidence, 0.88)
        XCTAssertEqual(result.appleMusicID, "67890")
        XCTAssertEqual(result.previewURL, previewURL)
    }
    
    func testSearchResultEquality() throws {
        let song = Song(title: "Test", artist: "Artist", appleID: "123")
        let previewURL = URL(string: "https://example.com/preview.m4a")!
        
        let result1 = SearchResult(song: song, matchConfidence: 0.9, appleMusicID: "123", previewURL: previewURL)
        let result2 = SearchResult(song: song, matchConfidence: 0.9, appleMusicID: "123", previewURL: previewURL)
        
        XCTAssertEqual(result1, result2)
    }
    
    func testSearchResultInequality() throws {
        let song1 = Song(title: "Song 1", artist: "Artist", appleID: "123")
        let song2 = Song(title: "Song 2", artist: "Artist", appleID: "456")
        
        let result1 = SearchResult(song: song1, matchConfidence: 0.9, appleMusicID: "123")
        let result2 = SearchResult(song: song2, matchConfidence: 0.9, appleMusicID: "456")
        
        XCTAssertNotEqual(result1, result2)
    }
    
    // MARK: - Mock MusicSearcher Tests
    
    func testMockSearchSuccess() async throws {
        let song = Song(title: "Search Song", artist: "Search Artist")
        let customResults = [
            SearchResult(song: song, matchConfidence: 0.98, appleMusicID: "custom123"),
            SearchResult(song: song, matchConfidence: 0.85, appleMusicID: "custom456")
        ]
        mockSearcher.searchResult = customResults
        
        let result = try await mockSearcher.search(for: song)
        
        XCTAssertEqual(result, customResults)
    }
    
    func testMockSearchFailure() async throws {
        let song = Song(title: "Failed Song", artist: "Failed Artist")
        mockSearcher.shouldThrowError = true
        
        do {
            _ = try await mockSearcher.search(for: song)
            XCTFail("Expected error to be thrown")
        } catch let error as MusicSearchError {
            XCTAssertEqual(error, .searchFailed("Mock error"))
        }
    }
    
    func testMockSearchBatchSuccess() async throws {
        let song1 = Song(title: "Batch Song 1", artist: "Artist 1")
        let song2 = Song(title: "Batch Song 2", artist: "Artist 2")
        let songs = [song1, song2]
        
        let customBatchResult = [
            song1: [SearchResult(song: song1, matchConfidence: 0.9, appleMusicID: "batch123")],
            song2: [SearchResult(song: song2, matchConfidence: 0.85, appleMusicID: "batch456")]
        ]
        mockSearcher.searchBatchResult = customBatchResult
        
        let result = try await mockSearcher.searchBatch(songs)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[song1], customBatchResult[song1])
        XCTAssertEqual(result[song2], customBatchResult[song2])
    }
    
    func testMockSearchBatchFailure() async throws {
        let songs = [Song(title: "Test", artist: "Artist")]
        mockSearcher.shouldThrowError = true
        
        do {
            _ = try await mockSearcher.searchBatch(songs)
            XCTFail("Expected error to be thrown")
        } catch let error as MusicSearchError {
            XCTAssertEqual(error, .rateLimitExceeded)
        }
    }
    
    func testMockGetTopMatchSuccess() async throws {
        let song = Song(title: "Top Song", artist: "Top Artist")
        let customTopMatch = SearchResult(song: song, matchConfidence: 0.99, appleMusicID: "top999")
        mockSearcher.getTopMatchResult = customTopMatch
        
        let result = try await mockSearcher.getTopMatch(for: song)
        
        XCTAssertEqual(result, customTopMatch)
    }
    
    func testMockGetTopMatchFailure() async throws {
        let song = Song(title: "No Match Song", artist: "No Match Artist")
        mockSearcher.shouldThrowError = true
        
        do {
            _ = try await mockSearcher.getTopMatch(for: song)
            XCTFail("Expected error to be thrown")
        } catch let error as MusicSearchError {
            XCTAssertEqual(error, .noResultsFound("No Match Song by No Match Artist"))
        }
    }
    
    func testMockDefaultBehavior() async throws {
        let song = Song(title: "Default Song", artist: "Default Artist")
        
        // Test default search behavior
        let searchResults = try await mockSearcher.search(for: song)
        XCTAssertEqual(searchResults.count, 2)
        
        let firstResult = searchResults[0]
        XCTAssertEqual(firstResult.song.title, "Default Song")
        XCTAssertEqual(firstResult.song.artist, "Default Artist")
        XCTAssertEqual(firstResult.matchConfidence, 0.95)
        XCTAssertEqual(firstResult.appleMusicID, "12345")
        XCTAssertEqual(firstResult.previewURL?.absoluteString, "https://example.com/preview1.m4a")
        
        let secondResult = searchResults[1]
        XCTAssertEqual(secondResult.song.title, "Similar Default Song")
        XCTAssertEqual(secondResult.matchConfidence, 0.75)
        XCTAssertEqual(secondResult.appleMusicID, "67890")
        
        // Test default top match behavior
        let topMatch = try await mockSearcher.getTopMatch(for: song)
        XCTAssertNotNil(topMatch)
        XCTAssertEqual(topMatch!.song.title, "Default Song")
        XCTAssertEqual(topMatch!.matchConfidence, 0.9)
        XCTAssertEqual(topMatch!.appleMusicID, "top123")
        XCTAssertEqual(topMatch!.previewURL?.absoluteString, "https://example.com/top_preview.m4a")
        
        // Test default batch behavior
        let songs = [song]
        let batchResults = try await mockSearcher.searchBatch(songs)
        XCTAssertEqual(batchResults.count, 1)
        XCTAssertEqual(batchResults[song], searchResults)
    }
    
    func testSearchBatchWithMultipleSongs() async throws {
        let song1 = Song(title: "Multi Song 1", artist: "Multi Artist 1")
        let song2 = Song(title: "Multi Song 2", artist: "Multi Artist 2")
        let song3 = Song(title: "Multi Song 3", artist: "Multi Artist 3")
        let songs = [song1, song2, song3]
        
        let batchResults = try await mockSearcher.searchBatch(songs)
        
        XCTAssertEqual(batchResults.count, 3)
        XCTAssertNotNil(batchResults[song1])
        XCTAssertNotNil(batchResults[song2])
        XCTAssertNotNil(batchResults[song3])
        
        // Each song should have search results
        XCTAssertEqual(batchResults[song1]!.count, 2)
        XCTAssertEqual(batchResults[song2]!.count, 2)
        XCTAssertEqual(batchResults[song3]!.count, 2)
    }
    
    // MARK: - DefaultMusicSearcher Tests
    
    func testDefaultMusicSearcherInitialization() throws {
        let searcher1 = DefaultMusicSearcher()
        XCTAssertNotNil(searcher1)
        
        let searcher2 = DefaultMusicSearcher(minimumConfidence: 0.8)
        XCTAssertNotNil(searcher2)
    }
    
    func testDefaultMusicSearcherNotImplemented() async throws {
        let searcher = DefaultMusicSearcher()
        let song = Song(title: "Test", artist: "Artist")
        
        do {
            _ = try await searcher.search(for: song)
            XCTFail("Expected notImplemented error")
        } catch let error as MusicSearchError {
            XCTAssertEqual(error, .notImplemented)
        }
    }
    
    func testSearchBatchHandlesErrors() async throws {
        let song1 = Song(title: "Success Song", artist: "Success Artist")
        let song2 = Song(title: "Fail Song", artist: "Fail Artist")
        let songs = [song1, song2]
        
        // Configure mock to fail only for specific song
        let mockSearcher = MockMusicSearcher()
        mockSearcher.searchResult = [SearchResult(song: song1, matchConfidence: 0.9, appleMusicID: "123")]
        
        // Override search method to throw error for specific song
        class TestMockSearcher: MockMusicSearcher {
            override func search(for song: Song) async throws -> [SearchResult] {
                if song.title == "Fail Song" {
                    throw MusicSearchError.searchFailed("Test error")
                }
                return try await super.search(for: song)
            }
        }
        
        let testSearcher = TestMockSearcher()
        testSearcher.searchResult = [SearchResult(song: song1, matchConfidence: 0.9, appleMusicID: "123")]
        
        let batchResults = try await testSearcher.searchBatch(songs)
        
        // Should have results for successful song and empty array for failed song
        XCTAssertEqual(batchResults.count, 2)
        XCTAssertEqual(batchResults[song1]!.count, 1)
        XCTAssertEqual(batchResults[song2]!.count, 0)
    }
}
