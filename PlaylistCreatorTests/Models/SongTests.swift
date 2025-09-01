import XCTest
@testable import PlaylistCreator

final class SongTests: XCTestCase {
    
    // MARK: - Model Creation and Initialization Tests
    
    func testSongInitialization() throws {
        let song = Song(title: "Test Song", artist: "Test Artist")
        
        XCTAssertEqual(song.title, "Test Song")
        XCTAssertEqual(song.artist, "Test Artist")
        XCTAssertNil(song.appleID)
        XCTAssertEqual(song.confidence, 0.0)
    }
    
    func testSongInitializationWithAllParameters() throws {
        let song = Song(
            title: "Test Song",
            artist: "Test Artist", 
            appleID: "12345",
            confidence: 0.85
        )
        
        XCTAssertEqual(song.title, "Test Song")
        XCTAssertEqual(song.artist, "Test Artist")
        XCTAssertEqual(song.appleID, "12345")
        XCTAssertEqual(song.confidence, 0.85, accuracy: 0.001)
    }
    
    // MARK: - Property Validation Tests
    
    func testEmptyTitleHandling() throws {
        let song = Song(title: "", artist: "Test Artist")
        XCTAssertEqual(song.title, "")
        XCTAssertTrue(song.title.isEmpty)
    }
    
    func testEmptyArtistHandling() throws {
        let song = Song(title: "Test Song", artist: "")
        XCTAssertEqual(song.artist, "")
        XCTAssertTrue(song.artist.isEmpty)
    }
    
    func testConfidenceScoreBounds() throws {
        // Test minimum confidence
        let minSong = Song(title: "Test", artist: "Artist", confidence: 0.0)
        XCTAssertEqual(minSong.confidence, 0.0)
        
        // Test maximum confidence  
        let maxSong = Song(title: "Test", artist: "Artist", confidence: 1.0)
        XCTAssertEqual(maxSong.confidence, 1.0)
        
        // Test values outside bounds are allowed (validation should happen at creation time)
        let overMaxSong = Song(title: "Test", artist: "Artist", confidence: 1.5)
        XCTAssertEqual(overMaxSong.confidence, 1.5)
        
        let underMinSong = Song(title: "Test", artist: "Artist", confidence: -0.1)
        XCTAssertEqual(underMinSong.confidence, -0.1)
    }
    
    func testAppleIDOptionalHandling() throws {
        let songWithoutID = Song(title: "Test", artist: "Artist")
        XCTAssertNil(songWithoutID.appleID)
        
        let songWithID = Song(title: "Test", artist: "Artist", appleID: "12345")
        XCTAssertEqual(songWithID.appleID, "12345")
        
        let songWithEmptyID = Song(title: "Test", artist: "Artist", appleID: "")
        XCTAssertEqual(songWithEmptyID.appleID, "")
    }
    
    // MARK: - Equality Tests
    
    func testSongEquality() throws {
        let song1 = Song(title: "Test Song", artist: "Test Artist")
        let song2 = Song(title: "Test Song", artist: "Test Artist")
        
        XCTAssertEqual(song1, song2)
    }
    
    func testSongEqualityWithAllFields() throws {
        let song1 = Song(title: "Test", artist: "Artist", appleID: "123", confidence: 0.5)
        let song2 = Song(title: "Test", artist: "Artist", appleID: "123", confidence: 0.5)
        
        XCTAssertEqual(song1, song2)
    }
    
    func testSongInequality() throws {
        let song1 = Song(title: "Song 1", artist: "Artist")
        let song2 = Song(title: "Song 2", artist: "Artist")
        
        XCTAssertNotEqual(song1, song2)
    }
    
    func testSongInequalityDifferentAppleID() throws {
        let song1 = Song(title: "Test", artist: "Artist", appleID: "123")
        let song2 = Song(title: "Test", artist: "Artist", appleID: "456")
        
        XCTAssertNotEqual(song1, song2)
    }
    
    func testSongInequalityDifferentConfidence() throws {
        let song1 = Song(title: "Test", artist: "Artist", confidence: 0.5)
        let song2 = Song(title: "Test", artist: "Artist", confidence: 0.8)
        
        XCTAssertNotEqual(song1, song2)
    }
    
    // MARK: - Codable Tests
    
    func testSongCodableEncoding() throws {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "12345", confidence: 0.75)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(song)
        
        XCTAssertFalse(data.isEmpty)
        
        // Verify the JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["title"] as? String, "Test Song")
        XCTAssertEqual(json?["artist"] as? String, "Test Artist")
        XCTAssertEqual(json?["appleID"] as? String, "12345")
        XCTAssertEqual(json?["confidence"] as? Double ?? 0, 0.75, accuracy: 0.001)
    }
    
    func testSongCodableDecoding() throws {
        let json = """
        {
            "title": "Decoded Song",
            "artist": "Decoded Artist",
            "appleID": "54321",
            "confidence": 0.9
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let song = try decoder.decode(Song.self, from: data)
        
        XCTAssertEqual(song.title, "Decoded Song")
        XCTAssertEqual(song.artist, "Decoded Artist")
        XCTAssertEqual(song.appleID, "54321")
        XCTAssertEqual(song.confidence, 0.9, accuracy: 0.001)
    }
    
    func testSongCodableRoundTrip() throws {
        let originalSong = Song(title: "Round Trip", artist: "Test Artist", appleID: "99999", confidence: 0.42)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSong)
        
        let decoder = JSONDecoder()
        let decodedSong = try decoder.decode(Song.self, from: data)
        
        XCTAssertEqual(originalSong, decodedSong)
    }
    
    func testSongCodableWithNilAppleID() throws {
        let song = Song(title: "No Apple ID", artist: "Test Artist")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(song)
        
        let decoder = JSONDecoder()
        let decodedSong = try decoder.decode(Song.self, from: data)
        
        XCTAssertEqual(decodedSong.title, "No Apple ID")
        XCTAssertEqual(decodedSong.artist, "Test Artist")
        XCTAssertNil(decodedSong.appleID)
        XCTAssertEqual(decodedSong.confidence, 0.0)
    }
    
    // MARK: - Invalid Data Handling Tests
    
    func testSongDecodingWithMissingRequiredFields() throws {
        let invalidJSON = """
        {
            "title": "Missing Artist"
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(Song.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testSongDecodingWithInvalidTypes() throws {
        let invalidJSON = """
        {
            "title": "Valid Title",
            "artist": "Valid Artist",
            "confidence": "not a number"
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(Song.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}