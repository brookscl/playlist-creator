import Foundation
import MusicKit

protocol PlaylistCreator {
    func createPlaylist(name: String, songs: [MatchedSong]) async throws -> CreatedPlaylist
    func addSongs(to playlistID: String, songs: [MatchedSong]) async throws
    func deletePlaylist(_ playlistID: String) async throws
}

struct CreatedPlaylist: Equatable {
    let id: String
    let name: String
    let songCount: Int
    let url: URL?
    
    init(id: String, name: String, songCount: Int, url: URL? = nil) {
        self.id = id
        self.name = name
        self.songCount = songCount
        self.url = url
    }
}

class DefaultPlaylistCreator: PlaylistCreator {
    func createPlaylist(name: String, songs: [MatchedSong]) async throws -> CreatedPlaylist {
        throw PlaylistCreationError.notImplemented
    }
    
    func addSongs(to playlistID: String, songs: [MatchedSong]) async throws {
        throw PlaylistCreationError.notImplemented
    }
    
    func deletePlaylist(_ playlistID: String) async throws {
        throw PlaylistCreationError.notImplemented
    }
}
