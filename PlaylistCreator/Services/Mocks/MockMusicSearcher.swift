import Foundation

class MockMusicSearcher: MusicSearcher {
    var shouldThrowError = false
    var searchResult: [SearchResult]?
    var searchBatchResult: [Song: [SearchResult]]?
    var getTopMatchResult: SearchResult?
    
    func search(for song: Song) async throws -> [SearchResult] {
        if shouldThrowError {
            throw MusicSearchError.searchFailed("Mock error")
        }
        return searchResult ?? [
            SearchResult(
                song: Song(title: song.title, artist: song.artist, appleID: "12345"),
                matchConfidence: 0.95,
                appleMusicID: "12345",
                previewURL: URL(string: "https://example.com/preview1.m4a")
            ),
            SearchResult(
                song: Song(title: "Similar \(song.title)", artist: song.artist, appleID: "67890"),
                matchConfidence: 0.75,
                appleMusicID: "67890",
                previewURL: URL(string: "https://example.com/preview2.m4a")
            )
        ]
    }
    
    func searchBatch(_ songs: [Song]) async throws -> [Song: [SearchResult]] {
        if shouldThrowError {
            throw MusicSearchError.rateLimitExceeded
        }
        if let batchResult = searchBatchResult {
            return batchResult
        }
        
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
        if shouldThrowError {
            throw MusicSearchError.noResultsFound("\(song.title) by \(song.artist)")
        }
        return getTopMatchResult ?? SearchResult(
            song: Song(title: song.title, artist: song.artist, appleID: "top123"),
            matchConfidence: 0.9,
            appleMusicID: "top123",
            previewURL: URL(string: "https://example.com/top_preview.m4a")
        )
    }
}
