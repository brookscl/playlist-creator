import Foundation

/// Represents the status of a song match between extracted content and Apple Music catalog
///
/// MatchStatus is used to track the state of individual song matches during the playlist creation process:
/// - High-confidence matches are automatically selected (.auto)
/// - Ambiguous matches require user review (.pending)
/// - Users can explicitly select matches (.selected) 
/// - Users can skip unwanted matches (.skipped)
///
/// This status determines whether a song will be included in the final playlist.
enum MatchStatus: String, Codable, CaseIterable {
    /// Automatically selected due to high confidence match
    case auto
    
    /// Awaiting user decision (ambiguous match)
    case pending
    
    /// Explicitly selected by user
    case selected
    
    /// Explicitly skipped/rejected by user
    case skipped
}

// MARK: - CustomStringConvertible

extension MatchStatus: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}

// MARK: - Convenience Properties

extension MatchStatus {
    /// Returns true if this match will be included in the final playlist
    var isIncludedInPlaylist: Bool {
        switch self {
        case .auto, .selected:
            return true
        case .pending, .skipped:
            return false
        }
    }
    
    /// Returns true if user action is required for this match
    var requiresUserAction: Bool {
        return self == .pending
    }
    
    /// Returns true if the user has made a decision about this match
    var hasUserDecision: Bool {
        return self == .selected || self == .skipped
    }
    
    /// Returns true if this match was automatically determined by the system
    var isAutomatic: Bool {
        return self == .auto
    }
    
    /// Returns a user-friendly description of the match status
    var displayDescription: String {
        switch self {
        case .auto:
            return "Auto-selected"
        case .pending:
            return "Needs review"
        case .selected:
            return "Selected"
        case .skipped:
            return "Skipped"
        }
    }
    
    /// Returns an action description for UI buttons
    var actionDescription: String {
        switch self {
        case .auto:
            return "Auto-matched"
        case .pending:
            return "Choose"
        case .selected:
            return "Selected"
        case .skipped:
            return "Skipped"
        }
    }
}