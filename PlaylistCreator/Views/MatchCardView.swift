import SwiftUI

/// A card view displaying a single match for user review
///
/// Shows song information, confidence indicators, and visual feedback
/// for the card-based selection interface.
struct MatchCardView: View {
    let match: MatchedSong
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    @StateObject private var previewPlayer = AVPreviewPlayer()
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var playbackError: String?

    // MARK: - Constants

    private let cardWidth: CGFloat = 400
    private let cardHeight: CGFloat = 500
    private let dragThreshold: CGFloat = 100
    private let rotationMultiplier: Double = 0.05

    var body: some View {
        VStack(spacing: 0) {
            // Card content
            cardContent
                .frame(width: cardWidth, height: cardHeight)
                .background(cardBackground)
                .cornerRadius(20)
                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
                .overlay(dragOverlay)
                .offset(offset)
                .rotationEffect(.degrees(Double(offset.width) * rotationMultiplier))
                .gesture(dragGesture)
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Confidence indicator
            confidenceIndicator

            Spacer().frame(height: 20)

            // Song information
            songInformation

            // Preview controls
            if match.previewURL != nil {
                previewControls
            }

            Spacer()

            // Action buttons
            actionButtons
        }
        .padding(30)
        .onDisappear {
            stopPlayback()
        }
    }

    private var confidenceIndicator: some View {
        HStack {
            // Quality emoji
            Text(match.qualityIndicator)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(MatchSelector.qualityDescription(for: match.appleMusicSong))
                    .font(.headline)
                    .foregroundColor(confidenceColor)

                Text("\(Int(match.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var songInformation: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Original song
            if match.originalSong.title.lowercased() != match.appleMusicSong.title.lowercased() ||
               match.originalSong.artist.lowercased() != match.appleMusicSong.artist.lowercased() {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.originalSong.title)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(match.originalSong.artist)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            // Matched song
            VStack(alignment: .leading, spacing: 8) {
                if match.originalSong.title.lowercased() != match.appleMusicSong.title.lowercased() ||
                   match.originalSong.artist.lowercased() != match.appleMusicSong.artist.lowercased() {
                    Text("Apple Music Match")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(match.appleMusicSong.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(match.appleMusicSong.artist)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Reject button
            Button(action: {
                stopPlayback()
                onReject()
            }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Skip")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.leftArrow, modifiers: [])

            // Accept button
            Button(action: {
                stopPlayback()
                onAccept()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Accept")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                offset = value.translation
            }
            .onEnded { value in
                isDragging = false

                // Check if drag exceeds threshold
                if abs(value.translation.width) > dragThreshold {
                    // Stop playback when dismissing
                    stopPlayback()

                    if value.translation.width > 0 {
                        // Swipe right = accept
                        withAnimation(.spring()) {
                            offset = CGSize(width: 500, height: value.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAccept()
                            offset = .zero
                        }
                    } else {
                        // Swipe left = reject
                        withAnimation(.spring()) {
                            offset = CGSize(width: -500, height: value.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onReject()
                            offset = .zero
                        }
                    }
                } else {
                    // Return to center
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                }
            }
    }

    // MARK: - Visual Feedback

    private var dragOverlay: some View {
        Group {
            if isDragging && abs(offset.width) > 50 {
                ZStack {
                    // Accept overlay (right swipe)
                    if offset.width > 0 {
                        Color.green.opacity(0.3)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.green)
                            )
                    }

                    // Reject overlay (left swipe)
                    if offset.width < 0 {
                        Color.red.opacity(0.3)
                            .overlay(
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                            )
                    }
                }
                .cornerRadius(20)
            }
        }
    }

    private var cardBackground: some View {
        Color(NSColor.controlBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }

    private var shadowColor: Color {
        if isDragging {
            return Color.black.opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }

    private var confidenceColor: Color {
        switch match.matchQuality {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }

    // MARK: - Preview Controls

    private var previewControls: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 16) {
                // Play/Pause button
                Button(action: { togglePlayback() }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isPlaying ? .orange : .blue)
                }
                .buttonStyle(.plain)
                .disabled(playbackError != nil)

                VStack(alignment: .leading, spacing: 4) {
                    // Progress indicator
                    if isPlaying {
                        HStack(spacing: 8) {
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()

                            ProgressView(value: currentTime, total: previewPlayer.duration)
                                .progressViewStyle(.linear)

                            Text(formatTime(previewPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    } else if let error = playbackError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Preview Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()
        }
    }

    // MARK: - Playback Methods

    private func togglePlayback() {
        print("🎵 togglePlayback() called, isPlaying: \(isPlaying)")
        Task {
            do {
                if isPlaying {
                    print("⏸️ Pausing playback")
                    previewPlayer.pause()
                    isPlaying = false
                } else {
                    guard let previewURL = match.previewURL else {
                        print("❌ No preview URL available")
                        return
                    }

                    print("▶️ Starting playback for: \(previewURL)")
                    try await previewPlayer.play(previewURL: previewURL)
                    print("✅ Playback started successfully")
                    isPlaying = true
                    playbackError = nil

                    // Update progress
                    startProgressTracking()
                }
            } catch {
                print("❌ Playback error: \(error)")
                playbackError = "Preview unavailable"
                isPlaying = false
            }
        }
    }

    private func stopPlayback() {
        previewPlayer.stop()
        isPlaying = false
        currentTime = 0
    }

    private func startProgressTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard isPlaying else {
                timer.invalidate()
                return
            }
            currentTime = previewPlayer.currentTime
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Excellent Match") {
    let original = Song(title: "Bohemian Rhapsody", artist: "Queen", appleID: nil, confidence: 0.0)
    let matched = Song(title: "Bohemian Rhapsody", artist: "Queen", appleID: "123", confidence: 0.95)
    let match = MatchedSong(originalSong: original, appleMusicSong: matched, matchStatus: .pending)

    return MatchCardView(match: match, onAccept: {}, onReject: {})
        .frame(width: 600, height: 700)
}

#Preview("Good Match with Variation") {
    let original = Song(title: "Stairway to Heaven", artist: "Led Zeppelin", appleID: nil, confidence: 0.0)
    let matched = Song(title: "Stairway To Heaven (Remastered)", artist: "Led Zeppelin", appleID: "456", confidence: 0.8)
    let match = MatchedSong(originalSong: original, appleMusicSong: matched, matchStatus: .pending)

    return MatchCardView(match: match, onAccept: {}, onReject: {})
        .frame(width: 600, height: 700)
}

#Preview("Poor Match") {
    let original = Song(title: "Hotel California", artist: "Eagles", appleID: nil, confidence: 0.0)
    let matched = Song(title: "Hotel California (Live)", artist: "Eagles", appleID: "789", confidence: 0.4)
    let match = MatchedSong(originalSong: original, appleMusicSong: matched, matchStatus: .pending)

    return MatchCardView(match: match, onAccept: {}, onReject: {})
        .frame(width: 600, height: 700)
}
