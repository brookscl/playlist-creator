import Foundation
import MusicKit

/// Protocol for MusicKit client to enable dependency injection and testing
protocol MusicKitClientProtocol {
    associatedtype SongType
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func search(term: String) async throws -> [SongType]
}

/// Protocol for extracted song data from search results
protocol MusicKitSongProtocol {
    var id: String { get }
    var title: String { get }
    var artistName: String { get }
    var previewURL: URL? { get }
}

/// Service for searching Apple Music catalog and matching songs
@available(macOS 12.0, *)
class AppleMusicSearchService<Client: MusicKitClientProtocol> where Client.SongType: MusicKitSongProtocol {

    // MARK: - Properties

    private let musicKitClient: Client
    private let minimumConfidence: Double
    private let rateLimitDelay: TimeInterval

    // MARK: - Initialization

    /// Initialize with a MusicKit client (supports dependency injection)
    init(
        musicKitClient: Client,
        minimumConfidence: Double = 0.7,
        rateLimitDelay: TimeInterval = 0.1
    ) {
        self.musicKitClient = musicKitClient
        self.minimumConfidence = minimumConfidence
        self.rateLimitDelay = rateLimitDelay
    }

    // MARK: - Authorization

    /// Request Apple Music authorization
    func requestAuthorization() async throws {
        try await musicKitClient.requestAuthorization()
    }

    // MARK: - Private Helper Methods

    /// Generate multiple query strategies for a song
    private func generateQueryStrategies(for song: Song) -> [String] {
        var queries: [String] = []

        // Clean the title and artist
        let cleanTitle = cleanSearchTerm(song.title)
        let cleanArtist = cleanSearchTerm(song.artist)

        // Strategy 1: Basic "title artist"
        queries.append("\(cleanTitle) \(cleanArtist)")

        // Strategy 2: Try with "The" prefix if not present
        if !cleanArtist.lowercased().hasPrefix("the ") {
            queries.append("\(cleanTitle) The \(cleanArtist)")
        }

        // Strategy 3: Try without "The" prefix if present
        if cleanArtist.lowercased().hasPrefix("the ") {
            let artistWithoutThe = String(cleanArtist.dropFirst(4))
            queries.append("\(cleanTitle) \(artistWithoutThe)")
        }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        return queries.filter { seen.insert($0.lowercased()).inserted }
    }

    /// Clean a search term by removing special characters and extra whitespace
    private func cleanSearchTerm(_ term: String) -> String {
        // Remove common noise patterns
        var cleaned = term

        // Remove quotes and other special characters
        cleaned = cleaned.replacingOccurrences(of: "\"", with: "")
        cleaned = cleaned.replacingOccurrences(of: "'s ", with: " ")

        // Remove parenthetical content that might confuse search
        if let regex = try? NSRegularExpression(pattern: "\\([^)]*\\)", options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: range, withTemplate: "")
        }

        // Normalize whitespace
        cleaned = cleaned.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        // Trim
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }

    /// Calculate match confidence between a search result and the original song
    private func calculateMatchConfidence(
        searchResult: Any,
        originalSong: Song,
        searchResultTitle: String,
        searchResultArtist: String
    ) -> Double {
        let originalTitle = originalSong.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let originalArtist = originalSong.artist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let resultTitle = searchResultTitle.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let resultArtist = searchResultArtist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for exact matches first (highest priority)
        if resultTitle == originalTitle && resultArtist == originalArtist {
            return 1.0
        }

        // Exact title match with similar artist
        if resultTitle == originalTitle {
            let artistScore = calculateStringSimilarity(originalArtist, resultArtist)
            if artistScore >= 0.8 {
                return 0.95
            }
        }

        // Start with base confidence
        var confidence: Double = 0.0

        // Title matching (weighted heavily)
        let titleScore = calculateStringSimilarity(originalTitle, resultTitle)
        confidence += titleScore * 0.5

        // Artist matching (also important)
        let artistScore = calculateStringSimilarity(originalArtist, resultArtist)
        confidence += artistScore * 0.4

        // Penalties for variations
        if resultTitle.contains("live") && !originalTitle.contains("live") {
            confidence -= 0.15
        }
        if resultTitle.contains("remix") && !originalTitle.contains("remix") {
            confidence -= 0.15
        }
        if resultTitle.contains("karaoke") {
            confidence -= 0.4
        }
        if resultTitle.contains("tribute") {
            confidence -= 0.4
        }
        if resultTitle.contains("remastered") && !originalTitle.contains("remastered") {
            confidence -= 0.05
        }

        // Bonus for featured artists match
        if (originalArtist.contains("ft.") || originalArtist.contains("feat.")) &&
           (resultTitle.contains("feat.") || resultArtist.contains("&")) {
            confidence += 0.1
        }

        return min(max(confidence, 0.0), 1.0)
    }

    /// Calculate string similarity using simple comparison
    private func calculateStringSimilarity(_ str1: String, _ str2: String) -> Double {
        let s1 = str1.lowercased()
        let s2 = str2.lowercased()

        // Exact match
        if s1 == s2 {
            return 1.0
        }

        // Contains match
        if s1.contains(s2) || s2.contains(s1) {
            return 0.8
        }

        // Word overlap
        let words1 = Set(s1.components(separatedBy: .whitespaces))
        let words2 = Set(s2.components(separatedBy: .whitespaces))
        let intersection = words1.intersection(words2)

        if words1.isEmpty || words2.isEmpty {
            return 0.0
        }

        let overlap = Double(intersection.count) / Double(max(words1.count, words2.count))
        return overlap
    }

    /// Filter and sort search results by confidence
    private func filterAndSortResults(
        _ results: [Client.SongType],
        originalSong: Song,
        getTitleAndArtist: (Client.SongType) -> (String, String),
        getId: (Client.SongType) -> String,
        getPreviewURL: (Client.SongType) -> URL?
    ) -> [SearchResult] {
        let searchResults: [SearchResult] = results.compactMap { result in
            let (title, artist) = getTitleAndArtist(result)
            let id = getId(result)
            let previewURL = getPreviewURL(result)

            let confidence = calculateMatchConfidence(
                searchResult: result,
                originalSong: originalSong,
                searchResultTitle: title,
                searchResultArtist: artist
            )

            // Create a new Song with normalized data from search result
            let song = Song(
                title: title,
                artist: artist,
                appleID: id,
                confidence: confidence
            )

            return SearchResult(
                song: song,
                matchConfidence: confidence,
                appleMusicID: id,
                previewURL: previewURL
            )
        }

        // Sort by confidence descending
        return searchResults.sorted { $0.matchConfidence > $1.matchConfidence }
    }

    /// Perform search with the musicKitClient
    private func performSearch(for song: Song) async throws -> [SearchResult] {
        // Check authorization
        guard musicKitClient.isAuthorized else {
            throw MusicSearchError.authenticationRequired
        }

        // Try multiple query strategies
        let queryStrategies = generateQueryStrategies(for: song)
        var allResults: [Client.SongType] = []
        var lastError: Error?

        for query in queryStrategies {
            do {
                let results = try await musicKitClient.search(term: query)
                allResults.append(contentsOf: results)
                // If we have results, we can stop trying other strategies
                if !allResults.isEmpty {
                    break
                }
            } catch let error as MusicSearchError {
                // Propagate specific search errors immediately (network, rate limit, etc.)
                throw error
            } catch {
                // Store the error and continue to next strategy
                lastError = error
                continue
            }
        }

        // Check if we have any results
        guard !allResults.isEmpty else {
            throw MusicSearchError.noResultsFound("\(song.title) by \(song.artist)")
        }

        // Filter and sort results using the protocol
        let filteredResults = filterAndSortResults(
            allResults,
            originalSong: song,
            getTitleAndArtist: { result in
                return (result.title, result.artistName)
            },
            getId: { result in
                result.id
            },
            getPreviewURL: { result in
                result.previewURL
            }
        )

        return filteredResults
    }
}

// MARK: - MusicSearcher Protocol Conformance

@available(macOS 12.0, *)
extension AppleMusicSearchService: MusicSearcher {

    /// Search Apple Music for a single song
    func search(for song: Song) async throws -> [SearchResult] {
        do {
            return try await performSearch(for: song)
        } catch let error as MusicSearchError {
            throw error
        } catch {
            throw MusicSearchError.searchFailed(error.localizedDescription)
        }
    }

    /// Search Apple Music for multiple songs in batch
    func searchBatch(_ songs: [Song]) async throws -> [Song: [SearchResult]] {
        var results: [Song: [SearchResult]] = [:]

        for (index, song) in songs.enumerated() {
            do {
                let searchResults = try await search(for: song)
                results[song] = searchResults
            } catch {
                // On failure, return empty array for this song
                results[song] = []
            }

            // Rate limiting delay between requests (skip after last request)
            if index < songs.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(rateLimitDelay * 1_000_000_000))
            }
        }

        return results
    }

    /// Get the best match for a song (highest confidence above minimum threshold)
    func getTopMatch(for song: Song) async throws -> SearchResult? {
        let results = try await search(for: song)
        return results.first { $0.matchConfidence >= minimumConfidence }
    }
}
