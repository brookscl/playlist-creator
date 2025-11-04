import Foundation
import MusicKit

// MARK: - MusicKit Wrapper Protocol

protocol MusicKitWrapperProtocol {
    func requestAuthorization() async throws -> Bool
    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws -> (id: String, url: URL?)
    func addSongs(to playlistID: String, songIDs: [String]) async throws
    func deletePlaylist(_ playlistID: String) async throws
    var currentAuthorizationStatus: MusicAuthorization.Status { get }
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

    /// Initialize with default real MusicKit implementation
    convenience init() {
        self.init(musicKitWrapper: RealMusicKitWrapper())
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
    var currentAuthorizationStatus: MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }

    func requestAuthorization() async throws -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }

    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws -> (id: String, url: URL?) {
        // Note: MusicKit's library playlist creation API is limited on macOS
        // This implementation requires Apple Music subscription and proper entitlements

        print("📝 Creating playlist '\(name)' with \(songIDs.count) songs")
        print("   Description: \(description ?? "none")")

        // For now, this is a placeholder implementation
        // Full implementation requires:
        // 1. Apple Music subscription check
        // 2. Proper entitlements in Info.plist
        // 3. iOS-style playlist creation APIs which may not be available on macOS

        // Return a mock response for now
        // TODO: Implement actual playlist creation when MusicKit library APIs are fully available
        throw PlaylistCreationError.creationFailed("Playlist creation via MusicKit is not yet fully implemented for macOS. Please use the iOS version or wait for full macOS support.")
    }

    func addSongs(to playlistID: String, songIDs: [String]) async throws {
        print("➕ Adding \(songIDs.count) songs to playlist \(playlistID)")

        // Placeholder - actual implementation requires MusicKit library APIs
        throw PlaylistCreationError.songAdditionFailed("Song addition via MusicKit is not yet fully implemented for macOS")
    }

    func deletePlaylist(_ playlistID: String) async throws {
        print("🗑️ Deleting playlist \(playlistID)")

        // Placeholder - actual implementation requires MusicKit library APIs
        throw PlaylistCreationError.playlistNotFound(playlistID)
    }
}
