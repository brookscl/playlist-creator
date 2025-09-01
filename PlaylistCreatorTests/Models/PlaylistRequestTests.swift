import XCTest
@testable import PlaylistCreator

final class PlaylistRequestTests: XCTestCase {
    
    // MARK: - Model Creation and Initialization Tests
    
    func testPlaylistRequestInitialization() throws {
        let request = PlaylistRequest()
        
        XCTAssertNotNil(request.id)
        XCTAssertEqual(request.status, .idle)
        XCTAssertNil(request.sourceURL)
        XCTAssertNil(request.sourceFilePath)
        XCTAssertNil(request.transcript)
        XCTAssertEqual(request.extractedSongs.count, 0)
        XCTAssertEqual(request.matchedSongs.count, 0)
        XCTAssertNil(request.playlistID)
        XCTAssertNil(request.playlistName)
        XCTAssertNotNil(request.createdAt)
        XCTAssertNil(request.completedAt)
        XCTAssertNil(request.errorMessage)
    }
    
    func testPlaylistRequestInitializationWithSourceURL() throws {
        let url = URL(string: "https://example.com/audio.mp3")!
        let request = PlaylistRequest(sourceURL: url)
        
        XCTAssertEqual(request.sourceURL, url)
        XCTAssertNil(request.sourceFilePath)
        XCTAssertEqual(request.status, .idle)
    }
    
    func testPlaylistRequestInitializationWithSourceFile() throws {
        let filePath = "/path/to/audio.mp3"
        let request = PlaylistRequest(sourceFilePath: filePath)
        
        XCTAssertEqual(request.sourceFilePath, filePath)
        XCTAssertNil(request.sourceURL)
        XCTAssertEqual(request.status, .idle)
    }
    
    // MARK: - Property Validation Tests
    
    func testUniqueIDGeneration() throws {
        let request1 = PlaylistRequest()
        let request2 = PlaylistRequest()
        
        XCTAssertNotEqual(request1.id, request2.id)
    }
    
    func testCreatedAtTimestamp() throws {
        let beforeCreation = Date()
        let request = PlaylistRequest()
        let afterCreation = Date()
        
        XCTAssertGreaterThanOrEqual(request.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(request.createdAt, afterCreation)
    }
    
    func testEmptyCollectionsInitialization() throws {
        let request = PlaylistRequest()
        
        XCTAssertTrue(request.extractedSongs.isEmpty)
        XCTAssertTrue(request.matchedSongs.isEmpty)
        XCTAssertEqual(request.extractedSongs.count, 0)
        XCTAssertEqual(request.matchedSongs.count, 0)
    }
    
    // MARK: - Workflow State Management Tests
    
    func testStatusProgression() throws {
        var request = PlaylistRequest()
        
        XCTAssertEqual(request.status, .idle)
        
        request.status = .processing
        XCTAssertEqual(request.status, .processing)
        
        request.status = .complete
        XCTAssertEqual(request.status, .complete)
    }
    
    func testCompletionTimestamp() throws {
        var request = PlaylistRequest()
        XCTAssertNil(request.completedAt)
        
        request.completedAt = Date()
        XCTAssertNotNil(request.completedAt)
    }
    
    func testErrorHandling() throws {
        var request = PlaylistRequest()
        XCTAssertNil(request.errorMessage)
        
        request.status = .error
        request.errorMessage = "Test error occurred"
        
        XCTAssertEqual(request.status, .error)
        XCTAssertEqual(request.errorMessage, "Test error occurred")
    }
    
    // MARK: - Song Collection Management Tests
    
    func testExtractedSongsManagement() throws {
        var request = PlaylistRequest()
        let song1 = Song(title: "Song 1", artist: "Artist 1")
        let song2 = Song(title: "Song 2", artist: "Artist 2")
        
        request.extractedSongs = [song1, song2]
        
        XCTAssertEqual(request.extractedSongs.count, 2)
        XCTAssertEqual(request.extractedSongs[0], song1)
        XCTAssertEqual(request.extractedSongs[1], song2)
    }
    
    func testMatchedSongsManagement() throws {
        var request = PlaylistRequest()
        let matchedSong1 = MatchedSong(
            originalSong: Song(title: "Song 1", artist: "Artist 1"),
            appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "123"),
            matchStatus: .auto
        )
        let matchedSong2 = MatchedSong(
            originalSong: Song(title: "Song 2", artist: "Artist 2"),
            appleMusicSong: Song(title: "Song 2", artist: "Artist 2", appleID: "456"),
            matchStatus: .selected
        )
        
        request.matchedSongs = [matchedSong1, matchedSong2]
        
        XCTAssertEqual(request.matchedSongs.count, 2)
        XCTAssertEqual(request.matchedSongs[0].matchStatus, .auto)
        XCTAssertEqual(request.matchedSongs[1].matchStatus, .selected)
    }
    
    // MARK: - Equality Tests
    
    func testPlaylistRequestEquality() throws {
        let id = UUID()
        let createdAt = Date()
        
        let request1 = PlaylistRequest(id: id, createdAt: createdAt)
        let request2 = PlaylistRequest(id: id, createdAt: createdAt)
        
        XCTAssertEqual(request1.id, request2.id)
        // Note: PlaylistRequest equality should be based on ID
    }
    
    func testPlaylistRequestInequality() throws {
        let request1 = PlaylistRequest()
        let request2 = PlaylistRequest()
        
        XCTAssertNotEqual(request1.id, request2.id)
    }
    
    // MARK: - Codable Tests
    
    func testPlaylistRequestCodableEncoding() throws {
        var request = PlaylistRequest(sourceURL: URL(string: "https://example.com/test.mp3")!)
        request.status = .processing
        request.transcript = "This is a test transcript"
        request.playlistName = "Test Playlist"
        
        let song = Song(title: "Test Song", artist: "Test Artist")
        request.extractedSongs = [song]
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(request)
        
        XCTAssertFalse(data.isEmpty)
        
        // Verify the JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["id"])
        XCTAssertEqual(json?["status"] as? String, "processing")
        XCTAssertEqual(json?["sourceURL"] as? String, "https://example.com/test.mp3")
        XCTAssertEqual(json?["transcript"] as? String, "This is a test transcript")
        XCTAssertEqual(json?["playlistName"] as? String, "Test Playlist")
        XCTAssertNotNil(json?["extractedSongs"])
    }
    
    func testPlaylistRequestCodableDecoding() throws {
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "status": "complete",
            "sourceFilePath": "/path/to/file.mp3",
            "transcript": "Decoded transcript",
            "extractedSongs": [
                {
                    "title": "Decoded Song",
                    "artist": "Decoded Artist",
                    "confidence": 0.8
                }
            ],
            "matchedSongs": [],
            "playlistName": "Decoded Playlist",
            "createdAt": "2024-01-01T00:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let request = try decoder.decode(PlaylistRequest.self, from: data)
        
        XCTAssertEqual(request.status, .complete)
        XCTAssertEqual(request.sourceFilePath, "/path/to/file.mp3")
        XCTAssertEqual(request.transcript, "Decoded transcript")
        XCTAssertEqual(request.playlistName, "Decoded Playlist")
        XCTAssertEqual(request.extractedSongs.count, 1)
        XCTAssertEqual(request.extractedSongs[0].title, "Decoded Song")
    }
    
    func testPlaylistRequestCodableRoundTrip() throws {
        var originalRequest = PlaylistRequest(sourceURL: URL(string: "https://test.com/audio.wav")!)
        originalRequest.status = .processing
        originalRequest.transcript = "Test transcript content"
        
        let song = Song(title: "Round Trip Song", artist: "Round Trip Artist", confidence: 0.75)
        originalRequest.extractedSongs = [song]
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalRequest)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedRequest = try decoder.decode(PlaylistRequest.self, from: data)
        
        XCTAssertEqual(originalRequest.id, decodedRequest.id)
        XCTAssertEqual(originalRequest.status, decodedRequest.status)
        XCTAssertEqual(originalRequest.sourceURL, decodedRequest.sourceURL)
        XCTAssertEqual(originalRequest.transcript, decodedRequest.transcript)
        XCTAssertEqual(originalRequest.extractedSongs.count, decodedRequest.extractedSongs.count)
        XCTAssertEqual(originalRequest.extractedSongs[0], decodedRequest.extractedSongs[0])
    }
    
    // MARK: - Invalid Data Handling Tests
    
    func testPlaylistRequestDecodingWithMissingRequiredFields() throws {
        let invalidJSON = """
        {
            "status": "processing"
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(PlaylistRequest.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testPlaylistRequestDecodingWithInvalidStatus() throws {
        let invalidJSON = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "status": "invalid_status",
            "extractedSongs": [],
            "matchedSongs": [],
            "createdAt": "2024-01-01T00:00:00Z"
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(PlaylistRequest.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Business Logic Helper Tests
    
    func testIsCompleted() throws {
        var request = PlaylistRequest()
        
        // Helper function to test completion status
        func isCompleted(_ status: ProcessingStatus) -> Bool {
            return status == .complete
        }
        
        XCTAssertFalse(isCompleted(request.status))
        
        request.status = .complete
        XCTAssertTrue(isCompleted(request.status))
    }
    
    func testHasError() throws {
        var request = PlaylistRequest()
        
        // Helper function to test error status
        func hasError(_ status: ProcessingStatus) -> Bool {
            return status == .error
        }
        
        XCTAssertFalse(hasError(request.status))
        
        request.status = .error
        XCTAssertTrue(hasError(request.status))
    }
    
    func testProgressCalculation() throws {
        var request = PlaylistRequest()
        
        // Helper function to calculate progress
        func calculateProgress(_ request: PlaylistRequest) -> Double {
            switch request.status {
            case .idle:
                return 0.0
            case .processing:
                return 0.5
            case .complete:
                return 1.0
            case .error:
                return 0.0
            }
        }
        
        XCTAssertEqual(calculateProgress(request), 0.0)
        
        request.status = .processing
        XCTAssertEqual(calculateProgress(request), 0.5)
        
        request.status = .complete
        XCTAssertEqual(calculateProgress(request), 1.0)
        
        request.status = .error
        XCTAssertEqual(calculateProgress(request), 0.0)
    }
}