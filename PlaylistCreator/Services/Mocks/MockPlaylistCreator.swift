import Foundation

class MockPlaylistCreator: PlaylistCreator {
    var shouldThrowError = false
    var createPlaylistResult: CreatedPlaylist?
    var createdPlaylists: [String: CreatedPlaylist] = [:]
    
    func createPlaylist(name: String, songs: [MatchedSong]) async throws -> CreatedPlaylist {
        if shouldThrowError {
            throw PlaylistCreationError.creationFailed("Mock error")
        }
        
        let playlist = createPlaylistResult ?? CreatedPlaylist(
            id: "mock_playlist_\(UUID().uuidString)",
            name: name,
            songCount: songs.count,
            url: URL(string: "https://music.apple.com/playlist/\(UUID().uuidString)")
        )
        
        createdPlaylists[playlist.id] = playlist
        return playlist
    }
    
    func addSongs(to playlistID: String, songs: [MatchedSong]) async throws {
        if shouldThrowError {
            throw PlaylistCreationError.songAdditionFailed("Mock error")
        }
        
        guard var playlist = createdPlaylists[playlistID] else {
            throw PlaylistCreationError.playlistNotFound(playlistID)
        }
        
        playlist = CreatedPlaylist(
            id: playlist.id,
            name: playlist.name,
            songCount: playlist.songCount + songs.count,
            url: playlist.url
        )
        
        createdPlaylists[playlistID] = playlist
    }
    
    func deletePlaylist(_ playlistID: String) async throws {
        if shouldThrowError {
            throw PlaylistCreationError.playlistNotFound(playlistID)
        }
        
        createdPlaylists.removeValue(forKey: playlistID)
    }
}
