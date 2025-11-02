import Foundation
import AVFoundation

/// Protocol for playing 30-second song preview audio
@MainActor
protocol PreviewPlayer {
    /// Whether playback is currently active
    var isPlaying: Bool { get }

    /// Current playback position in seconds
    var currentTime: TimeInterval { get }

    /// Total duration of the preview in seconds (typically 30)
    var duration: TimeInterval { get }

    /// Playback volume (0.0 to 1.0)
    var volume: Float { get set }

    /// Play a preview from the given URL
    /// - Parameter previewURL: URL to the preview audio file
    /// - Throws: PreviewPlayerError if playback cannot start
    func play(previewURL: URL) async throws

    /// Pause playback, preserving current position
    func pause()

    /// Stop playback and reset to beginning
    func stop()

    /// Seek to a specific time position
    /// - Parameter time: Time in seconds to seek to
    func seek(to time: TimeInterval)
}

/// Errors that can occur during preview playback
enum PreviewPlayerError: Error, Equatable, LocalizedError {
    case invalidURL
    case loadFailed
    case networkError
    case playbackFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid preview URL"
        case .loadFailed:
            return "Failed to load preview"
        case .networkError:
            return "Network error while loading preview"
        case .playbackFailed:
            return "Playback failed"
        }
    }
}

/// Concrete implementation of PreviewPlayer using AVPlayer
@MainActor
class AVPreviewPlayer: PreviewPlayer {
    nonisolated(unsafe) private var player: AVPlayer?
    nonisolated(unsafe) private var playerItem: AVPlayerItem?
    nonisolated(unsafe) private var timeObserver: Any?

    // MARK: - Published Properties

    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 30

    var volume: Float {
        get { Float(player?.volume ?? 1.0) }
        set { player?.volume = newValue }
    }

    // MARK: - Initialization

    init() {}

    deinit {
        cleanup()
    }

    // MARK: - PreviewPlayer Protocol

    func play(previewURL: URL) async throws {
        // Stop any current playback
        stop()

        // Validate URL scheme
        guard previewURL.scheme == "http" || previewURL.scheme == "https" else {
            throw PreviewPlayerError.invalidURL
        }

        // Create player item
        let item = AVPlayerItem(url: previewURL)
        playerItem = item

        // Create player
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        // Wait for player to be ready
        try await waitForPlayerReady(item: item)

        // Update duration if available
        if item.duration.isNumeric && !item.duration.isIndefinite {
            duration = item.duration.seconds
        }

        // Start playback
        newPlayer.play()
        isPlaying = true

        // Add time observer for progress updates
        addTimeObserver()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        cleanup()
        isPlaying = false
        currentTime = 0
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
    }

    // MARK: - Private Methods

    private func waitForPlayerReady(item: AVPlayerItem) async throws {
        // Check if already ready
        if item.status == .readyToPlay {
            return
        }

        // Wait for status to change
        for await status in item.publisher(for: \.status).values {
            switch status {
            case .readyToPlay:
                return
            case .failed:
                if let error = item.error as? NSError {
                    // Check for network errors
                    if error.domain == NSURLErrorDomain {
                        throw PreviewPlayerError.networkError
                    }
                }
                throw PreviewPlayerError.loadFailed
            case .unknown:
                continue
            @unknown default:
                continue
            }
        }

        throw PreviewPlayerError.loadFailed
    }

    private func addTimeObserver() {
        guard let player = player else { return }

        // Update current time every 0.1 seconds
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.currentTime = time.seconds
            }
        }
    }

    nonisolated private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player = nil
        playerItem = nil
    }
}
