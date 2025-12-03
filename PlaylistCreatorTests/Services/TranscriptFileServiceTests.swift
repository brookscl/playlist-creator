import XCTest
@testable import PlaylistCreator

class TranscriptFileServiceTests: XCTestCase {

    var service: TranscriptFileService!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        service = TranscriptFileService()

        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TranscriptFileServiceTests")
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - File Format Detection Tests

    func testDetectsPlainTextFormat() {
        let url = tempDirectory.appendingPathComponent("transcript.txt")
        let format = service.detectFormat(from: url)
        XCTAssertEqual(format, .plainText)
    }

    func testDetectsJSONFormat() {
        let url = tempDirectory.appendingPathComponent("transcript.json")
        let format = service.detectFormat(from: url)
        XCTAssertEqual(format, .json)
    }

    func testDetectsSRTFormat() {
        let url = tempDirectory.appendingPathComponent("transcript.srt")
        let format = service.detectFormat(from: url)
        XCTAssertEqual(format, .srt)
    }

    func testDetectsVTTFormat() {
        let url = tempDirectory.appendingPathComponent("transcript.vtt")
        let format = service.detectFormat(from: url)
        XCTAssertEqual(format, .vtt)
    }

    func testDetectsUnsupportedFormat() {
        let url = tempDirectory.appendingPathComponent("transcript.pdf")
        let format = service.detectFormat(from: url)
        XCTAssertEqual(format, .unsupported)
    }

    // MARK: - Plain Text Parsing Tests

    func testParsesPlainTextFile() async throws {
        let content = "This is a test transcript. The host mentions several songs."
        let url = tempDirectory.appendingPathComponent("test.txt")
        try content.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.text, content)
        XCTAssertTrue(transcript.segments.isEmpty) // Plain text has no segments
        XCTAssertNil(transcript.language)
        XCTAssertEqual(transcript.confidence, 1.0)
    }

    func testHandlesEmptyPlainTextFile() async throws {
        let url = tempDirectory.appendingPathComponent("empty.txt")
        try "".write(to: url, atomically: true, encoding: .utf8)

        do {
            _ = try await service.loadTranscript(from: url)
            XCTFail("Should throw error for empty file")
        } catch TranscriptFileError.emptyFile {
            // Expected
        }
    }

    func testHandlesWhitespacePlainTextFile() async throws {
        let url = tempDirectory.appendingPathComponent("whitespace.txt")
        try "   \n\n   \t  ".write(to: url, atomically: true, encoding: .utf8)

        do {
            _ = try await service.loadTranscript(from: url)
            XCTFail("Should throw error for whitespace-only file")
        } catch TranscriptFileError.emptyFile {
            // Expected
        }
    }

    // MARK: - JSON Parsing Tests

    func testParsesJSONWithSegments() async throws {
        let json = """
        {
            "text": "Full transcript text here.",
            "segments": [
                {
                    "text": "First segment",
                    "startTime": 0.0,
                    "endTime": 5.0,
                    "confidence": 0.95
                },
                {
                    "text": "Second segment",
                    "startTime": 5.0,
                    "endTime": 10.0,
                    "confidence": 0.98
                }
            ],
            "language": "en",
            "confidence": 0.96
        }
        """

        let url = tempDirectory.appendingPathComponent("test.json")
        try json.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.text, "Full transcript text here.")
        XCTAssertEqual(transcript.segments.count, 2)
        XCTAssertEqual(transcript.segments[0].text, "First segment")
        XCTAssertEqual(transcript.segments[0].startTime, 0.0)
        XCTAssertEqual(transcript.segments[0].endTime, 5.0)
        XCTAssertEqual(transcript.segments[0].confidence, 0.95)
        XCTAssertEqual(transcript.language, "en")
        XCTAssertEqual(transcript.confidence, 0.96)
    }

    func testParsesJSONWithoutSegments() async throws {
        let json = """
        {
            "text": "Simple transcript without segments.",
            "language": "en"
        }
        """

        let url = tempDirectory.appendingPathComponent("simple.json")
        try json.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.text, "Simple transcript without segments.")
        XCTAssertTrue(transcript.segments.isEmpty)
        XCTAssertEqual(transcript.language, "en")
        XCTAssertEqual(transcript.confidence, 1.0)
    }

    func testHandlesInvalidJSON() async throws {
        let json = "{ invalid json }"
        let url = tempDirectory.appendingPathComponent("invalid.json")
        try json.write(to: url, atomically: true, encoding: .utf8)

        do {
            _ = try await service.loadTranscript(from: url)
            XCTFail("Should throw error for invalid JSON")
        } catch TranscriptFileError.invalidFormat {
            // Expected
        }
    }

    // MARK: - SRT Parsing Tests

    func testParsesSRTFormat() async throws {
        let srt = """
        1
        00:00:00,000 --> 00:00:05,000
        First subtitle line

        2
        00:00:05,000 --> 00:00:10,000
        Second subtitle line

        3
        00:00:10,000 --> 00:00:15,000
        Third subtitle line
        """

        let url = tempDirectory.appendingPathComponent("test.srt")
        try srt.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.text, "First subtitle line Second subtitle line Third subtitle line")
        XCTAssertEqual(transcript.segments.count, 3)
        XCTAssertEqual(transcript.segments[0].text, "First subtitle line")
        XCTAssertEqual(transcript.segments[0].startTime, 0.0)
        XCTAssertEqual(transcript.segments[0].endTime, 5.0)
        XCTAssertEqual(transcript.segments[1].startTime, 5.0)
        XCTAssertEqual(transcript.segments[1].endTime, 10.0)
    }

    func testHandlesMultilineSRTSubtitles() async throws {
        let srt = """
        1
        00:00:00,000 --> 00:00:05,000
        First line of subtitle
        Second line of subtitle

        2
        00:00:05,000 --> 00:00:10,000
        Another subtitle
        """

        let url = tempDirectory.appendingPathComponent("multiline.srt")
        try srt.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.segments.count, 2)
        XCTAssertEqual(transcript.segments[0].text, "First line of subtitle Second line of subtitle")
        XCTAssertEqual(transcript.segments[1].text, "Another subtitle")
    }

    func testHandlesInvalidSRTTimestamp() async throws {
        let srt = """
        1
        invalid timestamp
        Some text
        """

        let url = tempDirectory.appendingPathComponent("invalid.srt")
        try srt.write(to: url, atomically: true, encoding: .utf8)

        do {
            _ = try await service.loadTranscript(from: url)
            XCTFail("Should throw error for invalid SRT format")
        } catch TranscriptFileError.invalidFormat {
            // Expected
        }
    }

    // MARK: - VTT Parsing Tests

    func testParsesVTTFormat() async throws {
        let vtt = """
        WEBVTT

        00:00:00.000 --> 00:00:05.000
        First caption

        00:00:05.000 --> 00:00:10.000
        Second caption
        """

        let url = tempDirectory.appendingPathComponent("test.vtt")
        try vtt.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.text, "First caption Second caption")
        XCTAssertEqual(transcript.segments.count, 2)
        XCTAssertEqual(transcript.segments[0].text, "First caption")
        XCTAssertEqual(transcript.segments[0].startTime, 0.0)
        XCTAssertEqual(transcript.segments[0].endTime, 5.0)
    }

    func testHandlesVTTWithNotes() async throws {
        let vtt = """
        WEBVTT

        NOTE This is a comment

        00:00:00.000 --> 00:00:05.000
        Caption text

        NOTE Another comment

        00:00:05.000 --> 00:00:10.000
        More caption text
        """

        let url = tempDirectory.appendingPathComponent("notes.vtt")
        try vtt.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.segments.count, 2)
        XCTAssertEqual(transcript.segments[0].text, "Caption text")
        XCTAssertEqual(transcript.segments[1].text, "More caption text")
    }

    func testHandlesVTTWithCueIdentifiers() async throws {
        let vtt = """
        WEBVTT

        cue-1
        00:00:00.000 --> 00:00:05.000
        First cue

        cue-2
        00:00:05.000 --> 00:00:10.000
        Second cue
        """

        let url = tempDirectory.appendingPathComponent("cues.vtt")
        try vtt.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.segments.count, 2)
        XCTAssertEqual(transcript.segments[0].text, "First cue")
        XCTAssertEqual(transcript.segments[1].text, "Second cue")
    }

    func testHandlesMissingWEBVTTHeader() async throws {
        let vtt = """
        00:00:00.000 --> 00:00:05.000
        Caption without header
        """

        let url = tempDirectory.appendingPathComponent("no-header.vtt")
        try vtt.write(to: url, atomically: true, encoding: .utf8)

        do {
            _ = try await service.loadTranscript(from: url)
            XCTFail("Should throw error for missing WEBVTT header")
        } catch TranscriptFileError.invalidFormat {
            // Expected
        }
    }

    // MARK: - URL Download Tests

    func testDownloadsTranscriptFromURL() async throws {
        // Create a mock server URL (we'll skip this test if no network available)
        // For now, we'll test the URL validation and flow
        let validURL = "https://example.com/transcript.txt"
        XCTAssertTrue(service.isValidTranscriptURL(validURL))
    }

    func testValidatesTranscriptURLs() {
        XCTAssertTrue(service.isValidTranscriptURL("https://example.com/file.txt"))
        XCTAssertTrue(service.isValidTranscriptURL("https://example.com/file.json"))
        XCTAssertTrue(service.isValidTranscriptURL("https://example.com/file.srt"))
        XCTAssertTrue(service.isValidTranscriptURL("https://example.com/file.vtt"))
        XCTAssertFalse(service.isValidTranscriptURL("not a url"))
        XCTAssertFalse(service.isValidTranscriptURL("https://example.com/file.mp3"))
    }

    // MARK: - Error Handling Tests

    func testHandlesFileNotFound() async throws {
        let url = tempDirectory.appendingPathComponent("nonexistent.txt")

        do {
            _ = try await service.loadTranscript(from: url)
            XCTFail("Should throw error for non-existent file")
        } catch TranscriptFileError.fileNotFound {
            // Expected
        }
    }

    func testHandlesUnsupportedFormat() async throws {
        let url = tempDirectory.appendingPathComponent("test.pdf")
        try "Some content".write(to: url, atomically: true, encoding: .utf8)

        do {
            _ = try await service.loadTranscript(from: url)
            XCTFail("Should throw error for unsupported format")
        } catch TranscriptFileError.unsupportedFormat {
            // Expected
        }
    }

    func testHandlesPermissionDenied() {
        // This test would require platform-specific permission testing
        // Placeholder for future implementation
    }

    // MARK: - Edge Cases

    func testHandlesVeryLargeFile() async throws {
        // Create a large transcript (simulate 1MB+ file)
        let largeContent = String(repeating: "This is a test sentence. ", count: 50000)
        let url = tempDirectory.appendingPathComponent("large.txt")
        try largeContent.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertFalse(transcript.text.isEmpty)
        XCTAssertTrue(transcript.text.count > 1_000_000)
    }

    func testHandlesUTF8EncodedFile() async throws {
        let content = "Transcript with émojis 🎵 and spëcial çharacters"
        let url = tempDirectory.appendingPathComponent("utf8.txt")
        try content.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertEqual(transcript.text, content)
    }

    func testHandlesWindowsLineEndings() async throws {
        let content = "Line 1\r\nLine 2\r\nLine 3"
        let url = tempDirectory.appendingPathComponent("windows.txt")
        try content.write(to: url, atomically: true, encoding: .utf8)

        let transcript = try await service.loadTranscript(from: url)

        XCTAssertTrue(transcript.text.contains("Line 1"))
        XCTAssertTrue(transcript.text.contains("Line 2"))
        XCTAssertTrue(transcript.text.contains("Line 3"))
    }
}
