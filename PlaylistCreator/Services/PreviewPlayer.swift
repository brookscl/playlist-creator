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
class AVPreviewPlayer: PreviewPlayer, ObservableObject {
    nonisolated(unsafe) private var player: AVPlayer?
    nonisolated(unsafe) private var playerItem: AVPlayerItem?
    nonisolated(unsafe) private var timeObserver: Any?

    // MARK: - Published Properties

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 30

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
        print("🎧 AVPreviewPlayer.play() called with URL: \(previewURL)")

        // Stop any current playback
        stop()

        // Validate URL scheme
        guard previewURL.scheme == "http" || previewURL.scheme == "https" else {
            print("❌ Invalid URL scheme: \(previewURL.scheme ?? "nil")")
            throw PreviewPlayerError.invalidURL
        }
        print("✅ URL validation passed")

        // Create player with URL directly (AVPlayer handles async loading automatically)
        let newPlayer = AVPlayer(url: previewURL)
        player = newPlayer
        print("✅ Created AVPlayer with URL")

        // Enable automatic waiting (allows playback to start even while buffering)
        if #available(macOS 10.15, *) {
            newPlayer.automaticallyWaitsToMinimizeStalling = true
        }

        // Set volume
        newPlayer.volume = 1.0
        print("✅ Set volume to 1.0")

        // Start playback (AVPlayer will buffer and play automatically)
        newPlayer.play()
        isPlaying = true
        print("▶️ Playback started! AVPlayer will buffer automatically")

        // Add time observer for progress updates
        addTimeObserver()
        print("✅ Time observer added")

        // Monitor for when duration becomes available
        Task {
            await MainActor.run {
                if let item = newPlayer.currentItem {
                    if item.duration.isNumeric && !item.duration.isIndefinite {
                        self.duration = item.duration.seconds
                        print("✅ Duration available: \(self.duration) seconds")
                    }
                }
            }
        }
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
        print("📊 Current item status: \(item.status.rawValue)")

        // Check if already ready
        if item.status == .readyToPlay {
            print("✅ Already ready!")
            return
        }

        // Check if already failed
        if item.status == .failed {
            print("❌ Already failed! Error: \(item.error?.localizedDescription ?? "unknown")")
            if let error = item.error {
                print("   Error domain: \((error as NSError).domain)")
                print("   Error code: \((error as NSError).code)")
            }
            throw PreviewPlayerError.loadFailed
        }

        // Wait for status to change with timeout
        print("⏳ Waiting for status change...")
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            print("⏰ Timeout reached!")
        }

        let statusTask = Task {
            for await status in item.publisher(for: \.status).values {
                print("📊 Status changed to: \(status.rawValue)")
                switch status {
                case .readyToPlay:
                    print("✅ Status is now ready!")
                    return
                case .failed:
                    print("❌ Status changed to failed!")
                    if let error = item.error {
                        print("   Error: \(error.localizedDescription)")
                        print("   Domain: \((error as NSError).domain)")
                        print("   Code: \((error as NSError).code)")
                        if (error as NSError).domain == NSURLErrorDomain {
                            throw PreviewPlayerError.networkError
                        }
                    }
                    throw PreviewPlayerError.loadFailed
                case .unknown:
                    print("⚠️ Status is unknown, continuing...")
                    continue
                @unknown default:
                    continue
                }
            }
            throw PreviewPlayerError.loadFailed
        }

        // Race between status change and timeout
        try await statusTask.value
        timeoutTask.cancel()
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
