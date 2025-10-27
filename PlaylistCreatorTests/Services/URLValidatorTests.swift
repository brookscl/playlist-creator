import XCTest
@testable import PlaylistCreator

final class URLValidatorTests: XCTestCase {
    var validator: URLValidator!

    override func setUp() {
        super.setUp()
        validator = URLValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - YouTube URL Validation Tests

    func testValidYouTubeStandardURL() {
        let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .youtube)
    }

    func testValidYouTubeShortenedURL() {
        let url = URL(string: "https://youtu.be/dQw4w9WgXcQ")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .youtube)
    }

    func testValidYouTubeWithTimestamp() {
        let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .youtube)
    }

    func testValidYouTubeMobileURL() {
        let url = URL(string: "https://m.youtube.com/watch?v=dQw4w9WgXcQ")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .youtube)
    }

    func testYouTubeURLWithoutProtocol() {
        let url = URL(string: "www.youtube.com/watch?v=dQw4w9WgXcQ")!
        let result = validator.validateURL(url)

        // Should still validate as YouTube
        XCTAssertEqual(result, .youtube)
    }

    // MARK: - Podcast/RSS URL Validation Tests

    func testValidPodcastRSSURL() {
        let url = URL(string: "https://feeds.example.com/podcast.rss")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .podcast)
    }

    func testValidPodcastXMLURL() {
        let url = URL(string: "https://feeds.example.com/podcast.xml")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .podcast)
    }

    // MARK: - Direct Audio URL Validation Tests

    func testValidDirectMP3URL() {
        let url = URL(string: "https://example.com/audio.mp3")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .directAudio)
    }

    func testValidDirectM4AURL() {
        let url = URL(string: "https://example.com/audio.m4a")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .directAudio)
    }

    func testValidDirectWAVURL() {
        let url = URL(string: "https://example.com/audio.wav")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .directAudio)
    }

    // MARK: - Direct Video URL Validation Tests

    func testValidDirectMP4URL() {
        let url = URL(string: "https://example.com/video.mp4")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .directVideo)
    }

    func testValidDirectMOVURL() {
        let url = URL(string: "https://example.com/video.mov")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .directVideo)
    }

    // MARK: - Invalid URL Tests

    func testInvalidURL() {
        let url = URL(string: "https://example.com/document.pdf")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .unsupported)
    }

    func testUnsupportedVideoSite() {
        let url = URL(string: "https://vimeo.com/123456789")!
        let result = validator.validateURL(url)

        XCTAssertEqual(result, .unsupported)
    }

    // MARK: - URL String Validation Tests

    func testIsValidURLString() {
        XCTAssertTrue(validator.isValidURLString("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
        XCTAssertTrue(validator.isValidURLString("https://example.com/audio.mp3"))
        XCTAssertTrue(validator.isValidURLString("http://feeds.example.com/podcast.rss"))
    }

    func testIsInvalidURLString() {
        XCTAssertFalse(validator.isValidURLString("not a url"))
        XCTAssertFalse(validator.isValidURLString(""))
        XCTAssertFalse(validator.isValidURLString("   "))
    }

    // MARK: - URL Normalization Tests

    func testNormalizeURLAddsHTTPS() {
        let normalized = validator.normalizeURLString("youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertTrue(normalized.hasPrefix("https://"))
    }

    func testNormalizeURLPreservesHTTPS() {
        let normalized = validator.normalizeURLString("https://youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertEqual(normalized, "https://youtube.com/watch?v=dQw4w9WgXcQ")
    }

    func testNormalizeURLTrimsWhitespace() {
        let normalized = validator.normalizeURLString("  https://youtube.com/watch?v=test  ")
        XCTAssertEqual(normalized, "https://youtube.com/watch?v=test")
    }

    // MARK: - Helper Method Tests

    func testExtractYouTubeVideoID() {
        let url1 = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        XCTAssertEqual(validator.extractYouTubeVideoID(from: url1), "dQw4w9WgXcQ")

        let url2 = URL(string: "https://youtu.be/dQw4w9WgXcQ")!
        XCTAssertEqual(validator.extractYouTubeVideoID(from: url2), "dQw4w9WgXcQ")

        let url3 = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s")!
        XCTAssertEqual(validator.extractYouTubeVideoID(from: url3), "dQw4w9WgXcQ")
    }

    func testExtractYouTubeVideoIDFromInvalidURL() {
        let url = URL(string: "https://example.com/video")!
        XCTAssertNil(validator.extractYouTubeVideoID(from: url))
    }
}
