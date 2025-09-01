import XCTest
@testable import PlaylistCreator

final class PlaylistCreatorServiceTests: XCTestCase {
    var mockCreator: MockPlaylistCreator!
    
    override func setUp() {
        super.setUp()
        mockCreator = MockPlaylistCreator()
    }
    
    override func tearDown() {
        mockCreator = nil
        super.tearDown()
    }
    
    // MARK: - CreatedPlaylist Tests
    
    func testCreatedPlaylistInitialization() throws {
        let playlist = CreatedPlaylist(id: "test123", name: "Test Playlist", songCount: 5)
        
        XCTAssertEqual(playlist.id, "test123")
        XCTAssertEqual(playlist.name, "Test Playlist")
        XCTAssertEqual(playlist.songCount, 5)
        XCTAssertNil(playlist.url)
    }
    
    func testCreatedPlaylistWithURL() throws {
        let url = URL(string: "https://music.apple.com/playlist/123")!
        let playlist = CreatedPlaylist(id: "test456", name: "URL Playlist", songCount: 10, url: url)
        
        XCTAssertEqual(playlist.id, "test456")
        XCTAssertEqual(playlist.name, "URL Playlist")
        XCTAssertEqual(playlist.songCount, 10)
        XCTAssertEqual(playlist.url, url)
    }
    
    func testCreatedPlaylistEquality() throws {
        let url = URL(string: "https://music.apple.com/playlist/123")!
        let playlist1 = CreatedPlaylist(id: "same123", name: "Same Playlist", songCount: 3, url: url)
        let playlist2 = CreatedPlaylist(id: "same123", name: "Same Playlist", songCount: 3, url: url)
        
        XCTAssertEqual(playlist1, playlist2)
    }
    
    func testCreatedPlaylistInequality() throws {
        let playlist1 = CreatedPlaylist(id: "diff123", name: "Playlist 1", songCount: 3)
        let playlist2 = CreatedPlaylist(id: "diff456", name: "Playlist 2", songCount: 5)
        
        XCTAssertNotEqual(playlist1, playlist2)
    }
    
    // MARK: - Mock PlaylistCreator Tests
    
    func testMockCreatePlaylistSuccess() async throws {
        let song1 = Song(title: "Song 1", artist: "Artist 1", appleID: "123")
        let song2 = Song(title: "Song 2", artist: "Artist 2", appleID: "456")
        let matchedSong1 = MatchedSong(originalSong: song1, appleMusicSong: song1, matchStatus: .auto)
        let matchedSong2 = MatchedSong(originalSong: song2, appleMusicSong: song2, matchStatus: .selected)
        let songs = [matchedSong1, matchedSong2]
        
        let customPlaylist = CreatedPlaylist(
            id: "custom123",
            name: "Custom Playlist",
            songCount: 2,
            url: URL(string: "https://music.apple.com/custom123")
        )
        mockCreator.createPlaylistResult = customPlaylist
        
        let result = try await mockCreator.createPlaylist(name: "Custom Playlist", songs: songs)
        
        XCTAssertEqual(result, customPlaylist)
        XCTAssertEqual(mockCreator.createdPlaylists[result.id], customPlaylist)
    }
    
    func testMockCreatePlaylistFailure() async throws {
        let songs: [MatchedSong] = []
        mockCreator.shouldThrowError = true
        
        do {
            _ = try await mockCreator.createPlaylist(name: "Failed Playlist", songs: songs)
            XCTFail("Expected error to be thrown")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .creationFailed("Mock error"))
        }
    }
    
    func testMockAddSongsSuccess() async throws {
        // First create a playlist
        let initialSongs = [MatchedSong(
            originalSong: Song(title: "Initial", artist: "Artist"),
            appleMusicSong: Song(title: "Initial", artist: "Artist", appleID: "initial"),
            matchStatus: .auto
        )]
        let playlist = try await mockCreator.createPlaylist(name: "Test Playlist", songs: initialSongs)
        
        // Then add more songs
        let additionalSongs = [
            MatchedSong(
                originalSong: Song(title: "Additional 1", artist: "Artist 1"),
                appleMusicSong: Song(title: "Additional 1", artist: "Artist 1", appleID: "add1"),
                matchStatus: .selected
            ),
            MatchedSong(
                originalSong: Song(title: "Additional 2", artist: "Artist 2"),
                appleMusicSong: Song(title: "Additional 2", artist: "Artist 2", appleID: "add2"),
                matchStatus: .auto
            )
        ]
        
        try await mockCreator.addSongs(to: playlist.id, songs: additionalSongs)
        
        let updatedPlaylist = mockCreator.createdPlaylists[playlist.id]
        XCTAssertNotNil(updatedPlaylist)
        XCTAssertEqual(updatedPlaylist!.songCount, 3) // 1 initial + 2 additional
    }
    
    func testMockAddSongsToNonexistentPlaylist() async throws {
        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]
        
        do {
            try await mockCreator.addSongs(to: "nonexistent", songs: songs)
            XCTFail("Expected error to be thrown")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .playlistNotFound("nonexistent"))
        }
    }
    
    func testMockAddSongsFailure() async throws {
        // Create a playlist first
        let playlist = try await mockCreator.createPlaylist(name: "Test", songs: [])
        
        mockCreator.shouldThrowError = true
        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]
        
        do {
            try await mockCreator.addSongs(to: playlist.id, songs: songs)
            XCTFail("Expected error to be thrown")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .songAdditionFailed("Mock error"))
        }
    }
    
    func testMockDeletePlaylistSuccess() async throws {
        // Create a playlist first
        let playlist = try await mockCreator.createPlaylist(name: "To Delete", songs: [])
        XCTAssertNotNil(mockCreator.createdPlaylists[playlist.id])
        
        // Delete the playlist
        try await mockCreator.deletePlaylist(playlist.id)
        
        XCTAssertNil(mockCreator.createdPlaylists[playlist.id])
    }
    
    func testMockDeleteNonexistentPlaylist() async throws {
        mockCreator.shouldThrowError = true
        
        do {
            try await mockCreator.deletePlaylist("nonexistent")
            XCTFail("Expected error to be thrown")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .playlistNotFound("nonexistent"))
        }
    }
    
    func testMockDefaultBehavior() async throws {
        let song = Song(title: "Default Song", artist: "Default Artist")
        let matchedSong = MatchedSong(
            originalSong: song,
            appleMusicSong: Song(title: "Default Song", artist: "Default Artist", appleID: "default123"),
            matchStatus: .auto
        )
        let songs = [matchedSong]
        
        let result = try await mockCreator.createPlaylist(name: "Default Playlist", songs: songs)
        
        // Test default behavior when no custom result is set
        XCTAssertTrue(result.id.hasPrefix("mock_playlist_"))
        XCTAssertEqual(result.name, "Default Playlist")
        XCTAssertEqual(result.songCount, 1)
        XCTAssertNotNil(result.url)
        XCTAssertTrue(result.url!.absoluteString.contains("music.apple.com/playlist/"))
        
        // Verify playlist is stored in mock
        XCTAssertNotNil(mockCreator.createdPlaylists[result.id])
    }
    
    func testMockPlaylistManagement() async throws {
        // Create multiple playlists
        let playlist1 = try await mockCreator.createPlaylist(name: "Playlist 1", songs: [])
        let playlist2 = try await mockCreator.createPlaylist(name: "Playlist 2", songs: [])
        
        XCTAssertEqual(mockCreator.createdPlaylists.count, 2)
        
        // Add songs to first playlist
        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]
        try await mockCreator.addSongs(to: playlist1.id, songs: songs)
        
        let updatedPlaylist1 = mockCreator.createdPlaylists[playlist1.id]!
        XCTAssertEqual(updatedPlaylist1.songCount, 1)
        
        let unchangedPlaylist2 = mockCreator.createdPlaylists[playlist2.id]!
        XCTAssertEqual(unchangedPlaylist2.songCount, 0)
        
        // Delete one playlist
        try await mockCreator.deletePlaylist(playlist1.id)
        XCTAssertEqual(mockCreator.createdPlaylists.count, 1)
        XCTAssertNotNil(mockCreator.createdPlaylists[playlist2.id])
    }
    
    // MARK: - DefaultPlaylistCreator Tests
    
    func testDefaultPlaylistCreatorInitialization() throws {
        let creator = DefaultPlaylistCreator()
        XCTAssertNotNil(creator)
    }
    
    func testDefaultPlaylistCreatorNotImplemented() async throws {
        let creator = DefaultPlaylistCreator()
        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]
        
        do {
            _ = try await creator.createPlaylist(name: "Test", songs: songs)
            XCTFail("Expected notImplemented error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .notImplemented)
        }
        
        do {
            try await creator.addSongs(to: "test", songs: songs)
            XCTFail("Expected notImplemented error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .notImplemented)
        }
        
        do {
            try await creator.deletePlaylist("test")
            XCTFail("Expected notImplemented error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .notImplemented)
        }
    }
}
