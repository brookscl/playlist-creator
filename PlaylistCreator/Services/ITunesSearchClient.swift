import Foundation

/// Simple iTunes Search API client for finding songs
/// This doesn't require MusicKit registration and works immediately
class ITunesSearchClient {

    struct ITunesSearchResponse: Codable {
        let results: [ITunesTrack]
    }

    struct ITunesTrack: Codable {
        let trackId: Int
        let trackName: String
        let artistName: String
        let collectionName: String?
        let previewUrl: String?
        let trackViewUrl: String?

        var appleID: String {
            String(trackId)
        }
    }

    func search(term: String) async throws -> [ITunesTrack] {
        print("🎵 ITunesSearchClient.search() called with term: '\(term)'")

        // Build the search URL
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "25")
        ]

        guard let url = components.url else {
            print("❌ Failed to construct URL")
            throw MusicSearchError.searchFailed("Invalid search URL")
        }

        print("🎵 Requesting: \(url)")

        // Perform the request
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw MusicSearchError.searchFailed("Invalid response")
        }

        print("🎵 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP error: \(httpResponse.statusCode)")
            throw MusicSearchError.searchFailed("HTTP \(httpResponse.statusCode)")
        }

        // Decode the response
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(ITunesSearchResponse.self, from: data)

        print("✅ Found \(searchResponse.results.count) tracks")

        // Log first few results
        for (index, track) in searchResponse.results.prefix(3).enumerated() {
            print("  [\(index)] \(track.trackName) by \(track.artistName)")
        }

        return searchResponse.results
    }
}

/// Wrapper to conform to MusicKitSongProtocol
struct ITunesTrackWrapper: MusicKitSongProtocol {
    let track: ITunesSearchClient.ITunesTrack

    var id: String {
        track.appleID
    }

    var title: String {
        track.trackName
    }

    var artistName: String {
        track.artistName
    }

    var previewURL: URL? {
        if let urlString = track.previewUrl {
            return URL(string: urlString)
        }
        return nil
    }
}

/// Client that uses iTunes Search API instead of MusicKit
@available(macOS 12.0, *)
class ITunesMusicKitClient: MusicKitClientProtocol {
    typealias SongType = ITunesTrackWrapper

    private let searchClient = ITunesSearchClient()

    var isAuthorized: Bool {
        // iTunes Search API doesn't require authorization
        return true
    }

    func requestAuthorization() async throws {
        // No authorization needed for iTunes Search API
        print("✅ iTunes Search API - no authorization required")
    }

    func search(term: String) async throws -> [ITunesTrackWrapper] {
        let tracks = try await searchClient.search(term: term)
        return tracks.map { ITunesTrackWrapper(track: $0) }
    }
}
