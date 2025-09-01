import XCTest
@testable import PlaylistCreator

final class PlaylistErrorTests: XCTestCase {
    
    // MARK: - PlaylistError Tests
    
    func testPlaylistErrorCases() throws {
        let audioError = AudioProcessingError.fileNotFound("/path/to/file")
        let transcriptionError = TranscriptionError.apiKeyMissing
        let musicExtractionError = MusicExtractionError.noSongsFound
        let musicSearchError = MusicSearchError.authenticationRequired
        let playlistCreationError = PlaylistCreationError.creationFailed("Failed to create")
        
        let playlistErrors: [PlaylistError] = [
            .audioProcessingFailed(audioError),
            .transcriptionFailed(transcriptionError),
            .musicExtractionFailed(musicExtractionError),
            .musicSearchFailed(musicSearchError),
            .playlistCreationFailed(playlistCreationError),
            .invalidInput("Invalid input message"),
            .networkError("Network failure"),
            .authenticationRequired,
            .unknown("Unknown error occurred")
        ]
        
        XCTAssertEqual(playlistErrors.count, 9)
        
        // Test error descriptions
        XCTAssertTrue(playlistErrors[0].localizedDescription.contains("Audio processing failed"))
        XCTAssertTrue(playlistErrors[1].localizedDescription.contains("Transcription failed"))
        XCTAssertTrue(playlistErrors[2].localizedDescription.contains("Music extraction failed"))
        XCTAssertTrue(playlistErrors[3].localizedDescription.contains("Music search failed"))
        XCTAssertTrue(playlistErrors[4].localizedDescription.contains("Playlist creation failed"))
        XCTAssertEqual(playlistErrors[5].localizedDescription, "Invalid input: Invalid input message")
        XCTAssertEqual(playlistErrors[6].localizedDescription, "Network error: Network failure")
        XCTAssertEqual(playlistErrors[7].localizedDescription, "Authentication required")
        XCTAssertEqual(playlistErrors[8].localizedDescription, "Unknown error: Unknown error occurred")
    }
    
    func testPlaylistErrorEquality() throws {
        let error1 = PlaylistError.invalidInput("Test message")
        let error2 = PlaylistError.invalidInput("Test message")
        let error3 = PlaylistError.invalidInput("Different message")
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        
        let authError1 = PlaylistError.authenticationRequired
        let authError2 = PlaylistError.authenticationRequired
        XCTAssertEqual(authError1, authError2)
    }
    
    // MARK: - AudioProcessingError Tests
    
    func testAudioProcessingErrorCases() throws {
        let errors: [AudioProcessingError] = [
            .unsupportedFormat("flac"),
            .fileNotFound("/path/to/missing.mp3"),
            .extractionFailed("FFmpeg error"),
            .normalizationFailed("Sample rate conversion failed"),
            .notImplemented
        ]
        
        XCTAssertEqual(errors.count, 5)
        
        XCTAssertEqual(errors[0].localizedDescription, "Unsupported audio format: flac")
        XCTAssertEqual(errors[1].localizedDescription, "Audio file not found: /path/to/missing.mp3")
        XCTAssertEqual(errors[2].localizedDescription, "Audio extraction failed: FFmpeg error")
        XCTAssertEqual(errors[3].localizedDescription, "Audio normalization failed: Sample rate conversion failed")
        XCTAssertEqual(errors[4].localizedDescription, "Feature not yet implemented")
    }
    
    func testAudioProcessingErrorEquality() throws {
        let error1 = AudioProcessingError.fileNotFound("/path/file.mp3")
        let error2 = AudioProcessingError.fileNotFound("/path/file.mp3")
        let error3 = AudioProcessingError.fileNotFound("/different/path.mp3")
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        
        let notImplemented1 = AudioProcessingError.notImplemented
        let notImplemented2 = AudioProcessingError.notImplemented
        XCTAssertEqual(notImplemented1, notImplemented2)
    }
    
    // MARK: - TranscriptionError Tests
    
    func testTranscriptionErrorCases() throws {
        let errors: [TranscriptionError] = [
            .apiKeyMissing,
            .apiRequestFailed("HTTP 401"),
            .audioFormatUnsupported,
            .transcriptionEmpty,
            .notImplemented
        ]
        
        XCTAssertEqual(errors.count, 5)
        
        XCTAssertEqual(errors[0].localizedDescription, "OpenAI API key missing")
        XCTAssertEqual(errors[1].localizedDescription, "Transcription API request failed: HTTP 401")
        XCTAssertEqual(errors[2].localizedDescription, "Audio format not supported for transcription")
        XCTAssertEqual(errors[3].localizedDescription, "Transcription result was empty")
        XCTAssertEqual(errors[4].localizedDescription, "Feature not yet implemented")
    }
    
    func testTranscriptionErrorEquality() throws {
        let error1 = TranscriptionError.apiRequestFailed("Timeout")
        let error2 = TranscriptionError.apiRequestFailed("Timeout")
        let error3 = TranscriptionError.apiRequestFailed("Rate limit")
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    // MARK: - MusicExtractionError Tests
    
    func testMusicExtractionErrorCases() throws {
        let errors: [MusicExtractionError] = [
            .apiKeyMissing,
            .apiRequestFailed("Invalid response"),
            .noSongsFound,
            .parsingFailed("JSON malformed"),
            .notImplemented
        ]
        
        XCTAssertEqual(errors.count, 5)
        
        XCTAssertEqual(errors[0].localizedDescription, "OpenAI API key missing")
        XCTAssertEqual(errors[1].localizedDescription, "Music extraction API request failed: Invalid response")
        XCTAssertEqual(errors[2].localizedDescription, "No songs found in transcript")
        XCTAssertEqual(errors[3].localizedDescription, "Failed to parse extracted songs: JSON malformed")
        XCTAssertEqual(errors[4].localizedDescription, "Feature not yet implemented")
    }
    
    // MARK: - MusicSearchError Tests
    
    func testMusicSearchErrorCases() throws {
        let errors: [MusicSearchError] = [
            .authenticationRequired,
            .searchFailed("API unavailable"),
            .noResultsFound("Unknown Artist - Unknown Song"),
            .rateLimitExceeded,
            .notImplemented
        ]
        
        XCTAssertEqual(errors.count, 5)
        
        XCTAssertEqual(errors[0].localizedDescription, "Apple Music authentication required")
        XCTAssertEqual(errors[1].localizedDescription, "Music search failed: API unavailable")
        XCTAssertEqual(errors[2].localizedDescription, "No results found for: Unknown Artist - Unknown Song")
        XCTAssertEqual(errors[3].localizedDescription, "Search rate limit exceeded")
        XCTAssertEqual(errors[4].localizedDescription, "Feature not yet implemented")
    }
    
    // MARK: - PlaylistCreationError Tests
    
    func testPlaylistCreationErrorCases() throws {
        let errors: [PlaylistCreationError] = [
            .authenticationRequired,
            .creationFailed("Insufficient storage"),
            .songAdditionFailed("Song not available in region"),
            .playlistNotFound("playlist-123"),
            .insufficientPermissions,
            .notImplemented
        ]
        
        XCTAssertEqual(errors.count, 6)
        
        XCTAssertEqual(errors[0].localizedDescription, "Apple Music authentication required")
        XCTAssertEqual(errors[1].localizedDescription, "Playlist creation failed: Insufficient storage")
        XCTAssertEqual(errors[2].localizedDescription, "Failed to add songs to playlist: Song not available in region")
        XCTAssertEqual(errors[3].localizedDescription, "Playlist not found: playlist-123")
        XCTAssertEqual(errors[4].localizedDescription, "Insufficient permissions to create playlist")
        XCTAssertEqual(errors[5].localizedDescription, "Feature not yet implemented")
    }
    
    // MARK: - Error Hierarchy Tests
    
    func testErrorHierarchy() throws {
        let audioError = AudioProcessingError.fileNotFound("/test")
        let playlistError = PlaylistError.audioProcessingFailed(audioError)
        
        XCTAssertTrue(playlistError.localizedDescription.contains("Audio processing failed"))
        XCTAssertTrue(playlistError.localizedDescription.contains("Audio file not found: /test"))
    }
    
    func testNestedErrorEquality() throws {
        let audioError1 = AudioProcessingError.fileNotFound("/test")
        let audioError2 = AudioProcessingError.fileNotFound("/test")
        let playlistError1 = PlaylistError.audioProcessingFailed(audioError1)
        let playlistError2 = PlaylistError.audioProcessingFailed(audioError2)
        
        XCTAssertEqual(playlistError1, playlistError2)
    }
    
    func testDifferentNestedErrorInequality() throws {
        let audioError = AudioProcessingError.fileNotFound("/test")
        let transcriptionError = TranscriptionError.apiKeyMissing
        let playlistError1 = PlaylistError.audioProcessingFailed(audioError)
        let playlistError2 = PlaylistError.transcriptionFailed(transcriptionError)
        
        XCTAssertNotEqual(playlistError1, playlistError2)
    }
    
    // MARK: - LocalizedError Conformance Tests
    
    func testLocalizedErrorConformance() throws {
        let errors: [LocalizedError] = [
            PlaylistError.invalidInput("test"),
            AudioProcessingError.fileNotFound("/test"),
            TranscriptionError.apiKeyMissing,
            MusicExtractionError.noSongsFound,
            MusicSearchError.authenticationRequired,
            PlaylistCreationError.creationFailed("test")
        ]
        
        // All errors should have localized descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
