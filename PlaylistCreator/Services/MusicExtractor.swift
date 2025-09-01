import Foundation

protocol MusicExtractor {
    func extractSongs(from transcript: Transcript) async throws -> [Song]
    func extractSongsWithContext(from transcript: Transcript) async throws -> [ExtractedSong]
}

struct ExtractedSong: Equatable {
    let song: Song
    let context: String
    let timestamp: TimeInterval?
    let extractionConfidence: Double
    
    init(song: Song, context: String, timestamp: TimeInterval? = nil, extractionConfidence: Double = 1.0) {
        self.song = song
        self.context = context
        self.timestamp = timestamp
        self.extractionConfidence = extractionConfidence
    }
}

class DefaultMusicExtractor: MusicExtractor {
    private let apiKey: String?
    private let model: String
    
    init(apiKey: String? = nil, model: String = "gpt-4") {
        self.apiKey = apiKey
        self.model = model
    }
    
    func extractSongs(from transcript: Transcript) async throws -> [Song] {
        let extractedSongs = try await extractSongsWithContext(from: transcript)
        return extractedSongs.map { $0.song }
    }
    
    func extractSongsWithContext(from transcript: Transcript) async throws -> [ExtractedSong] {
        throw MusicExtractionError.notImplemented
    }
}
