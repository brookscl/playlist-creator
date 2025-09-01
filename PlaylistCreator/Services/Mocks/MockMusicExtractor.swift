import Foundation

class MockMusicExtractor: MusicExtractor {
    var shouldThrowError = false
    var extractSongsResult: [Song]?
    var extractSongsWithContextResult: [ExtractedSong]?
    
    func extractSongs(from transcript: Transcript) async throws -> [Song] {
        if shouldThrowError {
            throw MusicExtractionError.noSongsFound
        }
        return extractSongsResult ?? [
            Song(title: "Bohemian Rhapsody", artist: "Queen", confidence: 0.9),
            Song(title: "Stairway to Heaven", artist: "Led Zeppelin", confidence: 0.85),
            Song(title: "Hotel California", artist: "Eagles", confidence: 0.8)
        ]
    }
    
    func extractSongsWithContext(from transcript: Transcript) async throws -> [ExtractedSong] {
        if shouldThrowError {
            throw MusicExtractionError.parsingFailed("Mock error")
        }
        return extractSongsWithContextResult ?? [
            ExtractedSong(
                song: Song(title: "Bohemian Rhapsody", artist: "Queen", confidence: 0.9),
                context: "They mentioned Bohemian Rhapsody by Queen",
                timestamp: 45.0,
                extractionConfidence: 0.95
            ),
            ExtractedSong(
                song: Song(title: "Stairway to Heaven", artist: "Led Zeppelin", confidence: 0.85),
                context: "Playing Stairway to Heaven from Led Zeppelin",
                timestamp: 120.0,
                extractionConfidence: 0.9
            )
        ]
    }
}
