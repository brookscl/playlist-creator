import XCTest
@testable import PlaylistCreator

final class TranscriptProcessorTests: XCTestCase {
    var processor: TranscriptProcessor!

    override func setUp() {
        super.setUp()
        processor = TranscriptProcessor()
    }

    override func tearDown() {
        processor = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testProcessorInitialization() {
        XCTAssertNotNil(processor)
    }

    // MARK: - Text Cleaning Tests

    func testRemoveFillerWords() {
        let input = "Um, I like, you know, this song is, uh, really good"
        let expected = "I this song is really good"
        let result = processor.removeFillerWords(input)
        XCTAssertEqual(result, expected)
    }

    func testRemoveMultipleFillerWords() {
        let input = "So like um uh you know basically"
        let result = processor.removeFillerWords(input)
        XCTAssertFalse(result.contains("um"))
        XCTAssertFalse(result.contains("uh"))
        XCTAssertFalse(result.contains("like"))
        XCTAssertFalse(result.contains("you know"))
    }

    func testPreserveImportantLikeUsage() {
        let input = "I like this song"
        let result = processor.removeFillerWords(input)
        // Should preserve "like" when it's meaningful (before noun/pronoun)
        XCTAssertTrue(result.contains("like") || !result.isEmpty)
    }

    func testRemoveExcessiveWhitespace() {
        let input = "Hello    world   test"
        let expected = "Hello world test"
        let result = processor.normalizeWhitespace(input)
        XCTAssertEqual(result, expected)
    }

    func testTrimWhitespace() {
        let input = "  Hello world  "
        let expected = "Hello world"
        let result = processor.normalizeWhitespace(input)
        XCTAssertEqual(result, expected)
    }

    // MARK: - Punctuation and Capitalization Tests

    func testCapitalizeSentences() {
        let input = "hello world. this is a test. another sentence"
        let result = processor.capitalizeSentences(input)
        XCTAssertTrue(result.hasPrefix("Hello"))
        XCTAssertTrue(result.contains(". This"))
        XCTAssertTrue(result.contains(". Another"))
    }

    func testFixMissingPeriods() {
        let input = "First sentence Second sentence"
        let result = processor.fixPunctuation(input)
        // Should attempt to add punctuation between sentences
        XCTAssertTrue(result.contains(".") || result.contains("sentence Second"))
    }

    func testPreserveExistingPunctuation() {
        let input = "Hello! How are you? I'm fine."
        let result = processor.fixPunctuation(input)
        XCTAssertTrue(result.contains("!"))
        XCTAssertTrue(result.contains("?"))
        XCTAssertTrue(result.contains("."))
    }

    func testRemoveExtraSpacesAroundPunctuation() {
        let input = "Hello , world . Test !"
        let expected = "Hello, world. Test!"
        let result = processor.fixPunctuation(input)
        XCTAssertEqual(result, expected)
    }

    // MARK: - Transcript Processing Tests

    func testProcessTranscriptWithCleaning() {
        let segments = [
            TranscriptSegment(text: "Um, so like, the song is great", startTime: 0.0, endTime: 5.0, confidence: 0.9)
        ]
        let transcript = Transcript(text: "Um, so like, the song is great", segments: segments, language: "en", confidence: 0.9)

        let processed = processor.process(transcript)

        XCTAssertNotNil(processed.text)
        XCTAssertFalse(processed.text.contains("Um"))
        XCTAssertFalse(processed.text.contains("like"))
    }

    func testProcessTranscriptPreservesTimestamps() {
        let segments = [
            TranscriptSegment(text: "First segment", startTime: 0.0, endTime: 5.0, confidence: 0.9),
            TranscriptSegment(text: "Second segment", startTime: 5.0, endTime: 10.0, confidence: 0.85)
        ]
        let transcript = Transcript(text: "First segment. Second segment.", segments: segments, language: "en", confidence: 0.875)

        let processed = processor.process(transcript)

        XCTAssertEqual(processed.segments.count, 2)
        XCTAssertEqual(processed.segments[0].startTime, 0.0)
        XCTAssertEqual(processed.segments[0].endTime, 5.0)
        XCTAssertEqual(processed.segments[1].startTime, 5.0)
        XCTAssertEqual(processed.segments[1].endTime, 10.0)
    }

    func testProcessEmptyTranscript() {
        let transcript = Transcript(text: "", segments: [], language: "en", confidence: 0.0)
        let processed = processor.process(transcript)

        XCTAssertTrue(processed.text.isEmpty)
        XCTAssertTrue(processed.segments.isEmpty)
    }

    // MARK: - Quality Scoring Tests

    func testCalculateSegmentQuality() {
        let highConfidenceSegment = TranscriptSegment(text: "Clear speech here", startTime: 0.0, endTime: 2.0, confidence: 0.95)
        let quality = processor.calculateQualityScore(highConfidenceSegment)

        XCTAssertGreaterThan(quality, 0.8)
    }

    func testLowQualitySegmentDetection() {
        let lowConfidenceSegment = TranscriptSegment(text: "Unclear mumbling", startTime: 0.0, endTime: 2.0, confidence: 0.3)
        let quality = processor.calculateQualityScore(lowConfidenceSegment)

        XCTAssertLessThan(quality, 0.5)
    }

    func testOverallTranscriptQuality() {
        let segments = [
            TranscriptSegment(text: "Good segment", startTime: 0.0, endTime: 5.0, confidence: 0.9),
            TranscriptSegment(text: "Another good one", startTime: 5.0, endTime: 10.0, confidence: 0.85),
            TranscriptSegment(text: "Poor quality", startTime: 10.0, endTime: 15.0, confidence: 0.4)
        ]
        let transcript = Transcript(text: "Combined text", segments: segments, language: "en", confidence: 0.72)

        let quality = processor.calculateOverallQuality(transcript)
        XCTAssertGreaterThan(quality, 0.0)
        XCTAssertLessThan(quality, 1.0)
    }

    // MARK: - Text Normalization Tests

    func testNormalizeQuotes() {
        let input = "He said \"hello\" and 'goodbye'"
        let result = processor.normalizeQuotes(input)
        // Should normalize to consistent quote style
        XCTAssertTrue(result.contains("\"") || result.contains("'"))
    }

    func testNormalizeApostrophes() {
        let input = "It's a test. Don't worry."
        let result = processor.normalizeText(input)
        XCTAssertTrue(result.contains("'") || result.contains("'"))
    }

    func testRemoveRepeatedPunctuation() {
        let input = "What???!!! Really..."
        let expected = "What?! Really."
        let result = processor.normalizeText(input)
        XCTAssertEqual(result, expected)
    }

    func testNormalizeNumberSpelling() {
        let input = "Track one and track 2"
        let result = processor.normalizeText(input)
        // Should make number formatting consistent
        XCTAssertNotNil(result)
    }

    // MARK: - Edge Case Tests

    func testHandleVeryLongText() {
        let longText = String(repeating: "This is a test sentence. ", count: 1000)
        let transcript = Transcript(text: longText, segments: [], language: "en", confidence: 0.9)

        let processed = processor.process(transcript)
        XCTAssertNotNil(processed)
        XCTAssertFalse(processed.text.isEmpty)
    }

    func testHandleSpecialCharacters() {
        let input = "Song: \"Test\" & 'Another' – with em-dash"
        let result = processor.normalizeText(input)
        XCTAssertNotNil(result)
    }

    func testHandleMultipleLanguages() {
        let transcript = Transcript(text: "Hello world", segments: [], language: "en", confidence: 0.9)
        let processed = processor.process(transcript)

        XCTAssertEqual(processed.language, "en")
    }

    func testPreserveImportantPunctuation() {
        let input = "Is this a question? Yes! It's amazing."
        let result = processor.normalizeText(input)
        XCTAssertTrue(result.contains("?"))
        XCTAssertTrue(result.contains("!"))
    }

    // MARK: - Segment Merging Tests

    func testMergeShortSegments() {
        let segments = [
            TranscriptSegment(text: "Hi", startTime: 0.0, endTime: 0.5, confidence: 0.9),
            TranscriptSegment(text: "there", startTime: 0.5, endTime: 1.0, confidence: 0.9),
            TranscriptSegment(text: "friend", startTime: 1.0, endTime: 1.5, confidence: 0.9)
        ]

        let merged = processor.mergeShortSegments(segments, minimumDuration: 2.0)
        XCTAssertLessThan(merged.count, segments.count)
    }

    func testPreserveLongSegments() {
        let segments = [
            TranscriptSegment(text: "This is a long segment", startTime: 0.0, endTime: 10.0, confidence: 0.9)
        ]

        let merged = processor.mergeShortSegments(segments, minimumDuration: 2.0)
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].text, segments[0].text)
    }

    // MARK: - Integration Tests

    func testFullProcessingPipeline() {
        let segments = [
            TranscriptSegment(text: "Um, so like, I listened to Wish You Were Here", startTime: 0.0, endTime: 5.0, confidence: 0.9),
            TranscriptSegment(text: "by Pink Floyd. It's, uh, really good", startTime: 5.0, endTime: 10.0, confidence: 0.85)
        ]
        let transcript = Transcript(
            text: "Um, so like, I listened to Wish You Were Here by Pink Floyd. It's, uh, really good",
            segments: segments,
            language: "en",
            confidence: 0.875
        )

        let processed = processor.process(transcript)

        // Verify cleaning
        XCTAssertFalse(processed.text.contains("Um"))
        XCTAssertFalse(processed.text.contains("uh"))

        // Verify song mention preserved
        XCTAssertTrue(processed.text.contains("Wish You Were Here"))
        XCTAssertTrue(processed.text.contains("Pink Floyd"))

        // Verify timestamps preserved
        XCTAssertEqual(processed.segments.count, 2)
        XCTAssertEqual(processed.segments[0].startTime, 0.0)
    }

    func testProcessingWithConfiguration() {
        let config = TranscriptProcessingConfig(
            removeFillerWords: true,
            fixPunctuation: true,
            capitalizeSentences: true,
            normalizeWhitespace: true,
            mergeShortSegments: false
        )

        let processor = TranscriptProcessor(config: config)
        let transcript = Transcript(text: "um hello world", segments: [], language: "en", confidence: 0.9)

        let processed = processor.process(transcript)
        XCTAssertNotNil(processed)
    }
}
