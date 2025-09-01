import XCTest
@testable import PlaylistCreator

final class MatchedSongTests: XCTestCase {
    
    // MARK: - Model Creation and Initialization Tests
    
    func testMatchedSongInitialization() throws {
        let originalSong = Song(title: "Original Title", artist: "Original Artist")
        let appleMusicSong = Song(title: "Apple Title", artist: "Apple Artist", appleID: "12345")
        
        let matchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        XCTAssertEqual(matchedSong.originalSong, originalSong)
        XCTAssertEqual(matchedSong.appleMusicSong, appleMusicSong)
        XCTAssertEqual(matchedSong.matchStatus, .auto)
    }
    
    func testMatchedSongWithPendingStatus() throws {
        let originalSong = Song(title: "Ambiguous Song", artist: "Unknown Artist")
        let appleMusicSong = Song(title: "Similar Song", artist: "Similar Artist", appleID: "67890")
        
        let matchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .pending
        )
        
        XCTAssertEqual(matchedSong.matchStatus, .pending)
    }
    
    func testMatchedSongWithUserSelection() throws {
        let originalSong = Song(title: "User Choice", artist: "Test Artist")
        let appleMusicSong = Song(title: "Selected Song", artist: "Selected Artist", appleID: "99999")
        
        let matchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .selected
        )
        
        XCTAssertEqual(matchedSong.matchStatus, .selected)
    }
    
    func testMatchedSongWithSkippedStatus() throws {
        let originalSong = Song(title: "Skipped Song", artist: "Skipped Artist")
        let appleMusicSong = Song(title: "Unwanted Match", artist: "Wrong Artist", appleID: "00000")
        
        let matchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .skipped
        )
        
        XCTAssertEqual(matchedSong.matchStatus, .skipped)
    }
    
    // MARK: - Property Validation Tests
    
    func testOriginalSongProperty() throws {
        let originalSong = Song(title: "Test Original", artist: "Test Artist", confidence: 0.6)
        let appleMusicSong = Song(title: "Test Match", artist: "Test Artist", appleID: "12345")
        
        let matchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        XCTAssertEqual(matchedSong.originalSong.title, "Test Original")
        XCTAssertEqual(matchedSong.originalSong.confidence, 0.6, accuracy: 0.001)
        XCTAssertNil(matchedSong.originalSong.appleID)
    }
    
    func testAppleMusicSongProperty() throws {
        let originalSong = Song(title: "Original", artist: "Artist")
        let appleMusicSong = Song(title: "Apple Match", artist: "Apple Artist", appleID: "apple123", confidence: 0.9)
        
        let matchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        XCTAssertEqual(matchedSong.appleMusicSong.title, "Apple Match")
        XCTAssertEqual(matchedSong.appleMusicSong.appleID, "apple123")
        XCTAssertEqual(matchedSong.appleMusicSong.confidence, 0.9, accuracy: 0.001)
    }
    
    // MARK: - Equality Tests
    
    func testMatchedSongEquality() throws {
        let originalSong = Song(title: "Test Song", artist: "Test Artist")
        let appleMusicSong = Song(title: "Matched Song", artist: "Matched Artist", appleID: "12345")
        
        let matchedSong1 = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        let matchedSong2 = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        XCTAssertEqual(matchedSong1, matchedSong2)
    }
    
    func testMatchedSongInequalityDifferentStatus() throws {
        let originalSong = Song(title: "Test Song", artist: "Test Artist")
        let appleMusicSong = Song(title: "Matched Song", artist: "Matched Artist", appleID: "12345")
        
        let matchedSong1 = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        let matchedSong2 = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .selected
        )
        
        XCTAssertNotEqual(matchedSong1, matchedSong2)
    }
    
    func testMatchedSongInequalityDifferentOriginalSong() throws {
        let originalSong1 = Song(title: "Song 1", artist: "Artist 1")
        let originalSong2 = Song(title: "Song 2", artist: "Artist 2")
        let appleMusicSong = Song(title: "Matched Song", artist: "Matched Artist", appleID: "12345")
        
        let matchedSong1 = MatchedSong(
            originalSong: originalSong1,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        let matchedSong2 = MatchedSong(
            originalSong: originalSong2,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        XCTAssertNotEqual(matchedSong1, matchedSong2)
    }
    
    func testMatchedSongInequalityDifferentAppleMusicSong() throws {
        let originalSong = Song(title: "Original Song", artist: "Original Artist")
        let appleMusicSong1 = Song(title: "Match 1", artist: "Artist 1", appleID: "111")
        let appleMusicSong2 = Song(title: "Match 2", artist: "Artist 2", appleID: "222")
        
        let matchedSong1 = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong1,
            matchStatus: .auto
        )
        
        let matchedSong2 = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong2,
            matchStatus: .auto
        )
        
        XCTAssertNotEqual(matchedSong1, matchedSong2)
    }
    
    // MARK: - Codable Tests
    
    func testMatchedSongCodableEncoding() throws {
        let originalSong = Song(title: "Original Song", artist: "Original Artist", confidence: 0.7)
        let appleMusicSong = Song(title: "Apple Song", artist: "Apple Artist", appleID: "apple456", confidence: 0.95)
        
        let matchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .selected
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(matchedSong)
        
        XCTAssertFalse(data.isEmpty)
        
        // Verify the JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        
        let originalSongJSON = json?["originalSong"] as? [String: Any]
        XCTAssertEqual(originalSongJSON?["title"] as? String, "Original Song")
        XCTAssertEqual(originalSongJSON?["artist"] as? String, "Original Artist")
        
        let appleMusicSongJSON = json?["appleMusicSong"] as? [String: Any]
        XCTAssertEqual(appleMusicSongJSON?["title"] as? String, "Apple Song")
        XCTAssertEqual(appleMusicSongJSON?["appleID"] as? String, "apple456")
        
        XCTAssertEqual(json?["matchStatus"] as? String, "selected")
    }
    
    func testMatchedSongCodableDecoding() throws {
        let json = """
        {
            "originalSong": {
                "title": "Decoded Original",
                "artist": "Decoded Artist",
                "confidence": 0.6
            },
            "appleMusicSong": {
                "title": "Decoded Apple Song",
                "artist": "Decoded Apple Artist",
                "appleID": "decoded123",
                "confidence": 0.88
            },
            "matchStatus": "pending"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let matchedSong = try decoder.decode(MatchedSong.self, from: data)
        
        XCTAssertEqual(matchedSong.originalSong.title, "Decoded Original")
        XCTAssertEqual(matchedSong.originalSong.artist, "Decoded Artist")
        XCTAssertEqual(matchedSong.originalSong.confidence, 0.6, accuracy: 0.001)
        
        XCTAssertEqual(matchedSong.appleMusicSong.title, "Decoded Apple Song")
        XCTAssertEqual(matchedSong.appleMusicSong.appleID, "decoded123")
        XCTAssertEqual(matchedSong.appleMusicSong.confidence, 0.88, accuracy: 0.001)
        
        XCTAssertEqual(matchedSong.matchStatus, .pending)
    }
    
    func testMatchedSongCodableRoundTrip() throws {
        let originalSong = Song(title: "Round Trip Original", artist: "RT Artist", confidence: 0.5)
        let appleMusicSong = Song(title: "Round Trip Apple", artist: "RT Apple Artist", appleID: "rt789", confidence: 0.92)
        
        let originalMatchedSong = MatchedSong(
            originalSong: originalSong,
            appleMusicSong: appleMusicSong,
            matchStatus: .auto
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalMatchedSong)
        
        let decoder = JSONDecoder()
        let decodedMatchedSong = try decoder.decode(MatchedSong.self, from: data)
        
        XCTAssertEqual(originalMatchedSong, decodedMatchedSong)
    }
    
    // MARK: - Invalid Data Handling Tests
    
    func testMatchedSongDecodingWithMissingFields() throws {
        let invalidJSON = """
        {
            "originalSong": {
                "title": "Incomplete",
                "artist": "Artist"
            },
            "matchStatus": "auto"
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(MatchedSong.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testMatchedSongDecodingWithInvalidMatchStatus() throws {
        let invalidJSON = """
        {
            "originalSong": {
                "title": "Original",
                "artist": "Artist"
            },
            "appleMusicSong": {
                "title": "Apple Song",
                "artist": "Apple Artist",
                "appleID": "123"
            },
            "matchStatus": "invalid_status"
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(MatchedSong.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Business Logic Tests
    
    func testIsIncludedInPlaylist() throws {
        let originalSong = Song(title: "Test", artist: "Artist")
        let appleMusicSong = Song(title: "Apple Test", artist: "Apple Artist", appleID: "123")
        
        // Helper function to test playlist inclusion
        func isIncludedInPlaylist(_ matchedSong: MatchedSong) -> Bool {
            switch matchedSong.matchStatus {
            case .auto, .selected:
                return true
            case .pending, .skipped:
                return false
            }
        }
        
        let autoMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .auto)
        let selectedMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .selected)
        let pendingMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .pending)
        let skippedMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .skipped)
        
        XCTAssertTrue(isIncludedInPlaylist(autoMatch))
        XCTAssertTrue(isIncludedInPlaylist(selectedMatch))
        XCTAssertFalse(isIncludedInPlaylist(pendingMatch))
        XCTAssertFalse(isIncludedInPlaylist(skippedMatch))
    }
    
    func testRequiresUserAction() throws {
        let originalSong = Song(title: "Test", artist: "Artist")
        let appleMusicSong = Song(title: "Apple Test", artist: "Apple Artist", appleID: "123")
        
        // Helper function to test if user action is required
        func requiresUserAction(_ matchedSong: MatchedSong) -> Bool {
            return matchedSong.matchStatus == .pending
        }
        
        let autoMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .auto)
        let selectedMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .selected)
        let pendingMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .pending)
        let skippedMatch = MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .skipped)
        
        XCTAssertFalse(requiresUserAction(autoMatch))
        XCTAssertFalse(requiresUserAction(selectedMatch))
        XCTAssertTrue(requiresUserAction(pendingMatch))
        XCTAssertFalse(requiresUserAction(skippedMatch))
    }
}