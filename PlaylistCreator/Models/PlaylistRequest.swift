import Foundation

/// Represents a complete playlist creation request and tracks the entire workflow state
///
/// PlaylistRequest is the central data model that encapsulates everything related to creating
/// a single playlist from source content. It tracks:
/// - Source content (file paths or URLs)
/// - Processing progress and status
/// - Extracted songs from transcripts
/// - Matched songs with Apple Music
/// - Final playlist information
/// - Error states and messages
///
/// This model persists throughout the entire workflow and can be serialized for storage/recovery.
struct PlaylistRequest: Codable, Identifiable {
    /// Unique identifier for this request
    let id: UUID
    
    /// Current processing status
    var status: ProcessingStatus
    
    // MARK: - Source Content
    
    /// Source URL for remote content (YouTube, podcasts, etc.)
    let sourceURL: URL?
    
    /// Local file path for uploaded content
    let sourceFilePath: String?
    
    // MARK: - Processing Data
    
    /// Extracted transcript from audio content
    var transcript: String?
    
    /// Songs extracted from transcript using AI
    var extractedSongs: [Song]
    
    /// Songs matched against Apple Music catalog
    var matchedSongs: [MatchedSong]
    
    // MARK: - Playlist Information
    
    /// Apple Music playlist identifier (set when playlist is created)
    var playlistID: String?
    
    /// Name of the created playlist
    var playlistName: String?
    
    // MARK: - Metadata
    
    /// Timestamp when request was created
    let createdAt: Date
    
    /// Timestamp when processing completed (successfully or with error)
    var completedAt: Date?
    
    /// Error message if processing failed
    var errorMessage: String?
    
    // MARK: - Initialization
    
    /// Creates a new PlaylistRequest for URL-based content
    /// - Parameter sourceURL: The URL to process
    init(sourceURL: URL) {
        self.id = UUID()
        self.status = .idle
        self.sourceURL = sourceURL
        self.sourceFilePath = nil
        self.transcript = nil
        self.extractedSongs = []
        self.matchedSongs = []
        self.playlistID = nil
        self.playlistName = nil
        self.createdAt = Date()
        self.completedAt = nil
        self.errorMessage = nil
    }
    
    /// Creates a new PlaylistRequest for local file content
    /// - Parameter sourceFilePath: Path to the local file
    init(sourceFilePath: String) {
        self.id = UUID()
        self.status = .idle
        self.sourceURL = nil
        self.sourceFilePath = sourceFilePath
        self.transcript = nil
        self.extractedSongs = []
        self.matchedSongs = []
        self.playlistID = nil
        self.playlistName = nil
        self.createdAt = Date()
        self.completedAt = nil
        self.errorMessage = nil
    }
    
    /// Creates a new empty PlaylistRequest (for testing or manual setup)
    init() {
        self.id = UUID()
        self.status = .idle
        self.sourceURL = nil
        self.sourceFilePath = nil
        self.transcript = nil
        self.extractedSongs = []
        self.matchedSongs = []
        self.playlistID = nil
        self.playlistName = nil
        self.createdAt = Date()
        self.completedAt = nil
        self.errorMessage = nil
    }
    
    /// Creates a PlaylistRequest with specific ID and timestamp (for testing/decoding)
    init(id: UUID, createdAt: Date) {
        self.id = id
        self.status = .idle
        self.sourceURL = nil
        self.sourceFilePath = nil
        self.transcript = nil
        self.extractedSongs = []
        self.matchedSongs = []
        self.playlistID = nil
        self.playlistName = nil
        self.createdAt = createdAt
        self.completedAt = nil
        self.errorMessage = nil
    }
}

// MARK: - Convenience Properties

extension PlaylistRequest {
    /// Returns true if the request has a source (URL or file path)
    var hasSource: Bool {
        return sourceURL != nil || sourceFilePath != nil
    }
    
    /// Returns a display name for the source content
    var sourceDisplayName: String {
        if let url = sourceURL {
            return url.lastPathComponent
        } else if let filePath = sourceFilePath {
            return URL(fileURLWithPath: filePath).lastPathComponent
        } else {
            return "Unknown Source"
        }
    }
    
    /// Returns true if processing has completed (successfully or with error)
    var isFinished: Bool {
        return status == .complete || status == .error
    }
    
    /// Returns true if the request can be started or restarted
    var canProcess: Bool {
        return hasSource && status.canStartProcessing
    }
    
    /// Returns the number of songs that will be included in the playlist
    var includedSongCount: Int {
        return matchedSongs.filter { $0.isIncludedInPlaylist }.count
    }
    
    /// Returns the number of songs requiring user review
    var pendingSongCount: Int {
        return matchedSongs.filter { $0.requiresUserAction }.count
    }
    
    /// Returns processing duration if completed
    var processingDuration: TimeInterval? {
        guard let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(createdAt)
    }
    
    /// Returns a progress percentage (0.0 to 1.0) based on current status
    var progressPercentage: Double {
        switch status {
        case .idle:
            return 0.0
        case .processing:
            return 0.5
        case .complete:
            return 1.0
        case .error:
            return 0.0
        }
    }
}

// MARK: - State Management

extension PlaylistRequest {
    /// Marks the request as completed successfully
    mutating func markCompleted() {
        status = .complete
        completedAt = Date()
        errorMessage = nil
    }
    
    /// Marks the request as failed with an error message
    mutating func markFailed(with error: String) {
        status = .error
        completedAt = Date()
        errorMessage = error
    }
    
    /// Starts processing by setting status to processing
    mutating func startProcessing() {
        guard canProcess else { return }
        status = .processing
        errorMessage = nil
        completedAt = nil
    }
    
    /// Resets the request to initial state (keeping source information)
    mutating func reset() {
        status = .idle
        transcript = nil
        extractedSongs = []
        matchedSongs = []
        playlistID = nil
        playlistName = nil
        completedAt = nil
        errorMessage = nil
    }
}

// MARK: - CustomStringConvertible

extension PlaylistRequest: CustomStringConvertible {
    var description: String {
        let source = sourceDisplayName
        let songCount = includedSongCount
        return "PlaylistRequest(\(id.uuidString.prefix(8))): \(source) - \(status.displayDescription) - \(songCount) songs"
    }
}