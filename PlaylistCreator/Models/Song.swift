import Foundation

/// Represents a song with metadata for playlist creation
/// 
/// Song is used throughout the application to represent music tracks from various sources:
/// - Original songs extracted from transcripts (without Apple ID)
/// - Apple Music catalog songs (with Apple ID)
/// - Matched songs with confidence scores
///
/// The confidence score represents how well a song matches search criteria or extraction accuracy.
struct Song: Codable, Equatable, Hashable {
    /// The title of the song
    let title: String
    
    /// The artist or performer of the song
    let artist: String
    
    /// Apple Music catalog identifier (nil for non-Apple Music songs)
    let appleID: String?
    
    /// Confidence score for matches or extractions (0.0 to 1.0, but validation is not enforced here)
    let confidence: Double
    
    /// Creates a new Song instance
    /// - Parameters:
    ///   - title: The song title
    ///   - artist: The song artist
    ///   - appleID: Optional Apple Music identifier
    ///   - confidence: Confidence score (defaults to 0.0)
    init(title: String, artist: String, appleID: String? = nil, confidence: Double = 0.0) {
        self.title = title
        self.artist = artist
        self.appleID = appleID
        self.confidence = confidence
    }
}

// MARK: - Hashable Implementation

extension Song {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(artist)
        hasher.combine(appleID)
        hasher.combine(confidence)
    }
}

// MARK: - CustomStringConvertible

extension Song: CustomStringConvertible {
    var description: String {
        return "\(artist) - \(title)"
    }
}