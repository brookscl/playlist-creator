import Foundation
import MusicKit

// MARK: - MusicKit Wrapper Protocol

protocol MusicKitWrapperProtocol {
    func requestAuthorization() async throws -> Bool
    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws -> (id: String, url: URL?)
    func addSongs(to playlistID: String, songIDs: [String]) async throws
    func deletePlaylist(_ playlistID: String) async throws
    var currentAuthorizationStatus: MusicAuthorization.Status { get }
    var userToken: String? { get }
}

// MARK: - Apple Music Playlist Service

/// Service for creating and managing Apple Music playlists using MusicKit
///
/// This service handles:
/// - User authorization for Apple Music access
/// - Playlist creation with songs
/// - Adding songs to existing playlists
/// - Playlist deletion
/// - Metadata generation for playlist names and descriptions
@available(macOS 12.0, *)
class AppleMusicPlaylistService: PlaylistCreator {
    private let musicKitWrapper: MusicKitWrapperProtocol

    /// Initialize with a MusicKitWrapper (for dependency injection and testing)
    init(musicKitWrapper: MusicKitWrapperProtocol) {
        self.musicKitWrapper = musicKitWrapper
    }

    // MARK: - PlaylistCreator Protocol Implementation

    func createPlaylist(name: String, songs: [MatchedSong]) async throws -> CreatedPlaylist {
        // Ensure authorization
        let isAuthorized = try await requestAuthorization()
        guard isAuthorized else {
            throw PlaylistCreationError.authenticationRequired
        }

        // Filter songs with Apple IDs
        let validSongs = songs.filter { $0.appleMusicSong.appleID != nil }
        let songIDs = validSongs.compactMap { $0.appleMusicSong.appleID }

        // Generate description
        let description = generatePlaylistDescription(songs: songs, sourceName: nil)

        // Create playlist via MusicKit
        do {
            let (playlistID, playlistURL) = try await musicKitWrapper.createPlaylist(
                name: name,
                description: description,
                songIDs: songIDs
            )

            return CreatedPlaylist(
                id: playlistID,
                name: name,
                songCount: songIDs.count,
                url: playlistURL
            )
        } catch let error as PlaylistCreationError {
            throw error
        } catch {
            throw PlaylistCreationError.creationFailed(error.localizedDescription)
        }
    }

    func addSongs(to playlistID: String, songs: [MatchedSong]) async throws {
        // Ensure authorization
        let isAuthorized = try await requestAuthorization()
        guard isAuthorized else {
            throw PlaylistCreationError.authenticationRequired
        }

        // Filter songs with Apple IDs
        let songIDs = songs.compactMap { $0.appleMusicSong.appleID }

        guard !songIDs.isEmpty else {
            // Nothing to add
            return
        }

        // Add songs to playlist
        do {
            try await musicKitWrapper.addSongs(to: playlistID, songIDs: songIDs)
        } catch let error as PlaylistCreationError {
            throw error
        } catch {
            throw PlaylistCreationError.songAdditionFailed(error.localizedDescription)
        }
    }

    func deletePlaylist(_ playlistID: String) async throws {
        // Ensure authorization
        let isAuthorized = try await requestAuthorization()
        guard isAuthorized else {
            throw PlaylistCreationError.authenticationRequired
        }

        // Delete playlist
        do {
            try await musicKitWrapper.deletePlaylist(playlistID)
        } catch let error as PlaylistCreationError {
            throw error
        } catch {
            throw PlaylistCreationError.playlistNotFound(playlistID)
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let status = musicKitWrapper.currentAuthorizationStatus

        switch status {
        case .authorized:
            return true

        case .notDetermined:
            // Request authorization
            return try await musicKitWrapper.requestAuthorization()

        case .denied:
            return false

        case .restricted:
            throw PlaylistCreationError.insufficientPermissions

        @unknown default:
            return false
        }
    }

    // MARK: - Helper Methods

    /// Generate a descriptive text for the playlist
    func generatePlaylistDescription(songs: [MatchedSong], sourceName: String?) -> String {
        let songCount = songs.count
        let songWord = songCount == 1 ? "song" : "songs"

        if let source = sourceName {
            return "Playlist with \(songCount) \(songWord) from \(source). Created with Playlist Creator."
        } else {
            return "Playlist with \(songCount) \(songWord). Created with Playlist Creator."
        }
    }
}

// MARK: - Real MusicKit Wrapper

@available(macOS 12.0, *)
class RealMusicKitWrapper: MusicKitWrapperProtocol {
    private let apiClient: AppleMusicAPIClient

    init(apiClient: AppleMusicAPIClient) {
        self.apiClient = apiClient
    }

    var currentAuthorizationStatus: MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }

    var userToken: String? {
        // Get user token from MusicKit
        // Note: This property is synchronous, but getting the token requires async calls
        // The actual token retrieval is handled by apiClient.getUserToken() in async contexts
        // This property is primarily for the protocol conformance
        return nil
    }

    func requestAuthorization() async throws -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }

    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws -> (id: String, url: URL?) {
        print("📝 Creating playlist '\(name)' with \(songIDs.count) songs via Apple Music API")
        print("   Description: \(description ?? "none")")

        do {
            let result = try await apiClient.createPlaylist(
                name: name,
                description: description,
                songIDs: songIDs
            )

            print("✅ Playlist created: \(result.id)")
            if let url = result.url {
                print("   URL: \(url.absoluteString)")
            }

            return result
        } catch let error as AppleMusicAPIError {
            print("❌ API Error: \(error.localizedDescription)")
            throw convertAPIError(error)
        } catch {
            print("❌ Unexpected error: \(error)")
            throw PlaylistCreationError.creationFailed(error.localizedDescription)
        }
    }

    func addSongs(to playlistID: String, songIDs: [String]) async throws {
        print("➕ Adding \(songIDs.count) songs to playlist \(playlistID)")

        do {
            try await apiClient.addSongs(to: playlistID, songIDs: songIDs)
            print("✅ Songs added successfully")
        } catch let error as AppleMusicAPIError {
            print("❌ API Error: \(error.localizedDescription)")
            throw convertAPIError(error)
        } catch {
            print("❌ Unexpected error: \(error)")
            throw PlaylistCreationError.songAdditionFailed(error.localizedDescription)
        }
    }

    func deletePlaylist(_ playlistID: String) async throws {
        print("🗑️ Deleting playlist \(playlistID)")
        // Note: Deletion is not typically needed for this app
        // but we keep it for completeness
        throw PlaylistCreationError.playlistNotFound(playlistID)
    }

    // MARK: - Error Conversion

    private func convertAPIError(_ error: AppleMusicAPIError) -> PlaylistCreationError {
        switch error {
        case .notAuthorized, .unauthorized:
            return .authenticationRequired
        case .noUserToken:
            return .authenticationRequired
        case .rateLimitExceeded:
            return .creationFailed("Rate limit exceeded. Please try again later.")
        case .playlistNotFound:
            return .playlistNotFound("Playlist not found")
        case .networkError:
            return .creationFailed("Network error occurred")
        case .invalidURL, .invalidResponse:
            return .creationFailed("Invalid response from Apple Music")
        }
    }
}
