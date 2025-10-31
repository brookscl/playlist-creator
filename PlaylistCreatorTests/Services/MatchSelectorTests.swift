import XCTest
@testable import PlaylistCreator

/// Tests for the MatchSelector utility that determines automatic match selection
final class MatchSelectorTests: XCTestCase {

    // MARK: - Auto-Selection Threshold Tests

    func testExcellentMatchIsAutoSelected() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.95)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .auto, "Excellent matches (>= 0.9) should be auto-selected")
    }

    func testPerfectMatchIsAutoSelected() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 1.0)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .auto, "Perfect matches (1.0) should be auto-selected")
    }

    func testExactThresholdMatchIsAutoSelected() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.9)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .auto, "Matches at exact 0.9 threshold should be auto-selected")
    }

    func testGoodMatchRequiresReview() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.8)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .pending, "Good matches (0.7-0.89) should require user review")
    }

    func testFairMatchRequiresReview() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.6)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .pending, "Fair matches (0.5-0.69) should require user review")
    }

    func testLowConfidenceMatchRequiresReview() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.5)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .pending, "Matches at 0.5 confidence should require review")
    }

    func testVeryPoorMatchRequiresReview() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.3)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .pending, "Poor matches (< 0.5) should still be presented for review")
    }

    func testZeroConfidenceMatchRequiresReview() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.0)
        let status = MatchSelector.determineMatchStatus(for: song)

        XCTAssertEqual(status, .pending, "Zero confidence matches should require review")
    }

    // MARK: - Batch Processing Tests

    func testBatchProcessingWithMixedConfidences() {
        let songs = [
            Song(title: "Song 1", artist: "Artist 1", appleID: "1", confidence: 0.95), // auto
            Song(title: "Song 2", artist: "Artist 2", appleID: "2", confidence: 0.8),  // pending
            Song(title: "Song 3", artist: "Artist 3", appleID: "3", confidence: 0.6),  // pending
            Song(title: "Song 4", artist: "Artist 4", appleID: "4", confidence: 0.92), // auto
        ]

        let results = MatchSelector.processMatches(songs)

        XCTAssertEqual(results.count, 4)
        XCTAssertEqual(results[0].matchStatus, .auto)
        XCTAssertEqual(results[1].matchStatus, .pending)
        XCTAssertEqual(results[2].matchStatus, .pending)
        XCTAssertEqual(results[3].matchStatus, .auto)
    }

    func testBatchProcessingWithAllExcellentMatches() {
        let songs = [
            Song(title: "Song 1", artist: "Artist 1", appleID: "1", confidence: 0.95),
            Song(title: "Song 2", artist: "Artist 2", appleID: "2", confidence: 0.98),
            Song(title: "Song 3", artist: "Artist 3", appleID: "3", confidence: 1.0),
        ]

        let results = MatchSelector.processMatches(songs)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.matchStatus == .auto })
    }

    func testBatchProcessingWithAllPendingMatches() {
        let songs = [
            Song(title: "Song 1", artist: "Artist 1", appleID: "1", confidence: 0.8),
            Song(title: "Song 2", artist: "Artist 2", appleID: "2", confidence: 0.6),
            Song(title: "Song 3", artist: "Artist 3", appleID: "3", confidence: 0.7),
        ]

        let results = MatchSelector.processMatches(songs)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.matchStatus == .pending })
    }

    func testBatchProcessingWithEmptyInput() {
        let songs: [Song] = []
        let results = MatchSelector.processMatches(songs)

        XCTAssertEqual(results.count, 0)
    }

    // MARK: - SearchResult to MatchedSong Conversion Tests

    func testConvertSearchResultToMatchedSong() {
        let originalSong = Song(title: "Original Title", artist: "Original Artist", appleID: nil, confidence: 0.0)
        let searchResult = SearchResult(
            song: Song(title: "Matched Title", artist: "Matched Artist", appleID: "123", confidence: 0.95),
            matchConfidence: 0.95,
            appleMusicID: "123",
            previewURL: URL(string: "https://example.com/preview.m4a")
        )

        let matchedSong = MatchSelector.createMatchedSong(original: originalSong, searchResult: searchResult)

        XCTAssertEqual(matchedSong.originalSong.title, "Original Title")
        XCTAssertEqual(matchedSong.appleMusicSong.title, "Matched Title")
        XCTAssertEqual(matchedSong.matchStatus, .auto)
        XCTAssertEqual(matchedSong.confidence, 0.95)
    }

    func testConvertMultipleSearchResultsToMatchedSongs() {
        let originalSong = Song(title: "Test Song", artist: "Test Artist", appleID: nil, confidence: 0.0)
        let searchResults = [
            SearchResult(song: Song(title: "Match 1", artist: "Artist 1", appleID: "1", confidence: 0.95),
                        matchConfidence: 0.95, appleMusicID: "1", previewURL: nil),
            SearchResult(song: Song(title: "Match 2", artist: "Artist 2", appleID: "2", confidence: 0.7),
                        matchConfidence: 0.7, appleMusicID: "2", previewURL: nil)
        ]

        let matchedSongs = MatchSelector.createMatchedSongs(original: originalSong, searchResults: searchResults)

        XCTAssertEqual(matchedSongs.count, 2)
        XCTAssertEqual(matchedSongs[0].matchStatus, .auto)
        XCTAssertEqual(matchedSongs[1].matchStatus, .pending)
    }

    // MARK: - Selection Summary Tests

    func testSelectionSummaryWithMixedResults() {
        let results = [
            MatchedSong(originalSong: Song(title: "Song 1", artist: "Artist 1", appleID: nil, confidence: 0.0),
                       appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "1", confidence: 0.95),
                       matchStatus: .auto),
            MatchedSong(originalSong: Song(title: "Song 2", artist: "Artist 2", appleID: nil, confidence: 0.0),
                       appleMusicSong: Song(title: "Song 2", artist: "Artist 2", appleID: "2", confidence: 0.8),
                       matchStatus: .pending),
            MatchedSong(originalSong: Song(title: "Song 3", artist: "Artist 3", appleID: nil, confidence: 0.0),
                       appleMusicSong: Song(title: "Song 3", artist: "Artist 3", appleID: "3", confidence: 0.6),
                       matchStatus: .pending),
        ]

        let summary = MatchSelector.generateSelectionSummary(results)

        XCTAssertEqual(summary.totalMatches, 3)
        XCTAssertEqual(summary.autoSelected, 1)
        XCTAssertEqual(summary.requiresReview, 2)
        XCTAssertEqual(summary.skipped, 0)
    }

    func testSelectionSummaryWithAllAutoSelected() {
        let results = [
            MatchedSong(originalSong: Song(title: "Song 1", artist: "Artist 1", appleID: nil, confidence: 0.0),
                       appleMusicSong: Song(title: "Song 1", artist: "Artist 1", appleID: "1", confidence: 0.95),
                       matchStatus: .auto),
            MatchedSong(originalSong: Song(title: "Song 2", artist: "Artist 2", appleID: nil, confidence: 0.0),
                       appleMusicSong: Song(title: "Song 2", artist: "Artist 2", appleID: "2", confidence: 1.0),
                       matchStatus: .auto),
        ]

        let summary = MatchSelector.generateSelectionSummary(results)

        XCTAssertEqual(summary.totalMatches, 2)
        XCTAssertEqual(summary.autoSelected, 2)
        XCTAssertEqual(summary.requiresReview, 0)
    }

    func testSelectionSummaryWithEmptyResults() {
        let results: [MatchedSong] = []
        let summary = MatchSelector.generateSelectionSummary(results)

        XCTAssertEqual(summary.totalMatches, 0)
        XCTAssertEqual(summary.autoSelected, 0)
        XCTAssertEqual(summary.requiresReview, 0)
    }

    // MARK: - Custom Threshold Tests

    func testCustomAutoSelectionThreshold() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.85)

        // With default threshold (0.9), this should be pending
        let defaultStatus = MatchSelector.determineMatchStatus(for: song)
        XCTAssertEqual(defaultStatus, .pending)

        // With custom threshold (0.8), this should be auto
        let customStatus = MatchSelector.determineMatchStatus(for: song, autoSelectThreshold: 0.8)
        XCTAssertEqual(customStatus, .auto)
    }

    func testCustomMinimumConfidenceThreshold() {
        let song = Song(title: "Test Song", artist: "Test Artist", appleID: "123", confidence: 0.3)

        // With default (show all), this should be pending
        let defaultStatus = MatchSelector.determineMatchStatus(for: song)
        XCTAssertEqual(defaultStatus, .pending)

        // With custom minimum threshold (0.5), this should still be pending but marked as low quality
        let customStatus = MatchSelector.determineMatchStatus(for: song, minimumConfidence: 0.5)
        XCTAssertEqual(customStatus, .pending, "Even below minimum, matches should be shown for review")
    }

    // MARK: - Match Quality Indicator Tests

    func testMatchQualityDescription() {
        let excellentSong = Song(title: "Test", artist: "Test", appleID: "1", confidence: 0.95)
        let goodSong = Song(title: "Test", artist: "Test", appleID: "2", confidence: 0.8)
        let fairSong = Song(title: "Test", artist: "Test", appleID: "3", confidence: 0.6)
        let poorSong = Song(title: "Test", artist: "Test", appleID: "4", confidence: 0.3)

        XCTAssertEqual(MatchSelector.qualityDescription(for: excellentSong), "Excellent match")
        XCTAssertEqual(MatchSelector.qualityDescription(for: goodSong), "Good match")
        XCTAssertEqual(MatchSelector.qualityDescription(for: fairSong), "Fair match")
        XCTAssertEqual(MatchSelector.qualityDescription(for: poorSong), "Poor match")
    }
}
