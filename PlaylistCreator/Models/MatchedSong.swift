import Foundation

/// Represents a pairing between an originally extracted song and its Apple Music catalog match
///
/// MatchedSong is used during the song matching phase of playlist creation to:
/// - Link extracted songs from transcripts to Apple Music catalog entries
/// - Track the confidence and status of each match
/// - Support user review and selection of ambiguous matches
/// - Maintain the relationship between original and matched content
///
/// This model is essential for the card-based UI where users review potential matches.
struct MatchedSong: Codable, Equatable, Hashable {
    /// The original song extracted from transcript/content
    let originalSong: Song

    /// The corresponding song found in Apple Music catalog
    let appleMusicSong: Song

    /// Current status of this match (auto, pending, selected, skipped)
    var matchStatus: MatchStatus

    /// URL for 30-second preview audio (from Apple Music)
    let previewURL: URL?

    /// Creates a new MatchedSong instance
    /// - Parameters:
    ///   - originalSong: The song extracted from source content
    ///   - appleMusicSong: The potential match from Apple Music catalog
    ///   - matchStatus: The current match status
    ///   - previewURL: Optional URL for preview audio
    init(originalSong: Song, appleMusicSong: Song, matchStatus: MatchStatus, previewURL: URL? = nil) {
        self.originalSong = originalSong
        self.appleMusicSong = appleMusicSong
        self.matchStatus = matchStatus
        self.previewURL = previewURL
    }
}

// MARK: - Hashable Implementation

extension MatchedSong {
    func hash(into hasher: inout Hasher) {
        hasher.combine(originalSong)
        hasher.combine(appleMusicSong)
        hasher.combine(matchStatus)
        hasher.combine(previewURL)
    }
}

// MARK: - Convenience Properties

extension MatchedSong {
    /// Returns true if this match will be included in the final playlist
    var isIncludedInPlaylist: Bool {
        return matchStatus.isIncludedInPlaylist
    }
    
    /// Returns true if user action is required for this match
    var requiresUserAction: Bool {
        return matchStatus.requiresUserAction
    }
    
    /// Returns the confidence score from the Apple Music match
    var confidence: Double {
        return appleMusicSong.confidence
    }
    
    /// Returns a display title combining both song titles if different
    var displayTitle: String {
        if originalSong.title.lowercased() == appleMusicSong.title.lowercased() {
            return appleMusicSong.title
        } else {
            return "\(originalSong.title) → \(appleMusicSong.title)"
        }
    }
    
    /// Returns a display artist combining both artists if different
    var displayArtist: String {
        if originalSong.artist.lowercased() == appleMusicSong.artist.lowercased() {
            return appleMusicSong.artist
        } else {
            return "\(originalSong.artist) → \(appleMusicSong.artist)"
        }
    }
}

// MARK: - CustomStringConvertible

extension MatchedSong: CustomStringConvertible {
    var description: String {
        let statusEmoji = matchStatus.isIncludedInPlaylist ? "✅" : "❌"
        return "\(statusEmoji) \(displayArtist) - \(displayTitle) (\(matchStatus.displayDescription))"
    }
}

// MARK: - Match Quality Assessment

extension MatchedSong {
    /// Enum representing the quality of a match
    enum MatchQuality {
        case excellent  // > 0.9
        case good      // 0.7 - 0.9
        case fair      // 0.5 - 0.7
        case poor      // < 0.5
    }
    
    /// Returns the quality assessment of this match based on confidence score
    var matchQuality: MatchQuality {
        switch confidence {
        case 0.9...:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.5..<0.7:
            return .fair
        default:
            return .poor
        }
    }
    
    /// Returns a color-coded quality indicator for UI display
    var qualityIndicator: String {
        switch matchQuality {
        case .excellent:
            return "🟢"
        case .good:
            return "🟡"
        case .fair:
            return "🟠"
        case .poor:
            return "🔴"
        }
    }
}