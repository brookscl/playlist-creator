import Foundation
import Combine

/// Manages the complete workflow from file upload to playlist creation
@MainActor
class WorkflowViewModel: ObservableObject {

    // MARK: - Workflow Phases

    enum WorkflowPhase {
        case fileInput          // File upload/URL input
        case transcription      // Audio transcription
        case musicExtraction    // Extracting music mentions from transcript
        case musicSearch        // Searching Apple Music for songs
        case matchSelection     // User reviewing and selecting matches
        case playlistCreation   // Creating the playlist (future)
        case complete           // Workflow complete
        case error(String)      // Error state
    }

    // MARK: - Published Properties

    @Published var currentPhase: WorkflowPhase = .fileInput
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""

    // Workflow data
    @Published var transcript: Transcript?
    @Published var extractedSongs: [Song] = []
    @Published var matchedSongs: [MatchedSong] = []

    // MARK: - Services

    private let musicExtractor: MusicExtractor
    private let musicSearcher: MusicSearcher
    private let playlistCreator: PlaylistCreator

    // Playlist result
    @Published var createdPlaylist: CreatedPlaylist?
    @Published var playlistError: String?

    // MARK: - Initialization

    init(musicExtractor: MusicExtractor = serviceContainer.resolve(MusicExtractor.self),
         musicSearcher: MusicSearcher = serviceContainer.resolve(MusicSearcher.self),
         playlistCreator: PlaylistCreator = serviceContainer.resolve(PlaylistCreator.self)) {
        self.musicExtractor = musicExtractor
        self.musicSearcher = musicSearcher
        self.playlistCreator = playlistCreator
    }

    // MARK: - Workflow Control

    /// Called after transcription is complete to continue the workflow
    func continueAfterTranscription(_ transcript: Transcript) async {
        self.transcript = transcript
        await extractMusicMentions()
    }

    /// Phase 1: Extract music mentions from transcript using AI
    private func extractMusicMentions() async {
        guard let transcript = transcript else { return }

        currentPhase = .musicExtraction
        isProcessing = true
        progress = 0.0
        statusMessage = "Extracting music mentions from transcript..."

        do {
            let songs = try await musicExtractor.extractSongs(from: transcript)
            extractedSongs = songs

            progress = 1.0
            statusMessage = "Found \(songs.count) song\(songs.count == 1 ? "" : "s")"

            // Automatically continue to music search
            await searchAppleMusic()

        } catch {
            currentPhase = .error("Music extraction failed: \(error.localizedDescription)")
            isProcessing = false
        }
    }

    /// Phase 2: Search Apple Music for extracted songs
    private func searchAppleMusic() async {
        currentPhase = .musicSearch
        isProcessing = true
        progress = 0.0
        statusMessage = "Requesting Apple Music access..."

        // Request authorization if needed
        print("🔍 Checking MusicSearcher type: \(type(of: musicSearcher))")

        if #available(macOS 12.0, *) {
            // Check for iTunes Search API client (no auth needed)
            if let _ = musicSearcher as? AppleMusicSearchService<ITunesMusicKitClient> {
                print("✅ Using iTunes Search API (no authorization required)")
            }
            // Check for real MusicKit client (requires auth)
            else if let service = musicSearcher as? AppleMusicSearchService<RealMusicKitClient> {
                print("✅ Using AppleMusicSearchService with RealMusicKitClient")
                do {
                    print("📱 Requesting Apple Music authorization...")
                    try await service.requestAuthorization()
                    print("✅ Apple Music authorization granted")
                } catch {
                    print("❌ Authorization failed: \(error)")
                    currentPhase = .error("Apple Music authorization denied. Please allow access in System Settings.")
                    isProcessing = false
                    return
                }
            } else {
                print("⚠️ Unknown MusicSearcher type")
            }
        }

        statusMessage = "Searching Apple Music catalog..."

        var allMatches: [MatchedSong] = []
        let totalSongs = extractedSongs.count

        // Search for each song
        for (index, song) in extractedSongs.enumerated() {
            statusMessage = "Searching Apple Music... (\(index + 1)/\(totalSongs))"
            progress = Double(index) / Double(totalSongs)

            do {
                // Search for the song
                let searchResults = try await musicSearcher.search(for: song)

                if let bestResult = searchResults.first {
                    // Create matched song using MatchSelector
                    let match = MatchSelector.createMatchedSong(
                        original: song,
                        searchResult: bestResult
                    )
                    print("✅ Created match: \(match.appleMusicSong.title) by \(match.appleMusicSong.artist)")
                    print("   Preview URL: \(match.previewURL?.absoluteString ?? "NONE")")
                    print("   Confidence: \(Int(match.confidence * 100))%")
                    allMatches.append(match)
                } else {
                    // No results found - create a match with status pending for user review
                    let noMatchSong = Song(
                        title: "No match found",
                        artist: song.artist,
                        appleID: nil,
                        confidence: 0.0
                    )
                    let noMatch = MatchedSong(
                        originalSong: song,
                        appleMusicSong: noMatchSong,
                        matchStatus: .skipped
                    )
                    allMatches.append(noMatch)
                }
            } catch {
                // Search failed for this song - skip it
                let errorMessage = "Search failed for \(song.title) by \(song.artist): \(error)"
                print(errorMessage)

                // Get detailed error info
                if let musicError = error as? MusicSearchError {
                    print("  MusicSearchError type: \(musicError)")
                    print("  Description: \(musicError.localizedDescription)")
                } else {
                    print("  Error type: \(type(of: error))")
                    print("  Description: \(error.localizedDescription)")
                }

                let noMatchSong = Song(
                    title: "Search failed",
                    artist: song.artist,
                    appleID: nil,
                    confidence: 0.0
                )
                let failedMatch = MatchedSong(
                    originalSong: song,
                    appleMusicSong: noMatchSong,
                    matchStatus: .skipped
                )
                allMatches.append(failedMatch)
            }
        }

        matchedSongs = allMatches
        progress = 1.0

        // Generate summary
        let summary = MatchSelector.generateSelectionSummary(allMatches)
        statusMessage = "Found \(summary.totalMatches) matches: \(summary.autoSelected) auto-selected, \(summary.requiresReview) need review"

        // Move to match selection phase
        currentPhase = .matchSelection
        isProcessing = false
    }

    /// Called when user finishes reviewing matches
    func completeMatchSelection() async {
        await createPlaylist()
    }

    /// Phase 3: Create playlist in Apple Music
    private func createPlaylist() async {
        currentPhase = .playlistCreation
        isProcessing = true
        progress = 0.0
        statusMessage = "Creating playlist..."

        // Get selected songs only
        let selectedSongs = matchedSongs.filter { $0.isIncludedInPlaylist }

        guard !selectedSongs.isEmpty else {
            currentPhase = .error("No songs selected for playlist")
            isProcessing = false
            return
        }

        // Generate playlist name
        let playlistName = generatePlaylistName()
        statusMessage = "Creating '\(playlistName)' with \(selectedSongs.count) songs..."

        do {
            // Create the playlist
            let playlist = try await playlistCreator.createPlaylist(
                name: playlistName,
                songs: selectedSongs
            )

            createdPlaylist = playlist
            progress = 1.0
            statusMessage = "Playlist created successfully!"

            // Move to complete phase
            currentPhase = .complete
            isProcessing = false

        } catch {
            print("❌ Playlist creation failed: \(error)")

            // Handle the error
            playlistError = error.localizedDescription
            currentPhase = .error("Failed to create playlist: \(error.localizedDescription)")
            isProcessing = false
        }
    }

    /// Generate a meaningful playlist name
    private func generatePlaylistName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: Date())
        return "Playlist Creator - \(dateString)"
    }

    /// Reset the entire workflow
    func reset() {
        currentPhase = .fileInput
        isProcessing = false
        progress = 0.0
        statusMessage = ""
        transcript = nil
        extractedSongs = []
        matchedSongs = []
    }
}
