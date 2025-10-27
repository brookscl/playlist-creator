# Playlist Creator - Development Checklist

## Foundation Week (Week 1)

### 1.1: Project Setup and Basic Architecture
- [x] Create new Xcode project targeting macOS with SwiftUI
- [x] Configure Info.plist with necessary permissions for file access and network requests
- [x] Add MusicKit capability to the project
- [x] Create basic ContentView with "Playlist Creator" title
- [x] Set up proper folder structure: Models/, Services/, Views/, Tests/
- [x] Create basic test target and ensure it compiles
- [x] Write simple smoke test that verifies the app launches
- [x] Verify project builds and runs successfully
- [x] Ensure clean architecture is ready for expansion

### 1.2: Core Data Models with Tests
- [x] Write comprehensive unit tests FIRST for all data models (118+ tests implemented)
- [x] Implement Song struct with: title, artist, appleID (optional), confidence score
- [x] Implement ProcessingStatus enum: idle, processing, complete, error
- [x] Implement MatchStatus enum: auto, pending, selected, skipped
- [x] Create MatchedSong model to track song matching workflow
- [x] Create PlaylistRequest model to track workflow state
- [x] Add Codable conformance where appropriate
- [x] Include proper validation and edge case handling
- [x] Write tests for model serialization/deserialization
- [x] Test model creation and initialization
- [x] Test property validation and edge cases
- [x] Test Codable encoding/decoding
- [x] Test equality comparisons where relevant
- [x] Test invalid data handling
- [x] Integrate models into main app target
- [x] Ensure all tests pass with good coverage
- [x] Add documentation for each model's purpose

### 1.3: Service Layer Architecture and Dependency Injection
- [x] Write tests first for all service protocols and implementations (139+ total tests)
- [x] Create AudioProcessor protocol for file/URL audio extraction
- [x] Create Transcriber protocol for audio to text conversion
- [x] Create MusicExtractor protocol for finding music mentions in text
- [x] Create MusicSearcher protocol for Apple Music catalog search
- [x] Create PlaylistCreator protocol for Apple Music playlist creation
- [x] Implement ServiceContainer for dependency injection
- [x] Create comprehensive error handling system with custom error types
- [x] Set up async/await patterns with proper error propagation
- [x] Create supporting data models (ProcessedAudio, Transcript, ExtractedSong, SearchResult, CreatedPlaylist)
- [x] Create mock implementations for testing
- [x] Test protocol conformance verification
- [x] Test dependency injection functionality
- [x] Test error handling and propagation
- [x] Test async/await pattern implementation
- [x] Test mock service behavior verification
- [x] Update ContentView to use ServiceContainer
- [x] Ensure all services are protocol-based for testability
- [x] Verify dependency injection system is type-safe and easy to use

## Content Input Week (Week 2)

### 2.1: File Upload with Drag & Drop
- [x] Write tests first for file validation and handling logic (22 tests implemented)
- [x] Create FileUploadService conforming to existing AudioProcessor protocol
- [x] Implement SwiftUI file picker with native file selection
- [x] Add drag-and-drop support for audio/video files
- [x] Implement file format validation (mp3, mp4, wav, m4a, mov, etc.)
- [x] Create temporary file storage with cleanup
- [x] Add basic progress feedback UI
- [x] Integrate with existing ServiceContainer and error handling
- [x] Create clean drag-and-drop target area
- [x] Add file validation feedback
- [x] Add progress indication during file operations
- [x] Add error display for invalid files
- [x] Integrate with existing ContentView
- [x] Test file format validation
- [x] Test temporary file management
- [x] Test progress tracking
- [x] Test error scenarios (invalid files, disk space, permissions)
- [x] Test service integration
- [x] Update ContentView with file upload capabilities
- [x] Implement automatic cleanup of temporary files

### 2.2: URL Input and Validation
- [x] Write comprehensive tests for URL validation and download logic (27 tests implemented)
- [x] Extend FileUploadService to handle URL downloads
- [x] Create URLValidator utility for YouTube/podcast URL formats
- [x] Implement URL download with progress tracking
- [x] Add URL input UI component to existing interface
- [x] Handle network errors, timeouts, and invalid URLs
- [x] Support YouTube video URLs (youtube.com, youtu.be)
- [x] Support podcast RSS feed URLs (detection ready, full implementation pending)
- [x] Support direct audio file URLs
- [x] Support common URL variations and redirects
- [x] Test URL format validation
- [x] Test download functionality with mocked network calls
- [x] Test progress tracking during downloads
- [x] Test network error handling
- [x] Test invalid URL scenarios
- [x] Test integration with existing file processing
- [x] Add URL input field with validation feedback
- [x] Add switch between file upload and URL input
- [x] Add combined progress display for both input methods
- [x] Add error messaging for network issues
- [x] Ensure robust error handling for network issues

### 2.3: Audio Extraction from Video Files
- [ ] Write tests first for audio extraction logic using test audio/video files (25+ tests)
- [ ] Create AudioExtractionService using AVFoundation
- [ ] Extract audio from video files (mp4, mov, avi, etc.)
- [ ] Convert audio to standard format (WAV or MP3)
- [ ] Handle various video codecs and audio formats
- [ ] Add progress tracking for extraction process
- [ ] Implement proper cleanup of intermediate files
- [ ] Integrate with existing FileUploadService
- [ ] Use AVAssetExportSession for extraction
- [ ] Support common video formats
- [ ] Normalize audio output format
- [ ] Handle extraction errors gracefully
- [ ] Maintain file metadata when possible
- [ ] Test audio extraction from various video formats
- [ ] Test progress tracking during extraction
- [ ] Test error handling for unsupported formats
- [ ] Test file cleanup verification
- [ ] Test integration with existing services
- [ ] Test performance with large files
- [ ] Update progress display to show extraction phase
- [ ] Handle longer processing times for video files
- [ ] Display appropriate status messages
- [ ] Add error feedback for extraction failures

## Transcription Week (Week 3)

### 3.1: Whisper Integration for Speech-to-Text
- [ ] Create comprehensive tests for transcription functionality using test audio files (30+ tests)
- [ ] Implement TranscriptionService conforming to existing Transcriber protocol
- [ ] Choose and integrate Whisper (local model or API based on performance needs)
- [ ] Add audio preprocessing (chunking, normalization) for optimal transcription
- [ ] Implement progress tracking with callbacks
- [ ] Handle various audio formats and quality levels
- [ ] Add proper error handling for transcription failures
- [ ] Preserve timestamp information for chronological ordering
- [ ] Implement audio preprocessing using AVAudioEngine or similar
- [ ] Create chunking strategy for long audio files
- [ ] Add progress reporting throughout transcription
- [ ] Preserve timestamp information for text segments
- [ ] Test transcription accuracy with test audio files
- [ ] Test progress callback functionality
- [ ] Test error handling for various failure scenarios
- [ ] Test audio preprocessing validation
- [ ] Test integration with existing service architecture
- [ ] Test performance with different audio lengths
- [ ] Connect to existing AudioProcessor output
- [ ] Update ServiceContainer with TranscriptionService
- [ ] Enhance progress UI for transcription phase
- [ ] Add transcription results to PlaylistRequest model

### 3.2: Transcript Processing and Formatting
- [ ] Write tests first for all text processing and formatting logic (25+ tests)
- [ ] Create TranscriptProcessor utility for text cleaning and formatting
- [ ] Implement timestamp preservation for chronological music mention ordering
- [ ] Add text normalization and cleanup (remove filler words, fix punctuation)
- [ ] Handle transcription confidence levels and quality indicators
- [ ] Create debug display for transcript review (development aid)
- [ ] Integrate with existing TranscriptionService
- [ ] Prepare transcript format for music extraction
- [ ] Remove excessive filler words ("um", "uh", "like")
- [ ] Fix punctuation and capitalization
- [ ] Handle multiple speakers if detected
- [ ] Preserve timing information for music mentions
- [ ] Add quality scoring for transcript segments
- [ ] Test text cleaning and normalization
- [ ] Test timestamp preservation and formatting
- [ ] Test quality assessment algorithms
- [ ] Test integration with transcription results
- [ ] Test edge cases (poor audio quality, multiple speakers)
- [ ] Test performance with very long transcripts
- [ ] Add transcript display for debugging (toggleable)
- [ ] Show processing status during cleanup
- [ ] Display transcript quality indicators
- [ ] Update progress tracking for processing phase
- [ ] Extend PlaylistRequest model to store processed transcript
- [ ] Update TranscriptionService to use processor
- [ ] Connect to existing error handling system

## Music Intelligence Week (Week 4)

### 4.1: OpenAI API Integration for Music Extraction
- [ ] Write comprehensive tests for API integration using mocked responses (25+ tests)
- [ ] Create MusicExtractionService conforming to existing MusicExtractor protocol
- [ ] Implement secure OpenAI API client with authentication
- [ ] Add rate limiting and retry logic with exponential backoff
- [ ] Create robust response parsing framework
- [ ] Handle API errors, timeouts, and quota limits
- [ ] Implement proper request/response validation
- [ ] Add configuration for API settings (model, temperature, etc.)
- [ ] Implement secure API key management (environment variables or keychain)
- [ ] Add request rate limiting to respect API limits
- [ ] Add automatic retry with exponential backoff
- [ ] Add response validation and error handling
- [ ] Add configurable API parameters
- [ ] Add request/response logging for debugging
- [ ] Test API client functionality with mocked responses
- [ ] Test rate limiting behavior verification
- [ ] Test error handling for various API failure scenarios
- [ ] Test request formatting validation
- [ ] Test response parsing accuracy
- [ ] Test integration with existing service architecture
- [ ] Ensure API keys are never hardcoded
- [ ] Use secure storage for credentials
- [ ] Validate all API responses
- [ ] Handle sensitive data appropriately
- [ ] Implement proper error messages without exposing internals
- [ ] Integrate with existing ServiceContainer

### 4.2: Music Mention Detection and Formatting
- [ ] Write tests first for music extraction prompts and response parsing (30+ tests)
- [ ] Design and test prompts for accurate music mention detection
- [ ] Implement structured JSON response parsing for song/artist extraction
- [ ] Create artist and song name normalization and cleaning logic
- [ ] Add confidence scoring for extracted music mentions
- [ ] Handle various mention formats (casual references, recommendations, etc.)
- [ ] Format output as clean "Artist - Song Title" structures
- [ ] Integrate with existing MusicExtractionService
- [ ] Identify explicit song titles and artist names
- [ ] Detect album and artist recommendations
- [ ] Handle various mention contexts and formats
- [ ] Extract timestamps for chronological ordering
- [ ] Score confidence levels for each extraction
- [ ] Clean and normalize artist/song names
- [ ] Craft prompts that accurately identify music mentions
- [ ] Handle edge cases (similar song titles, common names)
- [ ] Extract context around mentions for confidence scoring
- [ ] Preserve chronological order from transcript
- [ ] Format responses as structured JSON
- [ ] Test music extraction accuracy with various transcript samples
- [ ] Test prompt response parsing reliability
- [ ] Test confidence scoring algorithm validation
- [ ] Test artist/song normalization logic
- [ ] Test edge case handling (ambiguous mentions, typos)
- [ ] Test integration with transcript processing
- [ ] Extend PlaylistRequest model for extracted music
- [ ] Create Song objects with confidence scores
- [ ] Preserve timestamp information for ordering
- [ ] Handle duplicate mentions and filtering

## Apple Music Search Week (Week 5)

### 5.1: MusicKit Search Implementation
- [ ] Write comprehensive tests for MusicKit search functionality using mocked responses (25+ tests)
- [ ] Create AppleMusicSearchService conforming to existing MusicSearcher protocol
- [ ] Implement MusicKit authorization and user permissions handling
- [ ] Add search query optimization for best results
- [ ] Implement result filtering and ranking by relevance
- [ ] Handle API rate limits and search quotas
- [ ] Create proper error handling for search failures
- [ ] Add batch search optimization for multiple songs
- [ ] Handle user authorization flow
- [ ] Implement search with various query strategies
- [ ] Filter results by song type, availability, etc.
- [ ] Rank results by relevance and popularity
- [ ] Handle regional availability differences
- [ ] Manage API quotas and rate limits
- [ ] Try multiple query formats for better matches
- [ ] Handle special characters and formatting
- [ ] Search by artist first, then song title
- [ ] Implement fallback strategies for difficult matches
- [ ] Add query result caching for performance
- [ ] Test search functionality with mocked MusicKit responses
- [ ] Test authorization flow testing
- [ ] Test query optimization validation
- [ ] Test result filtering and ranking
- [ ] Test error handling for various failure scenarios
- [ ] Test batch search performance testing
- [ ] Connect to music extraction results
- [ ] Update PlaylistRequest with search results
- [ ] Enhance error handling system
- [ ] Add search progress tracking

### 5.2: Match Confidence and Auto-Selection Logic
- [ ] Write comprehensive tests for confidence scoring and auto-selection logic (30+ tests)
- [ ] Implement match confidence scoring algorithm
- [ ] Create auto-selection criteria for obvious matches
- [ ] Add fuzzy matching for close but not exact results
- [ ] Implement batch search optimization for multiple songs
- [ ] Handle edge cases (multiple versions, live recordings, remixes)
- [ ] Create match result data structures
- [ ] Integrate with existing AppleMusicSearchService
- [ ] Implement exact title and artist matches (high confidence)
- [ ] Add fuzzy string matching for variations
- [ ] Add popularity and recency factors
- [ ] Handle album context when available
- [ ] Add user's music library preferences
- [ ] Add regional availability scoring
- [ ] Define thresholds for automatic selection
- [ ] Handle single perfect matches
- [ ] Skip ambiguous low-confidence matches
- [ ] Account for artist name variations
- [ ] Handle featured artists and collaborations
- [ ] Optimize multiple search requests
- [ ] Handle rate limiting across batch operations
- [ ] Provide progress feedback for large batches
- [ ] Add error resilience for partial batch failures
- [ ] Test confidence scoring algorithm accuracy
- [ ] Test auto-selection threshold validation
- [ ] Test fuzzy matching effectiveness
- [ ] Test batch processing reliability
- [ ] Test edge case handling (remixes, live versions, etc.)
- [ ] Test integration with search results
- [ ] Extend Song model with match confidence
- [ ] Create MatchResult objects for search outcomes
- [ ] Update PlaylistRequest with match results
- [ ] Add debugging information for manual review

## Match Selection UI Week (Week 6)

### 6.1: Card-Based Selection Interface
- [ ] Write tests for all UI state management and card interaction logic (20+ tests)
- [ ] Create SwiftUI card component for displaying match options
- [ ] Implement card stack layout with smooth animations
- [ ] Add swipe gesture recognition for selection/rejection
- [ ] Create visual feedback for user interactions
- [ ] Display match information (song title, artist, album art, confidence)
- [ ] Handle card stack state management
- [ ] Integrate with existing match results
- [ ] Design clean, readable card with match information
- [ ] Implement smooth swipe animations (left = reject, right = accept)
- [ ] Add tap-to-select alternative interaction
- [ ] Add visual confidence indicators
- [ ] Display album artwork when available
- [ ] Add progress indicator through ambiguous matches
- [ ] Implement intuitive swipe gestures
- [ ] Add clear visual feedback for selections
- [ ] Add undo functionality for recent selections
- [ ] Add batch operations (skip all low confidence)
- [ ] Add keyboard shortcuts for power users
- [ ] Test card component rendering
- [ ] Test swipe gesture recognition validation
- [ ] Test state management
- [ ] Test animation performance verification
- [ ] Test user interaction flow
- [ ] Test integration with match data
- [ ] Track user selections and rejections
- [ ] Maintain card stack ordering
- [ ] Handle navigation between cards
- [ ] Save selection state for persistence
- [ ] Update PlaylistRequest with user choices
- [ ] Update ContentView with card interface

### 6.2: Match Preview and Selection Management
- [ ] Write tests for preview functionality and selection state management (25+ tests)
- [ ] Add 30-second song preview playback using MusicKit
- [ ] Implement play/pause controls on cards
- [ ] Create selection progress tracking and navigation
- [ ] Add skip/select action buttons as tap alternatives
- [ ] Handle multiple match versions (original, live, remix, etc.)
- [ ] Implement selection persistence and undo functionality
- [ ] Complete integration with playlist creation workflow
- [ ] Implement 30-second preview playback using MusicKit
- [ ] Add play/pause button on each card
- [ ] Add audio progress indicator
- [ ] Implement automatic stop when swiping to next card
- [ ] Handle preview loading errors gracefully
- [ ] Add volume control integration
- [ ] Track all user selections and rejections
- [ ] Provide clear progress through ambiguous matches
- [ ] Allow users to go back and change selections
- [ ] Display selection summary before playlist creation
- [ ] Handle bulk operations (accept all, reject all)
- [ ] Add tap-based alternatives to swipe gestures
- [ ] Add keyboard shortcuts for efficient navigation
- [ ] Add context menu for additional options
- [ ] Add batch selection tools
- [ ] Add quick preview without full playback
- [ ] Test preview playback functionality
- [ ] Test selection state persistence
- [ ] Test navigation between matches
- [ ] Test undo/redo functionality
- [ ] Test integration with MusicKit preview API
- [ ] Test user interaction flows
- [ ] Add progress indicator for match review process
- [ ] Add selection summary view
- [ ] Add audio playback controls
- [ ] Enhance card information display
- [ ] Add responsive design for different window sizes

## Playlist Creation Week (Week 7)

### 7.1: Apple Music Playlist Generation
- [ ] Write comprehensive tests for playlist creation logic using mocked MusicKit responses (25+ tests)
- [ ] Create PlaylistCreationService conforming to existing PlaylistCreator protocol
- [ ] Implement MusicKit playlist creation with proper user authorization
- [ ] Add song addition with comprehensive error handling
- [ ] Generate playlist metadata (name, description) based on source content
- [ ] Handle playlist creation failures and partial successes
- [ ] Implement progress tracking for playlist operations
- [ ] Add user permission handling and error recovery
- [ ] Create playlist with meaningful name and description
- [ ] Add songs in chronological order from original content
- [ ] Handle songs unavailable in user's region
- [ ] Manage duplicate song detection and handling
- [ ] Set playlist privacy settings appropriately
- [ ] Add playlist artwork if possible
- [ ] Handle user authorization failures
- [ ] Manage individual song addition errors
- [ ] Provide clear feedback for failures
- [ ] Implement retry logic for transient failures
- [ ] Add graceful degradation for partial successes
- [ ] Add detailed error reporting for debugging
- [ ] Test playlist creation with mocked MusicKit calls
- [ ] Test song addition success and failure scenarios
- [ ] Test permission handling and authorization flows
- [ ] Test error recovery and retry mechanisms
- [ ] Test progress tracking validation
- [ ] Test integration with existing services
- [ ] Request necessary MusicKit permissions
- [ ] Handle user consent flows
- [ ] Manage authorization token expiration
- [ ] Provide clear permission error messaging
- [ ] Guide users through authorization process

### 7.2: Workflow Completion and User Feedback
- [ ] Write tests for workflow completion and user feedback systems (30+ tests)
- [ ] Implement chronological song ordering based on original mention timestamps
- [ ] Create success/failure feedback UI with detailed results
- [ ] Add final playlist preview before creation confirmation
- [ ] Implement "Open in Apple Music" functionality
- [ ] Create workflow completion tracking and analytics
- [ ] Add playlist sharing capabilities
- [ ] Handle edge cases and provide graceful error recovery
- [ ] Preserve chronological order from original content
- [ ] Generate playlist summary with statistics
- [ ] Show successful vs. failed song additions
- [ ] Provide final confirmation before playlist creation
- [ ] Display creation progress with detailed status
- [ ] Offer post-creation actions (open, share, create another)
- [ ] Add success confirmation with playlist details
- [ ] Add clear error explanations with suggested actions
- [ ] Show progress summary (X of Y songs successfully added)
- [ ] Add link to created playlist in Apple Music
- [ ] Add option to retry failed song additions
- [ ] Add export playlist information for manual review
- [ ] Implement direct link to playlist in Apple Music
- [ ] Add share playlist with standard iOS sharing
- [ ] Add copy playlist link to clipboard
- [ ] Add export playlist as text or file
- [ ] Save workflow results for future reference
- [ ] Test chronological ordering algorithm
- [ ] Test success/failure feedback systems
- [ ] Test Apple Music integration and linking
- [ ] Test sharing functionality
- [ ] Test edge case handling (empty playlists, all failures)
- [ ] Test complete workflow integration
- [ ] Connect all services in complete workflow
- [ ] Update ContentView with final result display
- [ ] Implement proper cleanup of temporary resources
- [ ] Add workflow restart capability
- [ ] Ensure proper error state recovery

## Integration & Polish Week (Week 8)

### 8.1: End-to-End Integration and Testing
- [ ] Create comprehensive integration tests covering the complete workflow (50+ tests)
- [ ] Implement end-to-end testing with real (but controlled) data
- [ ] Add performance testing for large files and long transcripts
- [ ] Create memory leak detection and resource management testing
- [ ] Implement error scenario testing for all failure points
- [ ] Add logging and analytics for workflow monitoring
- [ ] Create automated testing pipeline
- [ ] Ensure all components work together seamlessly
- [ ] Test complete workflow from file upload to playlist creation
- [ ] Test with various file types and sizes
- [ ] Validate error handling at each stage
- [ ] Verify progress tracking accuracy
- [ ] Test user interaction flows
- [ ] Validate data persistence and cleanup
- [ ] Test large file processing (1+ hour audio)
- [ ] Monitor memory usage
- [ ] Optimize CPU utilization
- [ ] Test network request efficiency
- [ ] Ensure UI responsiveness during processing
- [ ] Handle concurrent operations
- [ ] Test network failures at each API call
- [ ] Test file corruption and invalid formats
- [ ] Test API quota exhaustion
- [ ] Test user permission denials
- [ ] Test partial failures and recovery
- [ ] Test resource exhaustion scenarios
- [ ] Connect all services through ServiceContainer
- [ ] Implement proper resource cleanup
- [ ] Add comprehensive logging throughout
- [ ] Create debugging utilities and tools
- [ ] Ensure thread safety for async operations
- [ ] Document debugging and maintenance procedures

### 8.2: UI/UX Polish and Production Readiness
- [ ] Write tests for all accessibility features and UI improvements
- [ ] Implement comprehensive accessibility support (VoiceOver, keyboard navigation)
- [ ] Create polished progress indicators and status messaging
- [ ] Add proper error message design and user guidance
- [ ] Implement app icon and visual branding
- [ ] Create user onboarding and help documentation
- [ ] Add preferences and settings management
- [ ] Ensure compliance with Apple's Human Interface Guidelines
- [ ] Refine progress bars with estimated time remaining
- [ ] Add professional error messaging with helpful suggestions
- [ ] Implement smooth transitions and micro-interactions
- [ ] Ensure consistent visual design throughout
- [ ] Add responsive layout for different window sizes
- [ ] Add keyboard shortcuts and menu bar integration
- [ ] Implement full VoiceOver support for all UI elements
- [ ] Add keyboard navigation throughout the application
- [ ] Add high contrast mode support
- [ ] Add dynamic text size support
- [ ] Add accessibility labels and hints
- [ ] Add screen reader friendly progress updates
- [ ] Design and implement app icon
- [ ] Add menu bar integration with standard macOS menus
- [ ] Create preferences window with user settings
- [ ] Add keyboard shortcuts and hotkeys
- [ ] Implement window state persistence
- [ ] Add user defaults and settings management
- [ ] Test UI across different macOS versions
- [ ] Test accessibility with assistive technologies
- [ ] Optimize performance and memory management
- [ ] Complete code review and documentation cleanup
- [ ] Conduct user acceptance testing scenarios
- [ ] Prepare for App Store submission (if applicable)
- [ ] Create production-ready application build

## Final Verification Checklist

- [ ] All unit tests passing (200+ tests total)
- [ ] All integration tests passing
- [ ] Performance benchmarks meet requirements
- [ ] Memory leaks resolved
- [ ] Accessibility fully implemented
- [ ] Error handling comprehensive
- [ ] User experience polished
- [ ] Documentation complete
- [ ] Production build created
- [ ] App ready for distribution