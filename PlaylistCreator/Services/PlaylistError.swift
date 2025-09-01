import Foundation

enum PlaylistError: Error, LocalizedError, Equatable {
    case audioProcessingFailed(AudioProcessingError)
    case transcriptionFailed(TranscriptionError)
    case musicExtractionFailed(MusicExtractionError)
    case musicSearchFailed(MusicSearchError)
    case playlistCreationFailed(PlaylistCreationError)
    case invalidInput(String)
    case networkError(String)
    case authenticationRequired
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .audioProcessingFailed(let error):
            return "Audio processing failed: \(error.localizedDescription)"
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .musicExtractionFailed(let error):
            return "Music extraction failed: \(error.localizedDescription)"
        case .musicSearchFailed(let error):
            return "Music search failed: \(error.localizedDescription)"
        case .playlistCreationFailed(let error):
            return "Playlist creation failed: \(error.localizedDescription)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationRequired:
            return "Authentication required"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

enum AudioProcessingError: Error, LocalizedError, Equatable {
    case unsupportedFormat(String)
    case fileNotFound(String)
    case extractionFailed(String)
    case normalizationFailed(String)
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported audio format: \(format)"
        case .fileNotFound(let path):
            return "Audio file not found: \(path)"
        case .extractionFailed(let reason):
            return "Audio extraction failed: \(reason)"
        case .normalizationFailed(let reason):
            return "Audio normalization failed: \(reason)"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}

enum TranscriptionError: Error, LocalizedError, Equatable {
    case apiKeyMissing
    case apiRequestFailed(String)
    case audioFormatUnsupported
    case transcriptionEmpty
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "OpenAI API key missing"
        case .apiRequestFailed(let reason):
            return "Transcription API request failed: \(reason)"
        case .audioFormatUnsupported:
            return "Audio format not supported for transcription"
        case .transcriptionEmpty:
            return "Transcription result was empty"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}

enum MusicExtractionError: Error, LocalizedError, Equatable {
    case apiKeyMissing
    case apiRequestFailed(String)
    case noSongsFound
    case parsingFailed(String)
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "OpenAI API key missing"
        case .apiRequestFailed(let reason):
            return "Music extraction API request failed: \(reason)"
        case .noSongsFound:
            return "No songs found in transcript"
        case .parsingFailed(let reason):
            return "Failed to parse extracted songs: \(reason)"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}

enum MusicSearchError: Error, LocalizedError, Equatable {
    case authenticationRequired
    case searchFailed(String)
    case noResultsFound(String)
    case rateLimitExceeded
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Apple Music authentication required"
        case .searchFailed(let reason):
            return "Music search failed: \(reason)"
        case .noResultsFound(let query):
            return "No results found for: \(query)"
        case .rateLimitExceeded:
            return "Search rate limit exceeded"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}

enum PlaylistCreationError: Error, LocalizedError, Equatable {
    case authenticationRequired
    case creationFailed(String)
    case songAdditionFailed(String)
    case playlistNotFound(String)
    case insufficientPermissions
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Apple Music authentication required"
        case .creationFailed(let reason):
            return "Playlist creation failed: \(reason)"
        case .songAdditionFailed(let reason):
            return "Failed to add songs to playlist: \(reason)"
        case .playlistNotFound(let id):
            return "Playlist not found: \(id)"
        case .insufficientPermissions:
            return "Insufficient permissions to create playlist"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}
