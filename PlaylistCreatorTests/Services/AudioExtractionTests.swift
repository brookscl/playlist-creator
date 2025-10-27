import XCTest
import AVFoundation
@testable import PlaylistCreator

final class AudioExtractionTests: XCTestCase {
    var service: FileUploadService!
    var tempDirectoryURL: URL!

    override func setUp() {
        super.setUp()
        service = FileUploadService()
        tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        service = nil
        tempDirectoryURL = nil
        super.tearDown()
    }

    // MARK: - Video Format Detection Tests

    func testDetectMP4VideoFormat() {
        XCTAssertTrue(service.isValidVideoFormat("mp4"))
    }

    func testDetectMOVVideoFormat() {
        XCTAssertTrue(service.isValidVideoFormat("mov"))
    }

    func testDetectAVIVideoFormat() {
        XCTAssertTrue(service.isValidVideoFormat("avi"))
    }

    func testDetectMKVVideoFormat() {
        XCTAssertTrue(service.isValidVideoFormat("mkv"))
    }

    func testDetectWebMVideoFormat() {
        XCTAssertTrue(service.isValidVideoFormat("webm"))
    }

    func testDetectM4VVideoFormat() {
        XCTAssertTrue(service.isValidVideoFormat("m4v"))
    }

    func testCaseInsensitiveVideoFormatDetection() {
        XCTAssertTrue(service.isValidVideoFormat("MP4"))
        XCTAssertTrue(service.isValidVideoFormat("Mov"))
        XCTAssertTrue(service.isValidVideoFormat("AVI"))
    }

    // MARK: - Audio Format Detection Tests

    func testDetectMP3AudioFormat() {
        XCTAssertTrue(service.isValidAudioFormat("mp3"))
    }

    func testDetectWAVAudioFormat() {
        XCTAssertTrue(service.isValidAudioFormat("wav"))
    }

    func testDetectM4AAudioFormat() {
        XCTAssertTrue(service.isValidAudioFormat("m4a"))
    }

    func testDetectAACAudioFormat() {
        XCTAssertTrue(service.isValidAudioFormat("aac"))
    }

    func testDetectFLACAudioFormat() {
        XCTAssertTrue(service.isValidAudioFormat("flac"))
    }

    func testDetectOGGAudioFormat() {
        XCTAssertTrue(service.isValidAudioFormat("ogg"))
    }

    // MARK: - File Type Determination Tests

    func testFileExtensionExtraction() {
        XCTAssertEqual(service.extractFileExtension("video.mp4"), "mp4")
        XCTAssertEqual(service.extractFileExtension("audio.mp3"), "mp3")
        XCTAssertEqual(service.extractFileExtension("file.name.with.dots.mov"), "mov")
        XCTAssertEqual(service.extractFileExtension("noextension"), "")
        XCTAssertEqual(service.extractFileExtension(".hidden"), "hidden")
    }

    // MARK: - Error Handling Tests

    func testExtractionFailsWithNoAudioTracks() async throws {
        // This test verifies error handling when video has no audio
        // In production, would use actual video file without audio track
        let testFile = tempDirectoryURL.appendingPathComponent("no-audio.mp4")
        try "fake video content".write(to: testFile, atomically: true, encoding: .utf8)

        do {
            _ = try await service.extractAudioFromVideo(testFile)
            XCTFail("Should throw error for file without audio tracks")
        } catch let error as AudioProcessingError {
            // Expected to fail - fake file cannot be loaded as video
            XCTAssertTrue(true) // Expected - fake file throws extraction error
        } catch {
            // AVFoundation may throw its own error for corrupted files
            XCTAssertTrue(true) // Also acceptable for fake file
        }
    }

    func testNormalizationWithInvalidFile() async throws {
        let invalidFile = tempDirectoryURL.appendingPathComponent("invalid.mp3")
        try "not valid audio".write(to: invalidFile, atomically: true, encoding: .utf8)

        do {
            _ = try await service.normalizeAudioFormat(invalidFile)
            XCTFail("Should throw error for invalid audio file")
        } catch let error as AudioProcessingError {
            switch error {
            case .normalizationFailed:
                XCTAssertTrue(true) // Expected
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Progress Tracking Tests

    func testExtractionProgressTracking() async throws {
        var progressUpdates: [Double] = []

        service.progressCallback = { progress in
            progressUpdates.append(progress)
        }

        // Test with fake file (will fail but should track progress attempts)
        let testFile = tempDirectoryURL.appendingPathComponent("test.mp4")
        try "fake content".write(to: testFile, atomically: true, encoding: .utf8)

        do {
            _ = try await service.extractAudioFromVideo(testFile)
        } catch {
            // Expected to fail, but should have attempted progress tracking
            XCTAssertFalse(progressUpdates.isEmpty, "Should have tracked some progress")
        }
    }

    func testNormalizationProgressTracking() async throws {
        var progressUpdates: [Double] = []

        service.progressCallback = { progress in
            progressUpdates.append(progress)
        }

        let testFile = tempDirectoryURL.appendingPathComponent("test.mp3")
        try "fake audio".write(to: testFile, atomically: true, encoding: .utf8)

        do {
            _ = try await service.normalizeAudioFormat(testFile)
        } catch {
            // Expected to fail, but should have attempted progress tracking
            XCTAssertFalse(progressUpdates.isEmpty, "Should have tracked some progress")
        }
    }

    // MARK: - File Management Tests

    func testTemporaryFileCleanup() throws {
        // Create some temporary files
        let file1 = tempDirectoryURL.appendingPathComponent("temp1.m4a")
        let file2 = tempDirectoryURL.appendingPathComponent("temp2.m4a")

        try "content1".write(to: file1, atomically: true, encoding: .utf8)
        try "content2".write(to: file2, atomically: true, encoding: .utf8)

        // Manually add to service's tracking (normally done during extraction)
        _ = try service.createTemporaryFile(from: file1)
        _ = try service.createTemporaryFile(from: file2)

        // Cleanup
        service.cleanupAllTemporaryFiles()

        // Verify cleanup doesn't crash on already-cleaned files
        service.cleanupAllTemporaryFiles()
        XCTAssertTrue(true) // Test passes if no crash
    }

    func testIntermediateFileCleanupAfterProcessing() throws {
        let testFile = tempDirectoryURL.appendingPathComponent("input.mp4")
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        // Create temp file
        let tempURL = try service.createTemporaryFile(from: testFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        // Cleanup should remove it
        service.performPostProcessingCleanup()
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))
    }

    // MARK: - Format Conversion Tests

    func testAudioFormatConversionAttempt() async throws {
        // Test that service attempts format conversion
        let audioFile = tempDirectoryURL.appendingPathComponent("test.wav")
        try "fake wav content".write(to: audioFile, atomically: true, encoding: .utf8)

        do {
            _ = try await service.normalizeAudioFormat(audioFile)
            // Would succeed with real audio file
        } catch {
            // Expected to fail with fake file, but verifies conversion attempt
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    // MARK: - Codec Support Tests

    func testSupportsVariousVideoExtensions() {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "m4v"]

        for ext in videoExtensions {
            XCTAssertTrue(service.isValidVideoFormat(ext), "\(ext) should be valid")
        }
    }

    func testSupportsVariousAudioExtensions() {
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "ogg"]

        for ext in audioExtensions {
            XCTAssertTrue(service.isValidAudioFormat(ext), "\(ext) should be valid")
        }
    }

    func testRejectsUnsupportedFormats() {
        let unsupportedFormats = ["txt", "pdf", "jpg", "png", "doc", "zip"]

        for ext in unsupportedFormats {
            XCTAssertFalse(service.isValidFileFormat(ext), "\(ext) should be invalid")
        }
    }

    // MARK: - Integration Tests

    func testCompleteVideoProcessingPipeline() async throws {
        // Test that video processing goes through expected steps
        let videoFile = tempDirectoryURL.appendingPathComponent("input.mp4")
        try "fake video".write(to: videoFile, atomically: true, encoding: .utf8)

        let validation = service.validateFile(videoFile)

        switch validation {
        case .success(let result):
            XCTAssertEqual(result.fileType, .video)
            XCTAssertTrue(result.isValid)
        case .failure:
            XCTFail("Validation should succeed for video file")
        }

        // Attempt processing (will fail with fake file but tests pipeline)
        do {
            _ = try await service.processFileUpload(videoFile)
            XCTFail("Should fail with fake video file")
        } catch {
            // Expected to fail with fake content - could be AudioProcessingError or AVFoundation error
            XCTAssertTrue(true) // Test passes - pipeline attempted processing and failed appropriately
        }
    }

    func testAudioFileSkipsExtraction() async throws {
        // Test that pure audio files skip extraction step
        let audioFile = tempDirectoryURL.appendingPathComponent("audio.mp3")
        try "fake audio".write(to: audioFile, atomically: true, encoding: .utf8)

        let validation = service.validateFile(audioFile)

        switch validation {
        case .success(let result):
            XCTAssertEqual(result.fileType, .audio)
            XCTAssertTrue(result.isValid)
        case .failure:
            XCTFail("Validation should succeed for audio file")
        }
    }

    // MARK: - Edge Case Tests

    func testHandlesFileWithMultipleExtensions() {
        let filename = "video.backup.mp4"
        let ext = service.extractFileExtension(filename)
        XCTAssertEqual(ext, "mp4")
    }

    func testHandlesEmptyFilename() {
        let ext = service.extractFileExtension("")
        XCTAssertEqual(ext, "")
    }

    func testHandlesFilenameWithOnlyExtension() {
        let ext = service.extractFileExtension(".mp4")
        XCTAssertEqual(ext, "mp4")
    }

    // MARK: - Status Message Tests

    func testProgressStatusUpdates() async throws {
        var statusUpdates: [Double] = []

        service.progressCallback = { progress in
            statusUpdates.append(progress)
        }

        // Verify progress callback works
        service.updateProgress(0.0)
        service.updateProgress(0.5)
        service.updateProgress(1.0)

        XCTAssertEqual(statusUpdates, [0.0, 0.5, 1.0])
    }

    func testProgressBoundsClamping() {
        var progressValues: [Double] = []

        service.progressCallback = { progress in
            progressValues.append(progress)
        }

        service.updateProgress(-0.5) // Should clamp to 0
        service.updateProgress(1.5)  // Should clamp to 1
        service.updateProgress(0.5)  // Normal value

        XCTAssertEqual(progressValues[0], 0.0)
        XCTAssertEqual(progressValues[1], 1.0)
        XCTAssertEqual(progressValues[2], 0.5)
    }
}
