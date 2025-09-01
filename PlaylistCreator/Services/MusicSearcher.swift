import Foundation
import MusicKit

protocol MusicSearcher {
    func search(for song: Song) async throws -> [SearchResult]
    func searchBatch(_ songs: [Song]) async throws -> [Song: [SearchResult]]
    func getTopMatch(for song: Song) async throws -> SearchResult?
}

struct SearchResult: Equatable {
    let song: Song
    let matchConfidence: Double
    let appleMusicID: String
    let previewURL: URL?
    
    init(song: Song, matchConfidence: Double, appleMusicID: String, previewURL: URL? = nil) {
        self.song = song
        self.matchConfidence = matchConfidence
        self.appleMusicID = appleMusicID
        self.previewURL = previewURL
    }
}

class DefaultMusicSearcher: MusicSearcher {
    private let minimumConfidence: Double
    
    init(minimumConfidence: Double = 0.7) {
        self.minimumConfidence = minimumConfidence
    }
    
    func search(for song: Song) async throws -> [SearchResult] {
        throw MusicSearchError.notImplemented
    }
    
    func searchBatch(_ songs: [Song]) async throws -> [Song: [SearchResult]] {
        var results: [Song: [SearchResult]] = [:]
        
        for song in songs {
            do {
                let searchResults = try await search(for: song)
                results[song] = searchResults
            } catch {
                results[song] = []
            }
        }
        
        return results
    }
    
    func getTopMatch(for song: Song) async throws -> SearchResult? {
        let results = try await search(for: song)
        return results.first { $0.matchConfidence >= minimumConfidence }
    }
}
