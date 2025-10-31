import Foundation
import SwiftUI

/// ViewModel for managing the card-based match selection workflow
///
/// Handles state management for navigating through ambiguous matches,
/// accepting/rejecting songs, undo functionality, and batch operations.
@MainActor
class MatchSelectionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of matches being reviewed
    @Published private(set) var matches: [MatchedSong]

    /// Current card index in the stack
    @Published private(set) var currentIndex: Int = 0

    // MARK: - Private Properties

    /// History of actions for undo functionality
    private var actionHistory: [(index: Int, previousStatus: MatchStatus)] = []

    // MARK: - Initialization

    init(matches: [MatchedSong]) {
        self.matches = matches
    }

    // MARK: - Computed Properties

    /// Current match being reviewed (nil if complete)
    var currentMatch: MatchedSong? {
        guard currentIndex < matches.count else { return nil }
        return matches[currentIndex]
    }

    /// Whether the user has reviewed all matches
    var isComplete: Bool {
        return currentIndex >= matches.count
    }

    /// Progress through the match review (0.0 to 1.0)
    var progress: Double {
        guard !matches.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(matches.count)
    }

    /// Number of matches remaining to review
    var remainingCount: Int {
        return max(0, matches.count - currentIndex)
    }

    /// Whether undo is available
    var canUndo: Bool {
        return !actionHistory.isEmpty
    }

    /// Matches that have been accepted
    var acceptedMatches: [MatchedSong] {
        return matches.filter { $0.matchStatus == .selected }
    }

    /// Matches that have been rejected
    var rejectedMatches: [MatchedSong] {
        return matches.filter { $0.matchStatus == .skipped }
    }

    // MARK: - Navigation Actions

    /// Accept the current match and move to the next
    func acceptCurrentMatch() {
        guard let current = currentMatch else { return }

        // Save to history for undo
        actionHistory.append((index: currentIndex, previousStatus: current.matchStatus))

        // Update match status
        matches[currentIndex].matchStatus = .selected

        // Move to next
        currentIndex += 1
    }

    /// Reject the current match and move to the next
    func rejectCurrentMatch() {
        guard let current = currentMatch else { return }

        // Save to history for undo
        actionHistory.append((index: currentIndex, previousStatus: current.matchStatus))

        // Update match status
        matches[currentIndex].matchStatus = .skipped

        // Move to next
        currentIndex += 1
    }

    /// Undo the last action and return to the previous match
    func undo() {
        guard let lastAction = actionHistory.popLast() else { return }

        // Restore previous state
        matches[lastAction.index].matchStatus = lastAction.previousStatus

        // Return to that index
        currentIndex = lastAction.index
    }

    // MARK: - Batch Operations

    /// Accept all remaining matches
    func acceptAll() {
        // Record all actions for potential undo
        for index in currentIndex..<matches.count {
            actionHistory.append((index: index, previousStatus: matches[index].matchStatus))
            matches[index].matchStatus = .selected
        }

        // Mark as complete
        currentIndex = matches.count
    }

    /// Reject all remaining matches
    func rejectAll() {
        // Record all actions for potential undo
        for index in currentIndex..<matches.count {
            actionHistory.append((index: index, previousStatus: matches[index].matchStatus))
            matches[index].matchStatus = .skipped
        }

        // Mark as complete
        currentIndex = matches.count
    }

    /// Accept all matches above a confidence threshold
    /// - Parameter threshold: Minimum confidence to accept (default: 0.9)
    func acceptAllHighConfidence(threshold: Double = 0.9) {
        for index in matches.indices where matches[index].confidence >= threshold {
            if matches[index].matchStatus == .pending {
                actionHistory.append((index: index, previousStatus: matches[index].matchStatus))
                matches[index].matchStatus = .selected
            }
        }
    }

    /// Reject all matches below a confidence threshold
    /// - Parameter threshold: Maximum confidence to reject (default: 0.5)
    func rejectAllLowConfidence(threshold: Double = 0.5) {
        for index in matches.indices where matches[index].confidence < threshold {
            if matches[index].matchStatus == .pending {
                actionHistory.append((index: index, previousStatus: matches[index].matchStatus))
                matches[index].matchStatus = .skipped
            }
        }
    }

    // MARK: - Reset

    /// Reset all matches to pending status and return to the beginning
    func reset() {
        for index in matches.indices {
            matches[index].matchStatus = .pending
        }
        currentIndex = 0
        actionHistory.removeAll()
    }

    // MARK: - Utility Methods

    /// Get selection summary statistics
    func getSelectionSummary() -> MatchSelector.SelectionSummary {
        return MatchSelector.generateSelectionSummary(matches)
    }
}
