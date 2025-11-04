import Foundation
import MusicKit

/// Wrapper around Apple's native MusicKit Song type to conform to our protocol
@available(macOS 12.0, *)
struct MusicKitSongWrapper: MusicKitSongProtocol {
    let song: MusicKit.Song

    var id: String {
        song.id.rawValue
    }

    var title: String {
        song.title
    }

    var artistName: String {
        song.artistName
    }

    var previewURL: URL? {
        song.previewAssets?.first?.url
    }
}

/// Production MusicKit client that uses Apple's MusicKit framework
@available(macOS 12.0, *)
class RealMusicKitClient: MusicKitClientProtocol {
    typealias SongType = MusicKitSongWrapper

    var isAuthorized: Bool {
        MusicAuthorization.currentStatus == .authorized
    }

    func requestAuthorization() async throws {
        let status = await MusicAuthorization.request()

        switch status {
        case .authorized:
            return
        case .denied, .restricted:
            throw MusicSearchError.authenticationRequired
        case .notDetermined:
            throw MusicSearchError.authenticationRequired
        @unknown default:
            throw MusicSearchError.authenticationRequired
        }
    }

    func search(term: String) async throws -> [MusicKitSongWrapper] {
        print("🎵 RealMusicKitClient.search() called with term: '\(term)'")

        // Check if authorized
        print("🎵 Checking authorization status: \(MusicAuthorization.currentStatus)")
        guard isAuthorized else {
            print("❌ Not authorized!")
            throw MusicSearchError.authenticationRequired
        }
        print("✅ Authorization confirmed")

        // Perform the search using MusicKit
        var searchRequest = MusicCatalogSearchRequest(term: term, types: [MusicKit.Song.self])
        searchRequest.limit = 25 // Get up to 25 results
        print("🎵 Creating search request with limit: 25")

        do {
            print("🎵 Executing search request...")
            let response = try await searchRequest.response()
            print("✅ Got response with \(response.songs.count) songs")

            // Extract songs from response and wrap them
            let songs = response.songs.map { MusicKitSongWrapper(song: $0) }

            // Log first few results
            for (index, song) in songs.prefix(3).enumerated() {
                print("  [\(index)] \(song.title) by \(song.artistName)")
            }

            return songs
        } catch {
            // Map MusicKit errors to our error types
            print("❌ Search failed with error: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Localized: \(error.localizedDescription)")
            throw MusicSearchError.searchFailed(error.localizedDescription)
        }
    }
}
