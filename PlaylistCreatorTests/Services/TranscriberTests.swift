import XCTest
@testable import PlaylistCreator

final class TranscriberTests: XCTestCase {
    var mockTranscriber: MockTranscriber!
    
    override func setUp() {
        super.setUp()
        mockTranscriber = MockTranscriber()
    }
    
    override func tearDown() {
        mockTranscriber = nil
        super.tearDown()
    }
    
    // MARK: - Transcript Tests
    
    func testTranscriptInitialization() throws {
        let transcript = Transcript(text: "Hello world")
        
        XCTAssertEqual(transcript.text, "Hello world")
        XCTAssertTrue(transcript.segments.isEmpty)
        XCTAssertNil(transcript.language)
        XCTAssertEqual(transcript.confidence, 1.0)
    }
    
    func testTranscriptWithAllParameters() throws {
        let segments = [TranscriptSegment(text: "Hello", startTime: 0.0, endTime: 1.0)]
        let transcript = Transcript(text: "Hello world", segments: segments, language: "en", confidence: 0.95)
        
        XCTAssertEqual(transcript.text, "Hello world")
        XCTAssertEqual(transcript.segments.count, 1)
        XCTAssertEqual(transcript.language, "en")
        XCTAssertEqual(transcript.confidence, 0.95)
    }
    
    func testTranscriptEquality() throws {
        let segments1 = [TranscriptSegment(text: "Hello", startTime: 0.0, endTime: 1.0)]
        let segments2 = [TranscriptSegment(text: "Hello", startTime: 0.0, endTime: 1.0)]
        
        let transcript1 = Transcript(text: "Hello world", segments: segments1, language: "en", confidence: 0.95)
        let transcript2 = Transcript(text: "Hello world", segments: segments2, language: "en", confidence: 0.95)
        
        XCTAssertEqual(transcript1, transcript2)
    }
    
    func testTranscriptInequality() throws {
        let transcript1 = Transcript(text: "Hello world", language: "en")
        let transcript2 = Transcript(text: "Goodbye world", language: "en")
        
        XCTAssertNotEqual(transcript1, transcript2)
    }
    
    // MARK: - TranscriptSegment Tests
    
    func testTranscriptSegmentInitialization() throws {
        let segment = TranscriptSegment(text: "Hello", startTime: 0.0, endTime: 1.5)
        
        XCTAssertEqual(segment.text, "Hello")
        XCTAssertEqual(segment.startTime, 0.0)
        XCTAssertEqual(segment.endTime, 1.5)
        XCTAssertEqual(segment.confidence, 1.0)
    }
    
    func testTranscriptSegmentWithConfidence() throws {
        let segment = TranscriptSegment(text: "World", startTime: 1.5, endTime: 3.0, confidence: 0.85)
        
        XCTAssertEqual(segment.text, "World")
        XCTAssertEqual(segment.startTime, 1.5)
        XCTAssertEqual(segment.endTime, 3.0)
        XCTAssertEqual(segment.confidence, 0.85)
    }
    
    func testTranscriptSegmentEquality() throws {
        let segment1 = TranscriptSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9)
        let segment2 = TranscriptSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9)
        
        XCTAssertEqual(segment1, segment2)
    }
    
    func testTranscriptSegmentInequality() throws {
        let segment1 = TranscriptSegment(text: "Hello", startTime: 0.0, endTime: 1.0)
        let segment2 = TranscriptSegment(text: "Hello", startTime: 1.0, endTime: 2.0)
        
        XCTAssertNotEqual(segment1, segment2)
    }
    
    // MARK: - Mock Transcriber Tests
    
    func testMockTranscribeSuccess() async throws {
        let audio = ProcessedAudio(url: URL(fileURLWithPath: "/tmp/test.wav"), duration: 60.0)
        let expectedTranscript = Transcript(text: "Custom transcription", language: "es", confidence: 0.88)
        mockTranscriber.transcribeResult = expectedTranscript
        
        let result = try await mockTranscriber.transcribe(audio)
        
        XCTAssertEqual(result, expectedTranscript)
    }
    
    func testMockTranscribeFailure() async throws {
        let audio = ProcessedAudio(url: URL(fileURLWithPath: "/tmp/test.wav"), duration: 60.0)
        mockTranscriber.shouldThrowError = true
        
        do {
            _ = try await mockTranscriber.transcribe(audio)
            XCTFail("Expected error to be thrown")
        } catch let error as TranscriptionError {
            XCTAssertEqual(error, .transcriptionEmpty)
        }
    }
    
    func testMockTranscribeWithTimestampsSuccess() async throws {
        let audio = ProcessedAudio(url: URL(fileURLWithPath: "/tmp/test.wav"), duration: 120.0)
        let customSegments = [
            TranscriptSegment(text: "Custom segment 1", startTime: 0.0, endTime: 5.0, confidence: 0.95),
            TranscriptSegment(text: "Custom segment 2", startTime: 5.0, endTime: 10.0, confidence: 0.9)
        ]
        let expectedTranscript = Transcript(text: "Custom segment 1 Custom segment 2", segments: customSegments, language: "fr", confidence: 0.925)
        mockTranscriber.transcribeWithTimestampsResult = expectedTranscript
        
        let result = try await mockTranscriber.transcribeWithTimestamps(audio)
        
        XCTAssertEqual(result, expectedTranscript)
    }
    
    func testMockTranscribeWithTimestampsFailure() async throws {
        let audio = ProcessedAudio(url: URL(fileURLWithPath: "/tmp/test.wav"), duration: 120.0)
        mockTranscriber.shouldThrowError = true
        
        do {
            _ = try await mockTranscriber.transcribeWithTimestamps(audio)
            XCTFail("Expected error to be thrown")
        } catch let error as TranscriptionError {
            XCTAssertEqual(error, .apiRequestFailed("Mock error"))
        }
    }
    
    func testMockDefaultBehavior() async throws {
        let audio = ProcessedAudio(url: URL(fileURLWithPath: "/tmp/test.wav"), duration: 60.0)
        
        // Test default behavior when no custom results are set
        let transcribeResult = try await mockTranscriber.transcribe(audio)
        XCTAssertEqual(transcribeResult.text, "This is a mock transcription of the audio content.")
        XCTAssertTrue(transcribeResult.segments.isEmpty)
        XCTAssertEqual(transcribeResult.language, "en")
        XCTAssertEqual(transcribeResult.confidence, 0.95)
        
        let timestampResult = try await mockTranscriber.transcribeWithTimestamps(audio)
        XCTAssertEqual(timestampResult.text, "This is a mock transcription with timestamps.")
        XCTAssertEqual(timestampResult.segments.count, 2)
        XCTAssertEqual(timestampResult.language, "en")
        XCTAssertEqual(timestampResult.confidence, 0.92)
        
        // Test segment details
        let firstSegment = timestampResult.segments[0]
        XCTAssertEqual(firstSegment.text, "This is a mock transcription")
        XCTAssertEqual(firstSegment.startTime, 0.0)
        XCTAssertEqual(firstSegment.endTime, 2.5)
        XCTAssertEqual(firstSegment.confidence, 0.9)
        
        let secondSegment = timestampResult.segments[1]
        XCTAssertEqual(secondSegment.text, "with timestamps.")
        XCTAssertEqual(secondSegment.startTime, 2.5)
        XCTAssertEqual(secondSegment.endTime, 4.0)
        XCTAssertEqual(secondSegment.confidence, 0.95)
    }
    
    // MARK: - DefaultTranscriber Tests
    
    func testDefaultTranscriberInitialization() throws {
        let transcriber1 = DefaultTranscriber()
        XCTAssertNotNil(transcriber1)
        
        let transcriber2 = DefaultTranscriber(apiKey: "test-key")
        XCTAssertNotNil(transcriber2)
    }
    
    func testDefaultTranscriberNotImplemented() async throws {
        let transcriber = DefaultTranscriber()
        let audio = ProcessedAudio(url: URL(fileURLWithPath: "/tmp/test.wav"), duration: 60.0)
        
        do {
            _ = try await transcriber.transcribe(audio)
            XCTFail("Expected notImplemented error")
        } catch let error as TranscriptionError {
            XCTAssertEqual(error, .notImplemented)
        }
        
        do {
            _ = try await transcriber.transcribeWithTimestamps(audio)
            XCTFail("Expected notImplemented error")
        } catch let error as TranscriptionError {
            XCTAssertEqual(error, .notImplemented)
        }
    }
}
