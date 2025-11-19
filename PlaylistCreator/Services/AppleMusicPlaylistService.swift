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

// MARK: - Real MusicKit Wrapper (iOS)

/// Real MusicKit implementation for iOS/iPadOS
/// Uses MusicLibrary.shared APIs which are available on iOS
/// Relies on user's Apple Music subscription for authorization (no developer token needed)
@available(iOS 17.0, *)
class RealMusicKitWrapper: MusicKitWrapperProtocol {

    init() {
        print("✅ MusicKit wrapper initialized (using user subscription authentication)")
    }

    var currentAuthorizationStatus: MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }

    var userToken: String? {
        // Not needed for native iOS apps - user's Apple Music subscription provides auth
        return nil
    }

    func requestAuthorization() async throws -> Bool {
        let status = await MusicAuthorization.request()

        if status == .authorized {
            print("✅ User authorized Apple Music access")
        } else {
            print("⚠️ User denied Apple Music access")
        }

        return status == .authorized
    }

    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws -> (id: String, url: URL?) {
        print("📝 Creating playlist '\(name)' using user's Apple Music subscription")
        print("   Songs to add: \(songIDs.count)")

        // Convert song IDs to MusicItemID
        let musicItemIDs = songIDs.compactMap { MusicItemID($0) }

        guard !musicItemIDs.isEmpty else {
            throw PlaylistCreationError.creationFailed("No valid song IDs provided")
        }

        do {
            // Fetch songs from catalog using user's subscription
            var request = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, memberOf: musicItemIDs)
            request.limit = musicItemIDs.count

            print("🔍 Fetching \(musicItemIDs.count) songs from Apple Music catalog using user subscription...")
            let response = try await request.response()
            let songs = Array(response.items)

            print("✅ Found \(songs.count) songs in Apple Music catalog")

            if songs.count < musicItemIDs.count {
                print("⚠️ Warning: Only found \(songs.count) of \(musicItemIDs.count) requested songs")
                let foundIDs = songs.map { $0.id.rawValue }
                let missingIDs = musicItemIDs.map { $0.rawValue }.filter { !foundIDs.contains($0) }
                print("   Missing songs: \(missingIDs)")
            }

            guard !songs.isEmpty else {
                throw PlaylistCreationError.creationFailed("None of the requested songs were found in Apple Music catalog")
            }

            // Create playlist with songs in user's library
            print("📝 Creating playlist in user's library...")
            let playlist = try await MusicLibrary.shared.createPlaylist(
                name: name,
                description: description,
                items: songs
            )

            print("✅ Playlist created successfully")
            print("   ID: \(playlist.id)")
            print("   Name: \(playlist.name)")

            // Get playlist URL
            let urlString = "https://music.apple.com/library/playlist/\(playlist.id)"
            let url = URL(string: urlString)

            return (playlist.id.rawValue, url)

        } catch {
            print("❌ Failed to create playlist: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Description: \(error.localizedDescription)")

            // Provide more specific error messages
            if error.localizedDescription.contains("authorization") || error.localizedDescription.contains("not authorized") {
                throw PlaylistCreationError.authenticationRequired
            } else if error.localizedDescription.contains("subscription") {
                throw PlaylistCreationError.creationFailed("Apple Music subscription required. Please ensure you're signed in with an active Apple Music subscription.")
            } else {
                throw PlaylistCreationError.creationFailed(error.localizedDescription)
            }
        }
    }

    func addSongs(to playlistID: String, songIDs: [String]) async throws {
        // TODO: Implement song addition to existing playlists
        // MusicLibrary API for modifying existing playlists is limited
        throw PlaylistCreationError.songAdditionFailed("Adding songs to existing playlists not yet implemented")
    }

    func deletePlaylist(_ playlistID: String) async throws {
        // TODO: Implement playlist deletion
        // MusicLibrary API for deleting playlists is limited
        throw PlaylistCreationError.playlistNotFound(playlistID)
    }
}
