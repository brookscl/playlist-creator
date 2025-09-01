import XCTest
@testable import PlaylistCreator

final class AudioProcessorTests: XCTestCase {
    var mockProcessor: MockAudioProcessor!
    
    override func setUp() {
        super.setUp()
        mockProcessor = MockAudioProcessor()
    }
    
    override func tearDown() {
        mockProcessor = nil
        super.tearDown()
    }
    
    // MARK: - ProcessedAudio Tests
    
    func testProcessedAudioInitialization() throws {
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        let audio = ProcessedAudio(url: url, duration: 120.0)
        
        XCTAssertEqual(audio.url, url)
        XCTAssertEqual(audio.duration, 120.0)
        XCTAssertEqual(audio.format, .wav)
        XCTAssertEqual(audio.sampleRate, 16000)
    }
    
    func testProcessedAudioWithCustomParameters() throws {
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        let audio = ProcessedAudio(url: url, duration: 240.0, format: .mp3, sampleRate: 44100)
        
        XCTAssertEqual(audio.url, url)
        XCTAssertEqual(audio.duration, 240.0)
        XCTAssertEqual(audio.format, .mp3)
        XCTAssertEqual(audio.sampleRate, 44100)
    }
    
    func testProcessedAudioEquality() throws {
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        let audio1 = ProcessedAudio(url: url, duration: 120.0)
        let audio2 = ProcessedAudio(url: url, duration: 120.0)
        
        XCTAssertEqual(audio1, audio2)
    }
    
    func testProcessedAudioInequality() throws {
        let url1 = URL(fileURLWithPath: "/tmp/test1.wav")
        let url2 = URL(fileURLWithPath: "/tmp/test2.wav")
        let audio1 = ProcessedAudio(url: url1, duration: 120.0)
        let audio2 = ProcessedAudio(url: url2, duration: 120.0)
        
        XCTAssertNotEqual(audio1, audio2)
    }
    
    // MARK: - AudioFormat Tests
    
    func testAudioFormatCases() throws {
        XCTAssertEqual(AudioFormat.wav.rawValue, "wav")
        XCTAssertEqual(AudioFormat.mp3.rawValue, "mp3")
        XCTAssertEqual(AudioFormat.m4a.rawValue, "m4a")
        XCTAssertEqual(AudioFormat.aac.rawValue, "aac")
    }
    
    func testAudioFormatAllCases() throws {
        let allCases = AudioFormat.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.wav))
        XCTAssertTrue(allCases.contains(.mp3))
        XCTAssertTrue(allCases.contains(.m4a))
        XCTAssertTrue(allCases.contains(.aac))
    }
    
    // MARK: - Mock AudioProcessor Tests
    
    func testMockProcessFileUploadSuccess() async throws {
        let testURL = URL(fileURLWithPath: "/tmp/test.mp3")
        let expectedAudio = ProcessedAudio(url: testURL, duration: 300.0, format: .wav, sampleRate: 16000)
        mockProcessor.processFileUploadResult = expectedAudio
        
        let result = try await mockProcessor.processFileUpload(testURL)
        
        XCTAssertEqual(result, expectedAudio)
    }
    
    func testMockProcessFileUploadFailure() async throws {
        let testURL = URL(fileURLWithPath: "/tmp/nonexistent.mp3")
        mockProcessor.shouldThrowError = true
        
        do {
            _ = try await mockProcessor.processFileUpload(testURL)
            XCTFail("Expected error to be thrown")
        } catch let error as AudioProcessingError {
            XCTAssertEqual(error, .fileNotFound(testURL.path))
        }
    }
    
    func testMockProcessURLSuccess() async throws {
        let testURL = URL(string: "https://example.com/audio.mp3")!
        let expectedAudio = ProcessedAudio(url: testURL, duration: 180.0)
        mockProcessor.processURLResult = expectedAudio
        
        let result = try await mockProcessor.processURL(testURL)
        
        XCTAssertEqual(result, expectedAudio)
    }
    
    func testMockProcessURLFailure() async throws {
        let testURL = URL(string: "https://example.com/invalid.mp3")!
        mockProcessor.shouldThrowError = true
        
        do {
            _ = try await mockProcessor.processURL(testURL)
            XCTFail("Expected error to be thrown")
        } catch let error as AudioProcessingError {
            XCTAssertEqual(error, .extractionFailed("Mock error"))
        }
    }
    
    func testMockExtractAudioFromVideoSuccess() async throws {
        let videoURL = URL(fileURLWithPath: "/tmp/video.mp4")
        let expectedAudioURL = URL(fileURLWithPath: "/tmp/custom_audio.wav")
        mockProcessor.extractAudioResult = expectedAudioURL
        
        let result = try await mockProcessor.extractAudioFromVideo(videoURL)
        
        XCTAssertEqual(result, expectedAudioURL)
    }
    
    func testMockExtractAudioFromVideoFailure() async throws {
        let videoURL = URL(fileURLWithPath: "/tmp/corrupt.mp4")
        mockProcessor.shouldThrowError = true
        
        do {
            _ = try await mockProcessor.extractAudioFromVideo(videoURL)
            XCTFail("Expected error to be thrown")
        } catch let error as AudioProcessingError {
            XCTAssertEqual(error, .extractionFailed("Mock error"))
        }
    }
    
    func testMockNormalizeAudioFormatSuccess() async throws {
        let inputURL = URL(fileURLWithPath: "/tmp/input.mp3")
        let expectedOutputURL = URL(fileURLWithPath: "/tmp/custom_normalized.wav")
        mockProcessor.normalizeAudioResult = expectedOutputURL
        
        let result = try await mockProcessor.normalizeAudioFormat(inputURL)
        
        XCTAssertEqual(result, expectedOutputURL)
    }
    
    func testMockNormalizeAudioFormatFailure() async throws {
        let inputURL = URL(fileURLWithPath: "/tmp/invalid.mp3")
        mockProcessor.shouldThrowError = true
        
        do {
            _ = try await mockProcessor.normalizeAudioFormat(inputURL)
            XCTFail("Expected error to be thrown")
        } catch let error as AudioProcessingError {
            XCTAssertEqual(error, .normalizationFailed("Mock error"))
        }
    }
    
    func testMockDefaultBehavior() async throws {
        let testURL = URL(fileURLWithPath: "/tmp/test.mp3")
        
        // Test default behavior when no custom results are set
        let uploadResult = try await mockProcessor.processFileUpload(testURL)
        XCTAssertEqual(uploadResult.duration, 180.0)
        XCTAssertEqual(uploadResult.format, .wav)
        XCTAssertEqual(uploadResult.sampleRate, 16000)
        
        let urlResult = try await mockProcessor.processURL(testURL)
        XCTAssertEqual(urlResult.duration, 240.0)
        
        let videoURL = URL(fileURLWithPath: "/tmp/video.mp4")
        let extractResult = try await mockProcessor.extractAudioFromVideo(videoURL)
        XCTAssertEqual(extractResult.path, "/tmp/extracted_audio.wav")
        
        let normalizeResult = try await mockProcessor.normalizeAudioFormat(testURL)
        XCTAssertEqual(normalizeResult.path, "/tmp/normalized_audio.wav")
    }
}
