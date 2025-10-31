import Foundation

/// Utility for determining automatic match selection based on confidence thresholds
///
/// MatchSelector implements the auto-selection logic that decides which song matches
/// should be automatically accepted versus requiring user review. It uses confidence
/// scores to classify matches and provides batch processing capabilities.
struct MatchSelector {

    // MARK: - Configuration

    /// Default threshold for automatic selection (matches >= this value are auto-selected)
    static let defaultAutoSelectThreshold: Double = 0.9

    /// Default minimum confidence for considering a match (matches below this may be shown with warning)
    static let defaultMinimumConfidence: Double = 0.0

    // MARK: - Match Status Determination

    /// Determines the appropriate MatchStatus for a song based on its confidence score
    /// - Parameters:
    ///   - song: The song with a confidence score
    ///   - autoSelectThreshold: Confidence threshold for auto-selection (default: 0.9)
    ///   - minimumConfidence: Minimum confidence to consider (default: 0.0)
    /// - Returns: The determined MatchStatus (.auto or .pending)
    static func determineMatchStatus(
        for song: Song,
        autoSelectThreshold: Double = defaultAutoSelectThreshold,
        minimumConfidence: Double = defaultMinimumConfidence
    ) -> MatchStatus {
        // High confidence matches are automatically selected
        if song.confidence >= autoSelectThreshold {
            return .auto
        }

        // All other matches require user review
        // (including low confidence matches, which are presented with quality indicators)
        return .pending
    }

    /// Determines match status from a search result
    /// - Parameters:
    ///   - searchResult: The search result to evaluate
    ///   - autoSelectThreshold: Confidence threshold for auto-selection
    ///   - minimumConfidence: Minimum confidence to consider
    /// - Returns: The determined MatchStatus
    static func determineMatchStatus(
        for searchResult: SearchResult,
        autoSelectThreshold: Double = defaultAutoSelectThreshold,
        minimumConfidence: Double = defaultMinimumConfidence
    ) -> MatchStatus {
        return determineMatchStatus(
            for: searchResult.song,
            autoSelectThreshold: autoSelectThreshold,
            minimumConfidence: minimumConfidence
        )
    }

    // MARK: - Batch Processing

    /// Process multiple songs and determine their match statuses
    /// - Parameters:
    ///   - songs: Array of songs to process
    ///   - autoSelectThreshold: Confidence threshold for auto-selection
    /// - Returns: Array of MatchedSong objects with determined statuses
    static func processMatches(
        _ songs: [Song],
        autoSelectThreshold: Double = defaultAutoSelectThreshold
    ) -> [MatchedSong] {
        return songs.map { song in
            let status = determineMatchStatus(for: song, autoSelectThreshold: autoSelectThreshold)
            // For batch processing, we create MatchedSong with the same song as both original and match
            // In real usage, this would have different original and Apple Music songs
            return MatchedSong(originalSong: song, appleMusicSong: song, matchStatus: status)
        }
    }

    // MARK: - SearchResult to MatchedSong Conversion

    /// Creates a MatchedSong from an original song and its search result
    /// - Parameters:
    ///   - originalSong: The original song from extraction
    ///   - searchResult: The search result from Apple Music
    ///   - autoSelectThreshold: Confidence threshold for auto-selection
    /// - Returns: A MatchedSong with the appropriate status
    static func createMatchedSong(
        original originalSong: Song,
        searchResult: SearchResult,
        autoSelectThreshold: Double = defaultAutoSelectThreshold
    ) -> MatchedSong {
        let status = determineMatchStatus(for: searchResult, autoSelectThreshold: autoSelectThreshold)
        return MatchedSong(
            originalSong: originalSong,
            appleMusicSong: searchResult.song,
            matchStatus: status
        )
    }

    /// Creates multiple MatchedSongs from an original song and its search results
    /// - Parameters:
    ///   - originalSong: The original song from extraction
    ///   - searchResults: Array of search results from Apple Music
    ///   - autoSelectThreshold: Confidence threshold for auto-selection
    /// - Returns: Array of MatchedSong objects
    static func createMatchedSongs(
        original originalSong: Song,
        searchResults: [SearchResult],
        autoSelectThreshold: Double = defaultAutoSelectThreshold
    ) -> [MatchedSong] {
        return searchResults.map { searchResult in
            createMatchedSong(
                original: originalSong,
                searchResult: searchResult,
                autoSelectThreshold: autoSelectThreshold
            )
        }
    }

    // MARK: - Selection Summary

    /// Summary statistics for a batch of match results
    struct SelectionSummary {
        let totalMatches: Int
        let autoSelected: Int
        let requiresReview: Int
        let skipped: Int
        let selected: Int

        var percentageAutoSelected: Double {
            guard totalMatches > 0 else { return 0.0 }
            return Double(autoSelected) / Double(totalMatches) * 100.0
        }

        var percentageRequiresReview: Double {
            guard totalMatches > 0 else { return 0.0 }
            return Double(requiresReview) / Double(totalMatches) * 100.0
        }
    }

    /// Generates a summary of match selection results
    /// - Parameter results: Array of MatchedSong objects
    /// - Returns: A SelectionSummary with statistics
    static func generateSelectionSummary(_ results: [MatchedSong]) -> SelectionSummary {
        let autoSelected = results.filter { $0.matchStatus == .auto }.count
        let requiresReview = results.filter { $0.matchStatus == .pending }.count
        let skipped = results.filter { $0.matchStatus == .skipped }.count
        let selected = results.filter { $0.matchStatus == .selected }.count

        return SelectionSummary(
            totalMatches: results.count,
            autoSelected: autoSelected,
            requiresReview: requiresReview,
            skipped: skipped,
            selected: selected
        )
    }

    // MARK: - Match Quality Descriptions

    /// Returns a user-friendly quality description for a song match
    /// - Parameter song: The song to describe
    /// - Returns: A string description of match quality
    static func qualityDescription(for song: Song) -> String {
        switch song.confidence {
        case 0.9...:
            return "Excellent match"
        case 0.7..<0.9:
            return "Good match"
        case 0.5..<0.7:
            return "Fair match"
        default:
            return "Poor match"
        }
    }

    /// Returns a user-friendly quality description for a search result
    /// - Parameter searchResult: The search result to describe
    /// - Returns: A string description of match quality
    static func qualityDescription(for searchResult: SearchResult) -> String {
        return qualityDescription(for: searchResult.song)
    }

    /// Returns a detailed match explanation for debugging
    /// - Parameters:
    ///   - originalSong: The original song from extraction
    ///   - searchResult: The search result from Apple Music
    /// - Returns: A string explaining the match decision
    static func matchExplanation(original originalSong: Song, searchResult: SearchResult) -> String {
        let confidence = searchResult.matchConfidence
        let quality = qualityDescription(for: searchResult)
        let status = determineMatchStatus(for: searchResult)

        var explanation = "\(quality) (\(String(format: "%.1f%%", confidence * 100)))"

        if status == .auto {
            explanation += " - Automatically selected"
        } else {
            explanation += " - Requires review"
        }

        // Add note about title/artist differences
        if originalSong.title.lowercased() != searchResult.song.title.lowercased() {
            explanation += "\nTitle variation: \"\(originalSong.title)\" → \"\(searchResult.song.title)\""
        }

        if originalSong.artist.lowercased() != searchResult.song.artist.lowercased() {
            explanation += "\nArtist variation: \"\(originalSong.artist)\" → \"\(searchResult.song.artist)\""
        }

        return explanation
    }
}
