import XCTest
import AVFoundation
@testable import PlaylistCreator

/// Tests for PreviewPlayer protocol and implementations
@MainActor
final class PreviewPlayerTests: XCTestCase {

    // MARK: - Mock Implementation

    class MockPreviewPlayer: PreviewPlayer {
        var isPlaying: Bool = false
        var currentTime: TimeInterval = 0
        var duration: TimeInterval = 30
        var volume: Float = 1.0

        var playCallCount = 0
        var pauseCallCount = 0
        var stopCallCount = 0
        var seekCallCount = 0

        var shouldFailPlay = false
        var playError: PreviewPlayerError?

        var lastPlayedURL: URL?
        var lastSeekTime: TimeInterval?

        func play(previewURL: URL) async throws {
            playCallCount += 1
            lastPlayedURL = previewURL

            if shouldFailPlay {
                throw playError ?? PreviewPlayerError.invalidURL
            }

            isPlaying = true
            currentTime = 0
        }

        func pause() {
            pauseCallCount += 1
            isPlaying = false
        }

        func stop() {
            stopCallCount += 1
            isPlaying = false
            currentTime = 0
        }

        func seek(to time: TimeInterval) {
            seekCallCount += 1
            lastSeekTime = time
            currentTime = time
        }
    }

    // MARK: - Basic Functionality Tests

    func testInitialState() {
        let player = MockPreviewPlayer()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 0)
        XCTAssertEqual(player.duration, 30)
        XCTAssertEqual(player.volume, 1.0)
    }

    func testPlayStartsPlayback() async throws {
        let player = MockPreviewPlayer()
        let url = URL(string: "https://example.com/preview.m4a")!

        try await player.play(previewURL: url)

        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.playCallCount, 1)
        XCTAssertEqual(player.lastPlayedURL, url)
        XCTAssertEqual(player.currentTime, 0)
    }

    func testPauseStopsPlayback() async throws {
        let player = MockPreviewPlayer()
        let url = URL(string: "https://example.com/preview.m4a")!

        try await player.play(previewURL: url)
        XCTAssertTrue(player.isPlaying)

        player.pause()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 1)
    }

    func testStopResetsPlayback() async throws {
        let player = MockPreviewPlayer()
        let url = URL(string: "https://example.com/preview.m4a")!

        try await player.play(previewURL: url)
        player.currentTime = 15.0 // Simulate playback progress

        player.stop()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 0)
        XCTAssertEqual(player.stopCallCount, 1)
    }

    func testSeekUpdatesCurrentTime() {
        let player = MockPreviewPlayer()

        player.seek(to: 10.5)

        XCTAssertEqual(player.currentTime, 10.5)
        XCTAssertEqual(player.seekCallCount, 1)
        XCTAssertEqual(player.lastSeekTime, 10.5)
    }

    // MARK: - Error Handling Tests

    func testPlayWithInvalidURLThrowsError() async {
        let player = MockPreviewPlayer()
        player.shouldFailPlay = true
        player.playError = .invalidURL

        let url = URL(string: "https://example.com/preview.m4a")!

        do {
            try await player.play(previewURL: url)
            XCTFail("Expected invalidURL error")
        } catch let error as PreviewPlayerError {
            XCTAssertEqual(error, .invalidURL)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testPlayWithLoadFailureThrowsError() async {
        let player = MockPreviewPlayer()
        player.shouldFailPlay = true
        player.playError = .loadFailed

        let url = URL(string: "https://example.com/preview.m4a")!

        do {
            try await player.play(previewURL: url)
            XCTFail("Expected loadFailed error")
        } catch let error as PreviewPlayerError {
            XCTAssertEqual(error, .loadFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testPlayWithNetworkErrorThrowsError() async {
        let player = MockPreviewPlayer()
        player.shouldFailPlay = true
        player.playError = .networkError

        let url = URL(string: "https://example.com/preview.m4a")!

        do {
            try await player.play(previewURL: url)
            XCTFail("Expected networkError error")
        } catch let error as PreviewPlayerError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Playback State Tests

    func testMultiplePlayCallsReplaceCurrentTrack() async throws {
        let player = MockPreviewPlayer()
        let url1 = URL(string: "https://example.com/preview1.m4a")!
        let url2 = URL(string: "https://example.com/preview2.m4a")!

        try await player.play(previewURL: url1)
        XCTAssertEqual(player.lastPlayedURL, url1)

        try await player.play(previewURL: url2)
        XCTAssertEqual(player.lastPlayedURL, url2)
        XCTAssertEqual(player.playCallCount, 2)
    }

    func testPauseWhenNotPlayingIsNoop() {
        let player = MockPreviewPlayer()

        XCTAssertFalse(player.isPlaying)
        player.pause()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 1)
    }

    func testStopWhenNotPlayingIsNoop() {
        let player = MockPreviewPlayer()

        XCTAssertFalse(player.isPlaying)
        player.stop()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 0)
        XCTAssertEqual(player.stopCallCount, 1)
    }

    // MARK: - Volume Tests

    func testVolumeDefaultsToOne() {
        let player = MockPreviewPlayer()
        XCTAssertEqual(player.volume, 1.0)
    }

    func testVolumeCanBeChanged() {
        let player = MockPreviewPlayer()
        player.volume = 0.5
        XCTAssertEqual(player.volume, 0.5)
    }

    // MARK: - Duration Tests

    func testDurationDefaultsToThirtySeconds() {
        let player = MockPreviewPlayer()
        XCTAssertEqual(player.duration, 30)
    }

    func testDurationCanBeUpdated() {
        let player = MockPreviewPlayer()
        player.duration = 25.5
        XCTAssertEqual(player.duration, 25.5)
    }

    // MARK: - Current Time Tests

    func testCurrentTimeStartsAtZero() {
        let player = MockPreviewPlayer()
        XCTAssertEqual(player.currentTime, 0)
    }

    func testCurrentTimeResetsOnStop() async throws {
        let player = MockPreviewPlayer()
        let url = URL(string: "https://example.com/preview.m4a")!

        try await player.play(previewURL: url)
        player.currentTime = 15.0

        player.stop()

        XCTAssertEqual(player.currentTime, 0)
    }

    func testCurrentTimePreservedOnPause() async throws {
        let player = MockPreviewPlayer()
        let url = URL(string: "https://example.com/preview.m4a")!

        try await player.play(previewURL: url)
        player.currentTime = 15.0

        player.pause()

        XCTAssertEqual(player.currentTime, 15.0)
    }

    // MARK: - Seek Tests

    func testSeekToBeginning() {
        let player = MockPreviewPlayer()
        player.currentTime = 15.0

        player.seek(to: 0)

        XCTAssertEqual(player.currentTime, 0)
    }

    func testSeekToMiddle() {
        let player = MockPreviewPlayer()

        player.seek(to: 15.0)

        XCTAssertEqual(player.currentTime, 15.0)
    }

    func testSeekToEnd() {
        let player = MockPreviewPlayer()
        player.duration = 30

        player.seek(to: 30)

        XCTAssertEqual(player.currentTime, 30)
    }
}

// MARK: - PreviewPlayerError Tests

final class PreviewPlayerErrorTests: XCTestCase {

    func testErrorEquality() {
        XCTAssertEqual(PreviewPlayerError.invalidURL, PreviewPlayerError.invalidURL)
        XCTAssertEqual(PreviewPlayerError.loadFailed, PreviewPlayerError.loadFailed)
        XCTAssertEqual(PreviewPlayerError.networkError, PreviewPlayerError.networkError)
        XCTAssertEqual(PreviewPlayerError.playbackFailed, PreviewPlayerError.playbackFailed)
    }

    func testErrorInequality() {
        XCTAssertNotEqual(PreviewPlayerError.invalidURL, PreviewPlayerError.loadFailed)
        XCTAssertNotEqual(PreviewPlayerError.networkError, PreviewPlayerError.playbackFailed)
    }

    func testErrorDescriptions() {
        XCTAssertEqual(PreviewPlayerError.invalidURL.localizedDescription,
                      "Invalid preview URL")
        XCTAssertEqual(PreviewPlayerError.loadFailed.localizedDescription,
                      "Failed to load preview")
        XCTAssertEqual(PreviewPlayerError.networkError.localizedDescription,
                      "Network error while loading preview")
        XCTAssertEqual(PreviewPlayerError.playbackFailed.localizedDescription,
                      "Playback failed")
    }
}
