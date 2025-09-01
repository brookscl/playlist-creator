import Foundation

/// Represents the current state of playlist creation workflow processing
///
/// ProcessingStatus tracks the overall progress of converting content (audio files, URLs) 
/// into Apple Music playlists. This enum is used throughout the application to:
/// - Display appropriate UI states
/// - Enable/disable user interactions
/// - Handle error states and recovery
/// - Provide progress feedback
enum ProcessingStatus: String, Codable, CaseIterable {
    /// Initial state - no processing has started
    case idle
    
    /// Currently processing content (transcribing, extracting, searching, etc.)
    case processing
    
    /// Processing completed successfully, playlist created
    case complete
    
    /// Processing failed due to an error
    case error
}

// MARK: - CustomStringConvertible

extension ProcessingStatus: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}

// MARK: - Convenience Properties

extension ProcessingStatus {
    /// Returns true if the status indicates processing is currently active
    var isProcessing: Bool {
        return self == .processing
    }
    
    /// Returns true if the status indicates successful completion
    var isComplete: Bool {
        return self == .complete
    }
    
    /// Returns true if the status indicates an error occurred
    var hasError: Bool {
        return self == .error
    }
    
    /// Returns true if processing can be started (idle or error states)
    var canStartProcessing: Bool {
        return self == .idle || self == .error
    }
    
    /// Returns a user-friendly description of the current status
    var displayDescription: String {
        switch self {
        case .idle:
            return "Ready to start"
        case .processing:
            return "Processing..."
        case .complete:
            return "Complete"
        case .error:
            return "Error occurred"
        }
    }
}