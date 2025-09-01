import XCTest
@testable import PlaylistCreator

final class MusicExtractorTests: XCTestCase {
    var mockExtractor: MockMusicExtractor!
    
    override func setUp() {
        super.setUp()
        mockExtractor = MockMusicExtractor()
    }
    
    override func tearDown() {
        mockExtractor = nil
        super.tearDown()
    }
    
    // MARK: - ExtractedSong Tests
    
    func testExtractedSongInitialization() throws {
        let song = Song(title: "Test Song", artist: "Test Artist", confidence: 0.8)
        let extracted = ExtractedSong(song: song, context: "They mentioned this song")
        
        XCTAssertEqual(extracted.song, song)
        XCTAssertEqual(extracted.context, "They mentioned this song")
        XCTAssertNil(extracted.timestamp)
        XCTAssertEqual(extracted.extractionConfidence, 1.0)
    }
    
    func testExtractedSongWithAllParameters() throws {
        let song = Song(title: "Full Song", artist: "Full Artist", confidence: 0.9)
        let extracted = ExtractedSong(song: song, context: "Full context", timestamp: 120.5, extractionConfidence: 0.85)
        
        XCTAssertEqual(extracted.song, song)
        XCTAssertEqual(extracted.context, "Full context")
        XCTAssertEqual(extracted.timestamp, 120.5)
        XCTAssertEqual(extracted.extractionConfidence, 0.85)
    }
    
    func testExtractedSongEquality() throws {
        let song = Song(title: "Test", artist: "Artist", confidence: 0.7)
        let extracted1 = ExtractedSong(song: song, context: "Context", timestamp: 60.0, extractionConfidence: 0.9)
        let extracted2 = ExtractedSong(song: song, context: "Context", timestamp: 60.0, extractionConfidence: 0.9)
        
        XCTAssertEqual(extracted1, extracted2)
    }
    
    func testExtractedSongInequality() throws {
        let song1 = Song(title: "Song 1", artist: "Artist", confidence: 0.7)
        let song2 = Song(title: "Song 2", artist: "Artist", confidence: 0.7)
        let extracted1 = ExtractedSong(song: song1, context: "Context")
        let extracted2 = ExtractedSong(song: song2, context: "Context")
        
        XCTAssertNotEqual(extracted1, extracted2)
    }
    
    // MARK: - Mock MusicExtractor Tests
    
    func testMockExtractSongsSuccess() async throws {
        let transcript = Transcript(text: "Test transcript mentioning songs")
        let customSongs = [
            Song(title: "Custom Song 1", artist: "Custom Artist 1", confidence: 0.95),
            Song(title: "Custom Song 2", artist: "Custom Artist 2", confidence: 0.88)
        ]
        mockExtractor.extractSongsResult = customSongs
        
        let result = try await mockExtractor.extractSongs(from: transcript)
        
        XCTAssertEqual(result, customSongs)
    }
    
    func testMockExtractSongsFailure() async throws {
        let transcript = Transcript(text: "Empty transcript")
        mockExtractor.shouldThrowError = true
        
        do {
            _ = try await mockExtractor.extractSongs(from: transcript)
            XCTFail("Expected error to be thrown")
        } catch let error as MusicExtractionError {
            XCTAssertEqual(error, .noSongsFound)
        }
    }
    
    func testMockExtractSongsWithContextSuccess() async throws {
        let transcript = Transcript(text: "Transcript with songs mentioned")
        let customExtracted = [
            ExtractedSong(
                song: Song(title: "First Song", artist: "First Artist", confidence: 0.9),
                context: "First mention context",
                timestamp: 30.0,
                extractionConfidence: 0.95
            ),
            ExtractedSong(
                song: Song(title: "Second Song", artist: "Second Artist", confidence: 0.85),
                context: "Second mention context",
                timestamp: 150.0,
                extractionConfidence: 0.88
            )
        ]
        mockExtractor.extractSongsWithContextResult = customExtracted
        
        let result = try await mockExtractor.extractSongsWithContext(from: transcript)
        
        XCTAssertEqual(result, customExtracted)
    }
    
    func testMockExtractSongsWithContextFailure() async throws {
        let transcript = Transcript(text: "Malformed transcript")
        mockExtractor.shouldThrowError = true
        
        do {
            _ = try await mockExtractor.extractSongsWithContext(from: transcript)
            XCTFail("Expected error to be thrown")
        } catch let error as MusicExtractionError {
            XCTAssertEqual(error, .parsingFailed("Mock error"))
        }
    }
    
    func testMockDefaultBehavior() async throws {
        let transcript = Transcript(text: "Default test transcript")
        
        // Test default behavior when no custom results are set
        let songsResult = try await mockExtractor.extractSongs(from: transcript)
        XCTAssertEqual(songsResult.count, 3)
        XCTAssertEqual(songsResult[0].title, "Bohemian Rhapsody")
        XCTAssertEqual(songsResult[0].artist, "Queen")
        XCTAssertEqual(songsResult[1].title, "Stairway to Heaven")
        XCTAssertEqual(songsResult[1].artist, "Led Zeppelin")
        XCTAssertEqual(songsResult[2].title, "Hotel California")
        XCTAssertEqual(songsResult[2].artist, "Eagles")
        
        let contextResult = try await mockExtractor.extractSongsWithContext(from: transcript)
        XCTAssertEqual(contextResult.count, 2)
        
        let firstExtracted = contextResult[0]
        XCTAssertEqual(firstExtracted.song.title, "Bohemian Rhapsody")
        XCTAssertEqual(firstExtracted.context, "They mentioned Bohemian Rhapsody by Queen")
        XCTAssertEqual(firstExtracted.timestamp, 45.0)
        XCTAssertEqual(firstExtracted.extractionConfidence, 0.95)
        
        let secondExtracted = contextResult[1]
        XCTAssertEqual(secondExtracted.song.title, "Stairway to Heaven")
        XCTAssertEqual(secondExtracted.context, "Playing Stairway to Heaven from Led Zeppelin")
        XCTAssertEqual(secondExtracted.timestamp, 120.0)
        XCTAssertEqual(secondExtracted.extractionConfidence, 0.9)
    }
    
    func testExtractSongsImplementation() async throws {
        let transcript = Transcript(text: "Test transcript")
        let expectedExtracted = [
            ExtractedSong(
                song: Song(title: "Test Song", artist: "Test Artist", confidence: 0.8),
                context: "Test context",
                timestamp: 60.0,
                extractionConfidence: 0.9
            )
        ]
        mockExtractor.extractSongsWithContextResult = expectedExtracted
        
        let songs = try await mockExtractor.extractSongs(from: transcript)
        let expectedSongs = expectedExtracted.map { $0.song }
        
        XCTAssertEqual(songs, expectedSongs)
    }
    
    // MARK: - DefaultMusicExtractor Tests
    
    func testDefaultMusicExtractorInitialization() throws {
        let extractor1 = DefaultMusicExtractor()
        XCTAssertNotNil(extractor1)
        
        let extractor2 = DefaultMusicExtractor(apiKey: "test-key", model: "gpt-3.5-turbo")
        XCTAssertNotNil(extractor2)
    }
    
    func testDefaultMusicExtractorNotImplemented() async throws {
        let extractor = DefaultMusicExtractor()
        let transcript = Transcript(text: "Test transcript")
        
        do {
            _ = try await extractor.extractSongsWithContext(from: transcript)
            XCTFail("Expected notImplemented error")
        } catch let error as MusicExtractionError {
            XCTAssertEqual(error, .notImplemented)
        }
        
        do {
            _ = try await extractor.extractSongs(from: transcript)
            XCTFail("Expected notImplemented error")
        } catch let error as MusicExtractionError {
            XCTAssertEqual(error, .notImplemented)
        }
    }
}
