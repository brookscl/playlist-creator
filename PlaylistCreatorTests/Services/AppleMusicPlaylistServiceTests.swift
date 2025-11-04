import XCTest
@testable import PlaylistCreator
import MusicKit

@available(macOS 12.0, *)
final class AppleMusicPlaylistServiceTests: XCTestCase {
    var service: AppleMusicPlaylistService!
    var mockMusicKitWrapper: MockMusicKitWrapper!

    override func setUp() {
        super.setUp()
        mockMusicKitWrapper = MockMusicKitWrapper()
        service = AppleMusicPlaylistService(musicKitWrapper: mockMusicKitWrapper)
    }

    override func tearDown() {
        service = nil
        mockMusicKitWrapper = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testAuthorizationSuccess() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized

        let isAuthorized = try await service.requestAuthorization()

        XCTAssertTrue(isAuthorized)
        XCTAssertTrue(mockMusicKitWrapper.requestAuthorizationCalled)
    }

    func testAuthorizationDenied() async throws {
        mockMusicKitWrapper.authorizationStatus = .denied

        let isAuthorized = try await service.requestAuthorization()

        XCTAssertFalse(isAuthorized)
        XCTAssertTrue(mockMusicKitWrapper.requestAuthorizationCalled)
    }

    func testAuthorizationNotDetermined() async throws {
        mockMusicKitWrapper.authorizationStatus = .notDetermined
        mockMusicKitWrapper.nextAuthorizationStatus = .authorized

        let isAuthorized = try await service.requestAuthorization()

        XCTAssertTrue(isAuthorized)
        XCTAssertTrue(mockMusicKitWrapper.requestAuthorizationCalled)
    }

    func testAuthorizationRestricted() async throws {
        mockMusicKitWrapper.authorizationStatus = .restricted

        do {
            _ = try await service.requestAuthorization()
            XCTFail("Expected authorization error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .insufficientPermissions)
        }
    }

    // MARK: - Playlist Creation Tests

    func testCreatePlaylistSuccess() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized

        let song1 = Song(title: "Song 1", artist: "Artist 1", appleID: "123")
        let song2 = Song(title: "Song 2", artist: "Artist 2", appleID: "456")
        let matchedSong1 = MatchedSong(originalSong: song1, appleMusicSong: song1, matchStatus: .auto)
        let matchedSong2 = MatchedSong(originalSong: song2, appleMusicSong: song2, matchStatus: .selected)
        let songs = [matchedSong1, matchedSong2]

        mockMusicKitWrapper.createdPlaylistID = "pl.test123"
        mockMusicKitWrapper.createdPlaylistURL = URL(string: "https://music.apple.com/playlist/pl.test123")

        let result = try await service.createPlaylist(name: "Test Playlist", songs: songs)

        XCTAssertEqual(result.name, "Test Playlist")
        XCTAssertEqual(result.songCount, 2)
        XCTAssertEqual(result.id, "pl.test123")
        XCTAssertNotNil(result.url)
        XCTAssertTrue(mockMusicKitWrapper.createPlaylistCalled)
        XCTAssertEqual(mockMusicKitWrapper.lastPlaylistName, "Test Playlist")
    }

    func testCreatePlaylistWithEmptySongs() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.createdPlaylistID = "pl.empty"

        let result = try await service.createPlaylist(name: "Empty Playlist", songs: [])

        XCTAssertEqual(result.name, "Empty Playlist")
        XCTAssertEqual(result.songCount, 0)
        XCTAssertTrue(mockMusicKitWrapper.createPlaylistCalled)
    }

    func testCreatePlaylistWithoutAuthorization() async throws {
        mockMusicKitWrapper.authorizationStatus = .denied

        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]

        do {
            _ = try await service.createPlaylist(name: "Test", songs: songs)
            XCTFail("Expected authorization error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .authenticationRequired)
        }
    }

    func testCreatePlaylistFailure() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.shouldThrowError = true
        mockMusicKitWrapper.errorToThrow = PlaylistCreationError.creationFailed("Network error")

        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]

        do {
            _ = try await service.createPlaylist(name: "Test", songs: songs)
            XCTFail("Expected creation error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .creationFailed("Network error"))
        }
    }

    // MARK: - Song Addition Tests

    func testAddSongsSuccess() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.createdPlaylistID = "pl.test"

        // First create a playlist
        let initialPlaylist = try await service.createPlaylist(name: "Test", songs: [])

        // Then add songs
        let songs = [
            MatchedSong(
                originalSong: Song(title: "Song 1", artist: "Artist 1"),
                appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "1"),
                matchStatus: .auto
            ),
            MatchedSong(
                originalSong: Song(title: "Song 2", artist: "Artist 2"),
                appleMusicSong: Song(title: "Song 2", artist: "Artist 2", appleID: "2"),
                matchStatus: .selected
            )
        ]

        try await service.addSongs(to: initialPlaylist.id, songs: songs)

        XCTAssertTrue(mockMusicKitWrapper.addSongsCalled)
        XCTAssertEqual(mockMusicKitWrapper.lastAddedSongIDs.count, 2)
    }

    func testAddSongsWithoutAuthorization() async throws {
        mockMusicKitWrapper.authorizationStatus = .denied

        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]

        do {
            try await service.addSongs(to: "pl.test", songs: songs)
            XCTFail("Expected authorization error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .authenticationRequired)
        }
    }

    func testAddSongsFailure() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.shouldThrowError = true
        mockMusicKitWrapper.errorToThrow = PlaylistCreationError.songAdditionFailed("Failed to add songs")

        let songs = [MatchedSong(
            originalSong: Song(title: "Test", artist: "Artist"),
            appleMusicSong: Song(title: "Test", artist: "Artist", appleID: "test"),
            matchStatus: .auto
        )]

        do {
            try await service.addSongs(to: "pl.test", songs: songs)
            XCTFail("Expected song addition error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .songAdditionFailed("Failed to add songs"))
        }
    }

    func testAddSongsWithMissingAppleIDs() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized

        // Songs without Apple IDs should be filtered out
        let songs = [
            MatchedSong(
                originalSong: Song(title: "Song 1", artist: "Artist 1"),
                appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "valid1"),
                matchStatus: .auto
            ),
            MatchedSong(
                originalSong: Song(title: "Song 2", artist: "Artist 2"),
                appleMusicSong: Song(title: "Song 2", artist: "Artist 2", appleID: nil),
                matchStatus: .selected
            ),
            MatchedSong(
                originalSong: Song(title: "Song 3", artist: "Artist 3"),
                appleMusicSong: Song(title: "Song 3", artist: "Artist 3", appleID: "valid3"),
                matchStatus: .auto
            )
        ]

        try await service.addSongs(to: "pl.test", songs: songs)

        // Only songs with Apple IDs should be added
        XCTAssertEqual(mockMusicKitWrapper.lastAddedSongIDs.count, 2)
        XCTAssertTrue(mockMusicKitWrapper.lastAddedSongIDs.contains("valid1"))
        XCTAssertTrue(mockMusicKitWrapper.lastAddedSongIDs.contains("valid3"))
    }

    // MARK: - Delete Playlist Tests

    func testDeletePlaylistSuccess() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.createdPlaylistID = "pl.todelete"

        // Create a playlist first
        let playlist = try await service.createPlaylist(name: "To Delete", songs: [])

        // Delete it
        try await service.deletePlaylist(playlist.id)

        XCTAssertTrue(mockMusicKitWrapper.deletePlaylistCalled)
        XCTAssertEqual(mockMusicKitWrapper.lastDeletedPlaylistID, playlist.id)
    }

    func testDeletePlaylistWithoutAuthorization() async throws {
        mockMusicKitWrapper.authorizationStatus = .denied

        do {
            try await service.deletePlaylist("pl.test")
            XCTFail("Expected authorization error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .authenticationRequired)
        }
    }

    func testDeleteNonexistentPlaylist() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.shouldThrowError = true
        mockMusicKitWrapper.errorToThrow = PlaylistCreationError.playlistNotFound("pl.notfound")

        do {
            try await service.deletePlaylist("pl.notfound")
            XCTFail("Expected playlist not found error")
        } catch let error as PlaylistCreationError {
            XCTAssertEqual(error, .playlistNotFound("pl.notfound"))
        }
    }

    // MARK: - Playlist Description Generation Tests

    func testGeneratePlaylistDescription() {
        let songs = [
            MatchedSong(
                originalSong: Song(title: "Song 1", artist: "Artist 1"),
                appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "1"),
                matchStatus: .auto
            ),
            MatchedSong(
                originalSong: Song(title: "Song 2", artist: "Artist 2"),
                appleMusicSong: Song(title: "Song 2", artist: "Artist 2", appleID: "2"),
                matchStatus: .selected
            ),
            MatchedSong(
                originalSong: Song(title: "Song 3", artist: "Artist 3"),
                appleMusicSong: Song(title: "Song 3", artist: "Artist 3", appleID: "3"),
                matchStatus: .auto
            )
        ]

        let description = service.generatePlaylistDescription(songs: songs, sourceName: "Test Podcast")

        XCTAssertTrue(description.contains("3"))
        XCTAssertTrue(description.contains("Test Podcast"))
        XCTAssertFalse(description.isEmpty)
    }

    func testGeneratePlaylistDescriptionWithoutSourceName() {
        let songs = [
            MatchedSong(
                originalSong: Song(title: "Song 1", artist: "Artist 1"),
                appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "1"),
                matchStatus: .auto
            )
        ]

        let description = service.generatePlaylistDescription(songs: songs, sourceName: nil)

        XCTAssertTrue(description.contains("1"))
        XCTAssertFalse(description.isEmpty)
    }

    // MARK: - Integration Tests

    func testFullWorkflowCreateAndAddSongs() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.createdPlaylistID = "pl.workflow"

        // Create initial playlist with songs
        let initialSongs = [
            MatchedSong(
                originalSong: Song(title: "Song 1", artist: "Artist 1"),
                appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "1"),
                matchStatus: .auto
            )
        ]

        let playlist = try await service.createPlaylist(name: "Full Workflow", songs: initialSongs)

        // Add more songs
        let additionalSongs = [
            MatchedSong(
                originalSong: Song(title: "Song 2", artist: "Artist 2"),
                appleMusicSong: Song(title: "Song 2", artist: "Artist 2", appleID: "2"),
                matchStatus: .selected
            ),
            MatchedSong(
                originalSong: Song(title: "Song 3", artist: "Artist 3"),
                appleMusicSong: Song(title: "Song 3", artist: "Artist 3", appleID: "3"),
                matchStatus: .auto
            )
        ]

        try await service.addSongs(to: playlist.id, songs: additionalSongs)

        XCTAssertTrue(mockMusicKitWrapper.createPlaylistCalled)
        XCTAssertTrue(mockMusicKitWrapper.addSongsCalled)
        XCTAssertEqual(mockMusicKitWrapper.lastAddedSongIDs.count, 2)
    }

    func testChronologicalOrderPreserved() async throws {
        mockMusicKitWrapper.authorizationStatus = .authorized
        mockMusicKitWrapper.createdPlaylistID = "pl.chrono"

        // Songs with specific order
        let songs = [
            MatchedSong(
                originalSong: Song(title: "First", artist: "Artist"),
                appleMusicSong: Song(title: "First", artist: "Artist", appleID: "first"),
                matchStatus: .auto
            ),
            MatchedSong(
                originalSong: Song(title: "Second", artist: "Artist"),
                appleMusicSong: Song(title: "Second", artist: "Artist", appleID: "second"),
                matchStatus: .auto
            ),
            MatchedSong(
                originalSong: Song(title: "Third", artist: "Artist"),
                appleMusicSong: Song(title: "Third", artist: "Artist", appleID: "third"),
                matchStatus: .auto
            )
        ]

        _ = try await service.createPlaylist(name: "Chronological", songs: songs)

        // Verify order is preserved
        XCTAssertEqual(mockMusicKitWrapper.lastAddedSongIDs[0], "first")
        XCTAssertEqual(mockMusicKitWrapper.lastAddedSongIDs[1], "second")
        XCTAssertEqual(mockMusicKitWrapper.lastAddedSongIDs[2], "third")
    }
}

// MARK: - Mock MusicKit Wrapper

class MockMusicKitWrapper: MusicKitWrapperProtocol {
    var authorizationStatus: MusicAuthorization.Status = .notDetermined
    var nextAuthorizationStatus: MusicAuthorization.Status?
    var requestAuthorizationCalled = false
    var createPlaylistCalled = false
    var addSongsCalled = false
    var deletePlaylistCalled = false
    var shouldThrowError = false
    var errorToThrow: Error?

    var createdPlaylistID: String = "pl.mock123"
    var createdPlaylistURL: URL?
    var lastPlaylistName: String?
    var lastPlaylistDescription: String?
    var lastAddedSongIDs: [String] = []
    var lastDeletedPlaylistID: String?
    var userToken: String? = "mock.user.token"

    var currentAuthorizationStatus: MusicAuthorization.Status {
        return authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCalled = true

        if authorizationStatus == .restricted {
            throw PlaylistCreationError.insufficientPermissions
        }

        if let nextStatus = nextAuthorizationStatus {
            authorizationStatus = nextStatus
        }

        return authorizationStatus == .authorized
    }

    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws -> (id: String, url: URL?) {
        createPlaylistCalled = true
        lastPlaylistName = name
        lastPlaylistDescription = description
        lastAddedSongIDs = songIDs

        if shouldThrowError {
            throw errorToThrow ?? PlaylistCreationError.creationFailed("Mock error")
        }

        return (createdPlaylistID, createdPlaylistURL)
    }

    func addSongs(to playlistID: String, songIDs: [String]) async throws {
        addSongsCalled = true
        lastAddedSongIDs = songIDs

        if shouldThrowError {
            throw errorToThrow ?? PlaylistCreationError.songAdditionFailed("Mock error")
        }
    }

    func deletePlaylist(_ playlistID: String) async throws {
        deletePlaylistCalled = true
        lastDeletedPlaylistID = playlistID

        if shouldThrowError {
            throw errorToThrow ?? PlaylistCreationError.playlistNotFound(playlistID)
        }
    }
}
