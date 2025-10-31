import XCTest
@testable import PlaylistCreator

/// Tests for MatchSelectionViewModel that manages the card-based match selection workflow
@MainActor
final class MatchSelectionViewModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitializationWithMatches() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        XCTAssertEqual(viewModel.matches.count, 3)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.currentMatch?.originalSong.title, "Song 1")
        XCTAssertFalse(viewModel.isComplete)
    }

    func testInitializationWithEmptyMatches() {
        let viewModel = MatchSelectionViewModel(matches: [])

        XCTAssertEqual(viewModel.matches.count, 0)
        XCTAssertNil(viewModel.currentMatch)
        XCTAssertTrue(viewModel.isComplete)
    }

    // MARK: - Navigation Tests

    func testAcceptCurrentMatch() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        XCTAssertEqual(viewModel.currentIndex, 0)

        viewModel.acceptCurrentMatch()

        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(viewModel.matches[0].matchStatus, .selected)
    }

    func testRejectCurrentMatch() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.rejectCurrentMatch()

        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(viewModel.matches[0].matchStatus, .skipped)
    }

    func testNavigationThroughAllMatches() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        XCTAssertFalse(viewModel.isComplete)

        viewModel.acceptCurrentMatch() // 0 -> 1
        XCTAssertFalse(viewModel.isComplete)

        viewModel.rejectCurrentMatch() // 1 -> 2
        XCTAssertFalse(viewModel.isComplete)

        viewModel.acceptCurrentMatch() // 2 -> complete
        XCTAssertTrue(viewModel.isComplete)
    }

    // MARK: - Undo Tests

    func testUndoAfterAccept() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.acceptCurrentMatch()
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertTrue(viewModel.canUndo)

        viewModel.undo()
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.matches[0].matchStatus, .pending)
    }

    func testUndoAfterReject() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.rejectCurrentMatch()
        XCTAssertEqual(viewModel.currentIndex, 1)

        viewModel.undo()
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.matches[0].matchStatus, .pending)
    }

    func testUndoNotAvailableAtStart() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        XCTAssertFalse(viewModel.canUndo)
    }

    func testMultipleUndos() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.acceptCurrentMatch() // 0 -> 1
        viewModel.rejectCurrentMatch() // 1 -> 2
        XCTAssertEqual(viewModel.currentIndex, 2)

        viewModel.undo() // 2 -> 1
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(viewModel.matches[1].matchStatus, .pending)

        viewModel.undo() // 1 -> 0
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.matches[0].matchStatus, .pending)

        XCTAssertFalse(viewModel.canUndo)
    }

    // MARK: - Progress Tests

    func testProgressCalculation() {
        let matches = createTestMatches(count: 4)
        let viewModel = MatchSelectionViewModel(matches: matches)

        XCTAssertEqual(viewModel.progress, 0.0, accuracy: 0.01)

        viewModel.acceptCurrentMatch() // 1/4
        XCTAssertEqual(viewModel.progress, 0.25, accuracy: 0.01)

        viewModel.acceptCurrentMatch() // 2/4
        XCTAssertEqual(viewModel.progress, 0.5, accuracy: 0.01)

        viewModel.acceptCurrentMatch() // 3/4
        XCTAssertEqual(viewModel.progress, 0.75, accuracy: 0.01)

        viewModel.acceptCurrentMatch() // 4/4
        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.01)
    }

    func testRemainingCount() {
        let matches = createTestMatches(count: 5)
        let viewModel = MatchSelectionViewModel(matches: matches)

        XCTAssertEqual(viewModel.remainingCount, 5)

        viewModel.acceptCurrentMatch()
        XCTAssertEqual(viewModel.remainingCount, 4)

        viewModel.acceptCurrentMatch()
        XCTAssertEqual(viewModel.remainingCount, 3)
    }

    // MARK: - Selection Summary Tests

    func testAcceptedMatches() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.acceptCurrentMatch()
        viewModel.rejectCurrentMatch()
        viewModel.acceptCurrentMatch()

        let accepted = viewModel.acceptedMatches
        XCTAssertEqual(accepted.count, 2)
        XCTAssertTrue(accepted.allSatisfy { $0.matchStatus == .selected })
    }

    func testRejectedMatches() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.acceptCurrentMatch()
        viewModel.rejectCurrentMatch()
        viewModel.acceptCurrentMatch()

        let rejected = viewModel.rejectedMatches
        XCTAssertEqual(rejected.count, 1)
        XCTAssertTrue(rejected.allSatisfy { $0.matchStatus == .skipped })
    }

    // MARK: - Batch Operations Tests

    func testAcceptAll() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.acceptAll()

        XCTAssertTrue(viewModel.isComplete)
        XCTAssertTrue(viewModel.matches.allSatisfy { $0.matchStatus == .selected })
    }

    func testRejectAll() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.rejectAll()

        XCTAssertTrue(viewModel.isComplete)
        XCTAssertTrue(viewModel.matches.allSatisfy { $0.matchStatus == .skipped })
    }

    func testAcceptAllHighConfidence() {
        // Create mix of high and low confidence matches
        var matches = [MatchedSong]()
        matches.append(createTestMatch(index: 1, confidence: 0.95)) // high
        matches.append(createTestMatch(index: 2, confidence: 0.6))  // low
        matches.append(createTestMatch(index: 3, confidence: 0.85)) // medium
        matches.append(createTestMatch(index: 4, confidence: 0.92)) // high

        let viewModel = MatchSelectionViewModel(matches: matches)
        viewModel.acceptAllHighConfidence(threshold: 0.9)

        XCTAssertEqual(viewModel.matches[0].matchStatus, .selected)
        XCTAssertEqual(viewModel.matches[1].matchStatus, .pending)
        XCTAssertEqual(viewModel.matches[2].matchStatus, .pending)
        XCTAssertEqual(viewModel.matches[3].matchStatus, .selected)
    }

    func testRejectAllLowConfidence() {
        var matches = [MatchedSong]()
        matches.append(createTestMatch(index: 1, confidence: 0.95))
        matches.append(createTestMatch(index: 2, confidence: 0.6))
        matches.append(createTestMatch(index: 3, confidence: 0.4))

        let viewModel = MatchSelectionViewModel(matches: matches)
        viewModel.rejectAllLowConfidence(threshold: 0.7)

        XCTAssertEqual(viewModel.matches[0].matchStatus, .pending)
        XCTAssertEqual(viewModel.matches[1].matchStatus, .skipped)
        XCTAssertEqual(viewModel.matches[2].matchStatus, .skipped)
    }

    // MARK: - Reset Tests

    func testReset() {
        let matches = createTestMatches(count: 3)
        let viewModel = MatchSelectionViewModel(matches: matches)

        viewModel.acceptCurrentMatch()
        viewModel.rejectCurrentMatch()

        XCTAssertEqual(viewModel.currentIndex, 2)

        viewModel.reset()

        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertTrue(viewModel.matches.allSatisfy { $0.matchStatus == .pending })
        XCTAssertFalse(viewModel.canUndo)
    }

    // MARK: - Helper Methods

    private func createTestMatches(count: Int) -> [MatchedSong] {
        return (1...count).map { createTestMatch(index: $0, confidence: 0.8) }
    }

    private func createTestMatch(index: Int, confidence: Double) -> MatchedSong {
        let originalSong = Song(title: "Song \(index)", artist: "Artist \(index)", appleID: nil, confidence: 0.0)
        let appleMusicSong = Song(title: "Song \(index)", artist: "Artist \(index)", appleID: "\(index)", confidence: confidence)
        return MatchedSong(originalSong: originalSong, appleMusicSong: appleMusicSong, matchStatus: .pending)
    }
}
