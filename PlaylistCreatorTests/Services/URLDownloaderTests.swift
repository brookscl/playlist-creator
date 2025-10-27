import XCTest
@testable import PlaylistCreator

final class URLDownloaderTests: XCTestCase {
    var downloader: URLDownloader!
    var tempDirectoryURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
        downloader = URLDownloader()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        downloader = nil
        tempDirectoryURL = nil
        super.tearDown()
    }

    // MARK: - Download Progress Tests

    func testProgressCallbackInvoked() async throws {
        var progressUpdates: [Double] = []

        downloader.progressCallback = { progress in
            progressUpdates.append(progress)
        }

        // Simulate progress updates
        downloader.updateProgress(0.0)
        downloader.updateProgress(0.5)
        downloader.updateProgress(1.0)

        XCTAssertEqual(progressUpdates, [0.0, 0.5, 1.0])
    }

    func testProgressBounds() {
        var lastProgress: Double = -1.0

        downloader.progressCallback = { progress in
            lastProgress = progress
        }

        downloader.updateProgress(-0.1) // Should clamp to 0.0
        XCTAssertEqual(lastProgress, 0.0)

        downloader.updateProgress(1.5) // Should clamp to 1.0
        XCTAssertEqual(lastProgress, 1.0)
    }

    // MARK: - Error Handling Tests

    func testInvalidURLError() async {
        let invalidURL = URL(string: "not-a-valid-url")!

        do {
            _ = try await downloader.download(from: invalidURL)
            XCTFail("Should throw error for invalid URL")
        } catch let error as AudioProcessingError {
            XCTAssertEqual(error, .extractionFailed("Invalid URL"))
        } catch {
            XCTFail("Wrong error type thrown")
        }
    }

    func testNetworkErrorHandling() async {
        let unreachableURL = URL(string: "https://this-domain-does-not-exist-12345.com/file.mp3")!

        do {
            _ = try await downloader.download(from: unreachableURL)
            XCTFail("Should throw error for unreachable URL")
        } catch let error as AudioProcessingError {
            // Should fail with network error
            switch error {
            case .extractionFailed:
                XCTAssertTrue(true) // Expected
            default:
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type thrown")
        }
    }

    // MARK: - Cleanup Tests

    func testCleanupDownloadedFile() throws {
        let testFile = tempDirectoryURL.appendingPathComponent("test.mp3")
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        downloader.cleanup(fileAt: testFile)

        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile.path))
    }

    func testCleanupNonexistentFile() {
        let nonexistentFile = tempDirectoryURL.appendingPathComponent("nonexistent.mp3")

        // Should not throw
        downloader.cleanup(fileAt: nonexistentFile)

        XCTAssertTrue(true) // Test passes if no crash
    }

    // MARK: - File Type Detection Tests

    func testDetectAudioFileType() {
        let audioURL = URL(string: "https://example.com/file.mp3")!
        let type = downloader.detectFileType(from: audioURL)

        XCTAssertEqual(type, .directAudio)
    }

    func testDetectVideoFileType() {
        let videoURL = URL(string: "https://example.com/file.mp4")!
        let type = downloader.detectFileType(from: videoURL)

        XCTAssertEqual(type, .directVideo)
    }

    func testDetectYouTubeURL() {
        let youtubeURL = URL(string: "https://www.youtube.com/watch?v=test")!
        let type = downloader.detectFileType(from: youtubeURL)

        XCTAssertEqual(type, .youtube)
    }

    // MARK: - Download Configuration Tests

    func testDefaultTimeout() {
        XCTAssertEqual(downloader.timeoutInterval, 300.0) // 5 minutes default
    }

    func testCustomTimeout() {
        let customDownloader = URLDownloader(timeoutInterval: 60.0)
        XCTAssertEqual(customDownloader.timeoutInterval, 60.0)
    }

    // MARK: - Integration Tests

    func testDownloadStateTracking() async {
        let testURL = URL(string: "https://example.com/test.mp3")!

        XCTAssertFalse(downloader.isDownloading)

        // Note: This test would need actual download implementation
        // For now, we're just testing the state tracking mechanism
    }
}
