import SwiftUI

/// Main view for the card-based match selection interface
///
/// Presents ambiguous matches in a card stack format, allowing users to
/// swipe or tap to accept/reject matches. Shows progress and provides
/// batch operations.
struct MatchSelectionView: View {
    @StateObject private var viewModel: MatchSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    init(matches: [MatchedSong], onComplete: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: MatchSelectionViewModel(matches: matches))
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main content
            if viewModel.isComplete {
                completionView
            } else {
                cardStackView
            }

            Divider()

            // Footer with controls
            footerView
        }
        .frame(minWidth: 700, minHeight: 800)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Review Matches")
                    .font(.title)
                    .fontWeight(.semibold)

                Spacer()

                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            // Progress bar
            progressBar
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(viewModel.remainingCount) remaining")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if viewModel.canUndo {
                    Button(action: { viewModel.undo() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .keyboardShortcut("z", modifiers: .command)
                }
            }

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
        }
    }

    // MARK: - Card Stack

    private var cardStackView: some View {
        ZStack {
            if let current = viewModel.currentMatch {
                MatchCardView(
                    match: current,
                    onAccept: { viewModel.acceptCurrentMatch() },
                    onReject: { viewModel.rejectCurrentMatch() }
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(), value: viewModel.currentIndex)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Review Complete!")
                .font(.title)
                .fontWeight(.bold)

            selectionSummary

            HStack(spacing: 16) {
                Button("Review Again") {
                    viewModel.reset()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Continue") {
                    onComplete()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectionSummary: some View {
        VStack(spacing: 16) {
            Text("Selection Summary")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 40) {
                summaryItem(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    count: viewModel.acceptedMatches.count,
                    label: "Accepted"
                )

                summaryItem(
                    icon: "xmark.circle.fill",
                    color: .red,
                    count: viewModel.rejectedMatches.count,
                    label: "Skipped"
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func summaryItem(icon: String, color: Color, count: Int, label: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 16) {
            // Batch operations menu
            Menu {
                Button("Accept All High Confidence (≥90%)") {
                    viewModel.acceptAllHighConfidence()
                }

                Button("Reject All Low Confidence (<50%)") {
                    viewModel.rejectAllLowConfidence()
                }

                Divider()

                Button("Accept All Remaining") {
                    viewModel.acceptAll()
                }

                Button("Reject All Remaining") {
                    viewModel.rejectAll()
                }
                .foregroundColor(.red)

                Divider()

                Button("Reset All") {
                    viewModel.reset()
                }
                .foregroundColor(.orange)
            } label: {
                HStack {
                    Image(systemName: "ellipsis.circle")
                    Text("Batch Actions")
                }
            }
            .disabled(viewModel.isComplete)

            Spacer()

            // Keyboard shortcuts hint
            if !viewModel.isComplete {
                Text("← Skip  |  → Accept  |  ⌘Z Undo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Preview

#Preview("With Matches") {
    let matches = [
        MatchedSong(
            originalSong: Song(title: "Bohemian Rhapsody", artist: "Queen", appleID: nil, confidence: 0.0),
            appleMusicSong: Song(title: "Bohemian Rhapsody", artist: "Queen", appleID: "1", confidence: 0.95),
            matchStatus: .pending
        ),
        MatchedSong(
            originalSong: Song(title: "Stairway to Heaven", artist: "Led Zeppelin", appleID: nil, confidence: 0.0),
            appleMusicSong: Song(title: "Stairway To Heaven (Remastered)", artist: "Led Zeppelin", appleID: "2", confidence: 0.8),
            matchStatus: .pending
        ),
        MatchedSong(
            originalSong: Song(title: "Hotel California", artist: "Eagles", appleID: nil, confidence: 0.0),
            appleMusicSong: Song(title: "Hotel California (Live)", artist: "Eagles", appleID: "3", confidence: 0.6),
            matchStatus: .pending
        )
    ]

    return MatchSelectionView(matches: matches)
}

#Preview("Empty") {
    MatchSelectionView(matches: [])
}
