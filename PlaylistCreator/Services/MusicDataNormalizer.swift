import Foundation

/// Utility class for normalizing and cleaning music data (song titles, artist names)
class MusicDataNormalizer {

    // MARK: - Song Title Normalization

    /// Normalize a song title by cleaning formatting and standardizing capitalization
    func normalizeSongTitle(_ title: String) -> String {
        var normalized = title

        // Remove extra whitespace
        normalized = normalizeWhitespace(normalized)

        // Remove common artifacts
        normalized = removeCommonArtifacts(normalized)

        // Fix capitalization while preserving intentional lowercase (like "iNeed")
        normalized = fixCapitalization(normalized, isTitle: true)

        // Remove quotes if they wrap the entire title
        normalized = removeWrappingQuotes(normalized)

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Artist Name Normalization

    /// Normalize an artist name by cleaning formatting and standardizing capitalization
    func normalizeArtistName(_ artist: String) -> String {
        var normalized = artist

        // Remove extra whitespace
        normalized = normalizeWhitespace(normalized)

        // Remove common prefixes/suffixes
        normalized = removeArtistArtifacts(normalized)

        // Fix capitalization
        normalized = fixCapitalization(normalized, isTitle: false)

        // Handle special cases (e.g., "The Beatles" vs "Beatles, The")
        normalized = normalizeArtistFormat(normalized)

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Confidence Score Adjustment

    /// Adjust confidence score based on data quality indicators
    func adjustConfidence(_ baseConfidence: Double, title: String, artist: String) -> Double {
        var adjusted = baseConfidence

        // Penalize very short titles (likely incomplete)
        if title.count < 3 {
            adjusted *= 0.7
        }

        // Penalize very short artist names
        if artist.count < 2 {
            adjusted *= 0.7
        }

        // Penalize if contains uncertainty markers
        let uncertaintyMarkers = ["?", "[", "]", "unclear", "unknown"]
        for marker in uncertaintyMarkers {
            if title.localizedCaseInsensitiveContains(marker) ||
               artist.localizedCaseInsensitiveContains(marker) {
                adjusted *= 0.6
                break
            }
        }

        // Boost if both title and artist are well-formed
        if title.count >= 3 && artist.count >= 3 &&
           !title.contains("...") && !artist.contains("...") {
            adjusted = min(adjusted * 1.1, 1.0)
        }

        return max(0.0, min(1.0, adjusted))
    }

    // MARK: - Duplicate Detection

    /// Check if two songs are likely duplicates (same song, minor variations)
    func areLikelyDuplicates(_ song1: Song, _ song2: Song) -> Bool {
        let title1 = normalizeSongTitle(song1.title).lowercased()
        let title2 = normalizeSongTitle(song2.title).lowercased()
        let artist1 = normalizeArtistName(song1.artist).lowercased()
        let artist2 = normalizeArtistName(song2.artist).lowercased()

        // Exact match after normalization
        if title1 == title2 && artist1 == artist2 {
            return true
        }

        // Similar titles with same artist (handle typos/variations)
        if artist1 == artist2 && calculateSimilarity(title1, title2) > 0.85 {
            return true
        }

        // Handle common variations like "Song (Live)" vs "Song"
        let cleanTitle1 = removeParenthetical(title1)
        let cleanTitle2 = removeParenthetical(title2)
        if cleanTitle1 == cleanTitle2 && artist1 == artist2 {
            return true
        }

        return false
    }

    // MARK: - Private Helper Methods

    private func normalizeWhitespace(_ text: String) -> String {
        // Replace multiple spaces with single space
        var result = text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )

        // Remove leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    private func removeCommonArtifacts(_ text: String) -> String {
        var result = text

        // Remove common transcript artifacts
        let artifacts = [
            " - Official Video",
            " (Official Video)",
            " [Official Video]",
            " - Official Audio",
            " (Official Audio)",
            " - Lyrics",
            " (Lyrics)",
            " - Official Music Video"
        ]

        for artifact in artifacts {
            result = result.replacingOccurrences(
                of: artifact,
                with: "",
                options: .caseInsensitive
            )
        }

        return result
    }

    private func removeArtistArtifacts(_ text: String) -> String {
        var result = text

        // Remove common prefixes like "by ", "from "
        let prefixes = ["by ", "from ", "artist: ", "performed by "]
        for prefix in prefixes {
            if result.lowercased().hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
            }
        }

        return result
    }

    private func fixCapitalization(_ text: String, isTitle: Bool) -> String {
        // Don't modify if it looks intentionally styled (all caps, all lowercase with caps mid-word)
        if text == text.uppercased() && text.count > 3 {
            // ALL CAPS - convert to title case
            return text.capitalized
        }

        // If it's all lowercase and short, capitalize first letter
        if text == text.lowercased() && text.count <= 30 {
            return text.prefix(1).uppercased() + text.dropFirst()
        }

        // Otherwise preserve as-is (might be intentional like "iNeed" or "k.d. lang")
        return text
    }

    private func removeWrappingQuotes(_ text: String) -> String {
        var result = text

        // Remove quotes that wrap the entire string
        if (result.hasPrefix("\"") && result.hasSuffix("\"")) ||
           (result.hasPrefix("'") && result.hasSuffix("'")) ||
           (result.hasPrefix("\u{201C}") && result.hasSuffix("\u{201D}")) {
            result = String(result.dropFirst().dropLast())
        }

        return result
    }

    private func normalizeArtistFormat(_ artist: String) -> String {
        // Handle "Artist, The" -> "The Artist"
        if let commaIndex = artist.lastIndex(of: ","),
           artist.suffix(5).trimmingCharacters(in: .whitespaces).lowercased() == "the" {
            let mainPart = artist[..<commaIndex].trimmingCharacters(in: .whitespaces)
            return "The \(mainPart)"
        }

        return artist
    }

    private func removeParenthetical(_ text: String) -> String {
        // Remove content in parentheses or brackets
        var result = text
        result = result.replacingOccurrences(
            of: #"\s*\([^)]*\)\s*"#,
            with: " ",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"\s*\[[^\]]*\]\s*"#,
            with: " ",
            options: .regularExpression
        )
        return result.trimmingCharacters(in: .whitespaces)
    }

    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        // Simple Levenshtein distance-based similarity
        let distance = levenshteinDistance(str1, str2)
        let maxLength = max(str1.count, str2.count)

        guard maxLength > 0 else { return 1.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        let str1Count = str1Array.count
        let str2Count = str2Array.count

        var matrix = Array(repeating: Array(repeating: 0, count: str2Count + 1), count: str1Count + 1)

        for i in 0...str1Count {
            matrix[i][0] = i
        }

        for j in 0...str2Count {
            matrix[0][j] = j
        }

        for i in 1...str1Count {
            for j in 1...str2Count {
                let cost = str1Array[i - 1] == str2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost  // substitution
                )
            }
        }

        return matrix[str1Count][str2Count]
    }
}
