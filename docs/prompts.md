# Test-Driven Implementation Prompts for Swift Playlist Creator

## Foundation Week (Week 1)

### Prompt 1.1: Project Setup and Basic Architecture

```
Create a new macOS SwiftUI application called "PlaylistCreator" following test-driven development principles. Set up the basic project structure with proper architecture from the start.

Requirements:
1. Create an Xcode project targeting macOS with SwiftUI
2. Configure Info.plist with necessary permissions for file access and network requests
3. Add MusicKit capability to the project
4. Create a basic ContentView with a simple "Playlist Creator" title
5. Set up a proper folder structure: Models/, Services/, Views/, Tests/
6. Create a basic test target and ensure it compiles
7. Write a simple smoke test that verifies the app launches

Deliverables:
- Working Xcode project that builds and runs
- Basic ContentView displaying app title
- Test target with one passing test
- Project configured with MusicKit capability
- Clean architecture ready for expansion

Focus on clean code practices, proper Swift conventions, and ensuring the foundation is solid for future features. Include basic SwiftUI app lifecycle setup and make sure the project follows Apple's recommended project structure.
```

### Prompt 1.2: Core Data Models with Tests

```
Building on the previous project setup, implement the core data models using test-driven development. These models will be the foundation for all playlist creation functionality.

Requirements:
1. Create comprehensive unit tests FIRST for all data models
2. Implement Song struct with: title, artist, appleID (optional), confidence score
3. Implement ProcessingStatus enum: idle, processing, complete, error
4. Implement MatchStatus enum: auto, pending, selected, skipped
5. Create PlaylistRequest model to track workflow state
6. Add Codable conformance where appropriate
7. Include proper validation and edge case handling
8. Write tests for model serialization/deserialization

Test Coverage Should Include:
- Model creation and initialization
- Property validation and edge cases
- Codable encoding/decoding
- Equality comparisons where relevant
- Invalid data handling

Deliverables:
- Complete test suite for all data models (20+ tests minimum)
- All models implemented with proper Swift conventions
- Models integrated into main app target
- Tests passing with good coverage
- Documentation for each model's purpose

Start with failing tests, then implement the minimal code to make them pass. Ensure models are immutable where possible and follow Swift best practices.
```

### Prompt 1.3: Service Layer Architecture and Dependency Injection

```
Implement a protocol-based service architecture with dependency injection and comprehensive error handling, building on the existing project and data models.

Requirements:
1. Write tests first for all service protocols and implementations
2. Create protocol definitions for core services:
   - AudioProcessor: handles file/URL audio extraction
   - Transcriber: converts audio to text
   - MusicExtractor: finds music mentions in text
   - MusicSearcher: searches Apple Music catalog
   - PlaylistCreator: creates Apple Music playlists
3. Implement a ServiceContainer for dependency injection
4. Create a comprehensive error handling system with custom error types
5. Set up async/await patterns with proper error propagation
6. Create a simple Logger utility for debugging
7. Create mock implementations for testing

Test Requirements:
- Protocol conformance verification
- Dependency injection functionality
- Error handling and propagation
- Async/await pattern implementation
- Mock service behavior verification

Deliverables:
- Complete service protocol definitions
- ServiceContainer with registration/resolution
- Custom error types for each service domain
- Logger utility with different log levels
- Mock implementations for all services
- Comprehensive test suite (30+ tests)
- Updated ContentView to use ServiceContainer

Ensure all services are protocol-based for testability, implement proper error handling throughout, and make the dependency injection system type-safe and easy to use.
```

## Content Input Week (Week 2)

### Prompt 2.1: File Upload with Drag & Drop

```
Implement file upload functionality with drag-and-drop support, building on the existing service architecture. Use test-driven development for all business logic.

Requirements:
1. Write tests first for file validation and handling logic
2. Create FileUploadService conforming to existing AudioProcessor protocol
3. Implement SwiftUI file picker with native file selection
4. Add drag-and-drop support for audio/video files
5. Implement file format validation (mp3, mp4, wav, m4a, mov, etc.)
6. Create temporary file storage with cleanup
7. Add basic progress feedback UI
8. Integrate with existing ServiceContainer and error handling

UI Requirements:
- Clean drag-and-drop target area
- File validation feedback
- Progress indication during file operations
- Error display for invalid files
- Integration with existing ContentView

Test Coverage:
- File format validation
- Temporary file management
- Progress tracking
- Error scenarios (invalid files, disk space, permissions)
- Service integration

Deliverables:
- FileUploadService implementation with full test coverage
- SwiftUI components for file selection and drag-drop
- Updated ContentView with file upload capabilities
- Temporary file management with automatic cleanup
- All tests passing (15+ new tests)

Focus on user experience, proper error handling, and ensuring the file upload integrates seamlessly with the existing architecture.
```

### Prompt 2.2: URL Input and Validation

```
Add URL input functionality for YouTube and podcast URLs, extending the existing file upload system. Follow test-driven development principles.

Requirements:
1. Write comprehensive tests for URL validation and download logic
2. Extend FileUploadService to handle URL downloads
3. Create URLValidator utility for YouTube/podcast URL formats
4. Implement URL download with progress tracking
5. Add URL input UI component to existing interface
6. Handle network errors, timeouts, and invalid URLs
7. Support common podcast and YouTube URL formats
8. Integrate download progress with existing progress system

URL Support Requirements:
- YouTube video URLs (youtube.com, youtu.be)
- Podcast RSS feed URLs
- Direct audio file URLs
- Common URL variations and redirects

Test Coverage:
- URL format validation
- Download functionality with mocked network calls
- Progress tracking during downloads
- Network error handling
- Invalid URL scenarios
- Integration with existing file processing

UI Updates:
- URL input field with validation feedback
- Switch between file upload and URL input
- Combined progress display for both input methods
- Error messaging for network issues

Deliverables:
- Extended FileUploadService supporting URLs
- URLValidator with comprehensive format support
- Updated UI with URL input capabilities
- Network layer with proper error handling
- Complete test suite (20+ tests)
- Integration with existing progress tracking

Ensure robust error handling for network issues and maintain consistency with the existing file upload user experience.
```

### Prompt 2.3: Audio Extraction from Video Files

```
Implement audio extraction from video files using AVFoundation, completing the content input pipeline. Use test-driven development for all audio processing logic.

Requirements:
1. Write tests first for audio extraction logic (using test audio/video files)
2. Create AudioExtractionService using AVFoundation
3. Extract audio from video files (mp4, mov, avi, etc.)
4. Convert audio to standard format (WAV or MP3)
5. Handle various video codecs and audio formats
6. Add progress tracking for extraction process
7. Implement proper cleanup of intermediate files
8. Integrate with existing FileUploadService

Technical Requirements:
- Use AVAssetExportSession for extraction
- Support common video formats
- Normalize audio output format
- Handle extraction errors gracefully
- Maintain file metadata when possible

Test Coverage:
- Audio extraction from various video formats
- Progress tracking during extraction
- Error handling for unsupported formats
- File cleanup verification
- Integration with existing services
- Performance testing with large files

UI Integration:
- Update progress display to show extraction phase
- Handle longer processing times for video files
- Display appropriate status messages
- Error feedback for extraction failures

Deliverables:
- AudioExtractionService with full AVFoundation integration
- Support for major video formats
- Updated FileUploadService integration
- Comprehensive test suite with test media files (25+ tests)
- Enhanced progress tracking UI
- Proper temporary file management

Focus on performance, error handling, and ensuring the extraction process provides good user feedback throughout the potentially lengthy operation.
```

## Transcription Week (Week 3)

### Prompt 3.1: Whisper Integration for Speech-to-Text

```
Implement OpenAI Whisper integration for speech-to-text transcription, building on the existing audio processing pipeline. Follow test-driven development principles.

Requirements:
1. Create comprehensive tests for transcription functionality (use test audio files)
2. Implement TranscriptionService conforming to existing Transcriber protocol
3. Integrate Whisper (choose local model or API based on performance needs)
4. Add audio preprocessing (chunking, normalization) for optimal transcription
5. Implement progress tracking with callbacks
6. Handle various audio formats and quality levels
7. Add proper error handling for transcription failures
8. Preserve timestamp information for chronological ordering

Technical Implementation:
- Audio preprocessing using AVAudioEngine or similar
- Whisper model integration (local or cloud)
- Chunking strategy for long audio files
- Progress reporting throughout transcription
- Timestamp preservation for text segments

Test Requirements:
- Transcription accuracy with test audio files
- Progress callback functionality
- Error handling for various failure scenarios
- Audio preprocessing validation
- Integration with existing service architecture
- Performance testing with different audio lengths

Integration Points:
- Connect to existing AudioProcessor output
- Update ServiceContainer with TranscriptionService
- Enhance progress UI for transcription phase
- Add transcription results to PlaylistRequest model

Deliverables:
- Complete TranscriptionService implementation
- Audio preprocessing pipeline
- Whisper integration with error handling
- Updated progress tracking system
- Comprehensive test suite with audio test files (30+ tests)
- Integration with existing service architecture

Focus on transcription accuracy, performance optimization for long files, and maintaining the smooth user experience with proper progress feedback.
```

### Prompt 3.2: Transcript Processing and Formatting

```
Implement transcript processing, cleaning, and formatting capabilities, building on the Whisper integration. Use test-driven development for text processing logic.

Requirements:
1. Write tests first for all text processing and formatting logic
2. Create TranscriptProcessor utility for text cleaning and formatting
3. Implement timestamp preservation for chronological music mention ordering
4. Add text normalization and cleanup (remove filler words, fix punctuation)
5. Handle transcription confidence levels and quality indicators
6. Create debug display for transcript review (development aid)
7. Integrate with existing TranscriptionService
8. Prepare transcript format for music extraction

Text Processing Features:
- Remove excessive filler words ("um", "uh", "like")
- Fix punctuation and capitalization
- Handle multiple speakers if detected
- Preserve timing information for music mentions
- Quality scoring for transcript segments

Test Coverage:
- Text cleaning and normalization
- Timestamp preservation and formatting
- Quality assessment algorithms
- Integration with transcription results
- Edge cases (poor audio quality, multiple speakers)
- Performance with very long transcripts

UI Enhancements:
- Add transcript display for debugging (toggleable)
- Show processing status during cleanup
- Display transcript quality indicators
- Update progress tracking for processing phase

Integration Requirements:
- Extend PlaylistRequest model to store processed transcript
- Update TranscriptionService to use processor
- Connect to existing error handling system
- Prepare data structure for music extraction phase

Deliverables:
- TranscriptProcessor with comprehensive text processing
- Updated TranscriptionService integration
- Debug UI for transcript review
- Enhanced data models for processed transcripts
- Complete test suite (25+ tests)
- Integration with existing progress system

Ensure the processed transcript maintains all necessary information for accurate music mention extraction while being clean and well-formatted.
```

## Music Intelligence Week (Week 4)

### Prompt 4.1: OpenAI API Integration for Music Extraction

```
Implement OpenAI API integration for extracting music mentions from transcripts, building on the existing transcript processing. Follow test-driven development principles.

Requirements:
1. Write comprehensive tests for API integration (using mocked responses)
2. Create MusicExtractionService conforming to existing MusicExtractor protocol
3. Implement secure OpenAI API client with authentication
4. Add rate limiting and retry logic with exponential backoff
5. Create robust response parsing framework
6. Handle API errors, timeouts, and quota limits
7. Implement proper request/response validation
8. Add configuration for API settings (model, temperature, etc.)

API Integration Features:
- Secure API key management (environment variables or keychain)
- Request rate limiting to respect API limits
- Automatic retry with exponential backoff
- Response validation and error handling
- Configurable API parameters
- Request/response logging for debugging

Test Requirements:
- API client functionality with mocked responses
- Rate limiting behavior verification
- Error handling for various API failure scenarios
- Request formatting validation
- Response parsing accuracy
- Integration with existing service architecture

Security Considerations:
- Never hardcode API keys
- Use secure storage for credentials
- Validate all API responses
- Handle sensitive data appropriately
- Implement proper error messages without exposing internals

Deliverables:
- Complete OpenAI API client implementation
- MusicExtractionService with full error handling
- Rate limiting and retry mechanisms
- Secure credential management
- Comprehensive test suite with mocked API calls (25+ tests)
- Integration with existing ServiceContainer

Focus on security, reliability, and proper error handling. Ensure the API integration is robust enough to handle various failure scenarios gracefully.
```

### Prompt 4.2: Music Mention Detection and Formatting

```
Implement intelligent music mention detection and formatting using OpenAI, completing the music extraction pipeline. Use test-driven development for all extraction logic.

Requirements:
1. Write tests first for music extraction prompts and response parsing
2. Design and test prompts for accurate music mention detection
3. Implement structured JSON response parsing for song/artist extraction
4. Create artist and song name normalization and cleaning logic
5. Add confidence scoring for extracted music mentions
6. Handle various mention formats (casual references, recommendations, etc.)
7. Format output as clean "Artist - Song Title" structures
8. Integrate with existing MusicExtractionService

Music Detection Features:
- Identify explicit song titles and artist names
- Detect album and artist recommendations
- Handle various mention contexts and formats
- Extract timestamps for chronological ordering
- Score confidence levels for each extraction
- Clean and normalize artist/song names

Prompt Engineering:
- Craft prompts that accurately identify music mentions
- Handle edge cases (similar song titles, common names)
- Extract context around mentions for confidence scoring
- Preserve chronological order from transcript
- Format responses as structured JSON

Test Coverage:
- Music extraction accuracy with various transcript samples
- Prompt response parsing reliability
- Confidence scoring algorithm validation
- Artist/song normalization logic
- Edge case handling (ambiguous mentions, typos)
- Integration with transcript processing

Data Processing:
- Extend PlaylistRequest model for extracted music
- Create Song objects with confidence scores
- Preserve timestamp information for ordering
- Handle duplicate mentions and filtering

Deliverables:
- Optimized music extraction prompts
- Complete response parsing and validation
- Artist/song normalization utilities
- Confidence scoring algorithm
- Updated MusicExtractionService implementation
- Comprehensive test suite with various transcript samples (30+ tests)

Focus on accuracy, handling edge cases, and ensuring the extracted music data is clean and well-formatted for Apple Music searching.
```

## Apple Music Search Week (Week 5)

### Prompt 5.1: MusicKit Search Implementation

```
Implement Apple Music search functionality using MusicKit, building on the music extraction results. Follow test-driven development principles.

Requirements:
1. Write comprehensive tests for MusicKit search functionality (using mocked responses)
2. Create AppleMusicSearchService conforming to existing MusicSearcher protocol
3. Implement MusicKit authorization and user permissions handling
4. Add search query optimization for best results
5. Implement result filtering and ranking by relevance
6. Handle API rate limits and search quotas
7. Create proper error handling for search failures
8. Add batch search optimization for multiple songs

MusicKit Integration:
- Handle user authorization flow
- Implement search with various query strategies
- Filter results by song type, availability, etc.
- Rank results by relevance and popularity
- Handle regional availability differences
- Manage API quotas and rate limits

Search Optimization:
- Try multiple query formats for better matches
- Handle special characters and formatting
- Search by artist first, then song title
- Fallback strategies for difficult matches
- Query result caching for performance

Test Requirements:
- Search functionality with mocked MusicKit responses
- Authorization flow testing
- Query optimization validation
- Result filtering and ranking
- Error handling for various failure scenarios
- Batch search performance testing

Integration Points:
- Connect to music extraction results
- Update PlaylistRequest with search results
- Enhance error handling system
- Add search progress tracking

Deliverables:
- Complete AppleMusicSearchService implementation
- MusicKit authorization handling
- Search query optimization strategies
- Result filtering and ranking logic
- Comprehensive test suite (25+ tests)
- Integration with existing service architecture

Focus on search accuracy, user experience with authorization, and handling the various edge cases that can occur with music catalog searches.
```

### Prompt 5.2: Match Confidence and Auto-Selection Logic

```
Implement intelligent match confidence scoring and automatic selection logic, completing the Apple Music search pipeline. Use test-driven development for all matching algorithms.

Requirements:
1. Write comprehensive tests for confidence scoring and auto-selection logic
2. Implement match confidence scoring algorithm
3. Create auto-selection criteria for obvious matches
4. Add fuzzy matching for close but not exact results
5. Implement batch search optimization for multiple songs
6. Handle edge cases (multiple versions, live recordings, remixes)
7. Create match result data structures
8. Integrate with existing AppleMusicSearchService

Confidence Scoring Features:
- Exact title and artist matches (high confidence)
- Fuzzy string matching for variations
- Popularity and recency factors
- Album context when available
- User's music library preferences
- Regional availability scoring

Auto-Selection Logic:
- Define thresholds for automatic selection
- Handle single perfect matches
- Skip ambiguous low-confidence matches
- Account for artist name variations
- Handle featured artists and collaborations

Batch Processing:
- Optimize multiple search requests
- Handle rate limiting across batch operations
- Provide progress feedback for large batches
- Error resilience for partial batch failures

Test Coverage:
- Confidence scoring algorithm accuracy
- Auto-selection threshold validation
- Fuzzy matching effectiveness
- Batch processing reliability
- Edge case handling (remixes, live versions, etc.)
- Integration with search results

Data Structures:
- Extend Song model with match confidence
- Create MatchResult objects for search outcomes
- Update PlaylistRequest with match results
- Add debugging information for manual review

Deliverables:
- Complete confidence scoring algorithm
- Auto-selection logic implementation
- Fuzzy matching utilities
- Batch search optimization
- Updated data models with match information
- Comprehensive test suite (30+ tests)

Focus on accuracy, performance, and ensuring the auto-selection logic makes sensible decisions while flagging ambiguous cases for user review.
```

## Match Selection UI Week (Week 6)

### Prompt 6.1: Card-Based Selection Interface

```
Implement a card-based UI for reviewing and selecting ambiguous music matches, building on the match confidence system. Use test-driven development for UI logic and state management.

Requirements:
1. Write tests for all UI state management and card interaction logic
2. Create SwiftUI card component for displaying match options
3. Implement card stack layout with smooth animations
4. Add swipe gesture recognition for selection/rejection
5. Create visual feedback for user interactions
6. Display match information (song title, artist, album art, confidence)
7. Handle card stack state management
8. Integrate with existing match results

Card Interface Features:
- Clean, readable card design with match information
- Smooth swipe animations (left = reject, right = accept)
- Tap-to-select alternative interaction
- Visual confidence indicators
- Album artwork display when available
- Progress indicator through ambiguous matches

Interaction Design:
- Intuitive swipe gestures
- Clear visual feedback for selections
- Undo functionality for recent selections
- Batch operations (skip all low confidence)
- Keyboard shortcuts for power users

Test Requirements:
- Card component rendering tests
- Swipe gesture recognition validation
- State management testing
- Animation performance verification
- User interaction flow testing
- Integration with match data

State Management:
- Track user selections and rejections
- Maintain card stack ordering
- Handle navigation between cards
- Save selection state for persistence
- Update PlaylistRequest with user choices

Deliverables:
- Card component with full swipe functionality
- Card stack container with state management
- Smooth animations and visual feedback
- Integration with existing match results
- Comprehensive UI tests (20+ tests)
- Updated ContentView with card interface

Focus on user experience, smooth animations, and intuitive interactions while maintaining proper separation of UI and business logic.
```

### Prompt 6.2: Match Preview and Selection Management

```
Implement match preview functionality with 30-second clips and comprehensive selection management, completing the card-based interface. Follow test-driven development for all preview and state logic.

Requirements:
1. Write tests for preview functionality and selection state management
2. Add 30-second song preview playback using MusicKit
3. Implement play/pause controls on cards
4. Create selection progress tracking and navigation
5. Add skip/select action buttons as tap alternatives
6. Handle multiple match versions (original, live, remix, etc.)
7. Implement selection persistence and undo functionality
8. Complete integration with playlist creation workflow

Preview Features:
- 30-second preview playback using MusicKit
- Play/pause button on each card
- Audio progress indicator
- Automatic stop when swiping to next card
- Handle preview loading errors gracefully
- Volume control integration

Selection Management:
- Track all user selections and rejections
- Provide clear progress through ambiguous matches
- Allow users to go back and change selections
- Display selection summary before playlist creation
- Handle bulk operations (accept all, reject all)

Enhanced Interactions:
- Tap-based alternatives to swipe gestures
- Keyboard shortcuts for efficient navigation
- Context menu for additional options
- Batch selection tools
- Quick preview without full playback

Test Coverage:
- Preview playback functionality
- Selection state persistence
- Navigation between matches
- Undo/redo functionality
- Integration with MusicKit preview API
- User interaction flows

UI Enhancements:
- Progress indicator for match review process
- Selection summary view
- Audio playback controls
- Enhanced card information display
- Responsive design for different window sizes

Deliverables:
- Complete preview playback integration
- Enhanced card interface with preview controls
- Selection state management system
- Navigation and progress tracking
- Comprehensive test suite (25+ tests)
- Integration with playlist creation workflow

Focus on smooth audio preview experience, clear progress indication, and ensuring users can efficiently review and select from ambiguous matches.
```

## Playlist Creation Week (Week 7)

### Prompt 7.1: Apple Music Playlist Generation

```
Implement Apple Music playlist creation functionality, building on the completed match selection process. Use test-driven development for all playlist operations.

Requirements:
1. Write comprehensive tests for playlist creation logic (using mocked MusicKit responses)
2. Create PlaylistCreationService conforming to existing PlaylistCreator protocol
3. Implement MusicKit playlist creation with proper user authorization
4. Add song addition with comprehensive error handling
5. Generate playlist metadata (name, description) based on source content
6. Handle playlist creation failures and partial successes
7. Implement progress tracking for playlist operations
8. Add user permission handling and error recovery

Playlist Creation Features:
- Create playlist with meaningful name and description
- Add songs in chronological order from original content
- Handle songs unavailable in user's region
- Manage duplicate song detection and handling
- Set playlist privacy settings appropriately
- Add playlist artwork if possible

Error Handling:
- Handle user authorization failures
- Manage individual song addition errors
- Provide clear feedback for failures
- Implement retry logic for transient failures
- Graceful degradation for partial successes
- Detailed error reporting for debugging

Test Requirements:
- Playlist creation with mocked MusicKit calls
- Song addition success and failure scenarios
- Permission handling and authorization flows
- Error recovery and retry mechanisms
- Progress tracking validation
- Integration with existing services

Authorization Management:
- Request necessary MusicKit permissions
- Handle user consent flows
- Manage authorization token expiration
- Provide clear permission error messaging
- Guide users through authorization process

Deliverables:
- Complete PlaylistCreationService implementation
- MusicKit playlist creation integration
- Comprehensive error handling and recovery
- User authorization management
- Progress tracking for playlist operations
- Complete test suite (25+ tests)

Focus on reliability, user experience with permissions, and providing clear feedback throughout the playlist creation process.
```

### Prompt 7.2: Workflow Completion and User Feedback

```
Complete the playlist creation workflow with comprehensive user feedback, success confirmation, and integration with Apple Music. Use test-driven development for all workflow completion logic.

Requirements:
1. Write tests for workflow completion and user feedback systems
2. Implement chronological song ordering based on original mention timestamps
3. Create success/failure feedback UI with detailed results
4. Add final playlist preview before creation confirmation
5. Implement "Open in Apple Music" functionality
6. Create workflow completion tracking and analytics
7. Add playlist sharing capabilities
8. Handle edge cases and provide graceful error recovery

Workflow Completion Features:
- Preserve chronological order from original content
- Generate playlist summary with statistics
- Show successful vs. failed song additions
- Provide final confirmation before playlist creation
- Display creation progress with detailed status
- Offer post-creation actions (open, share, create another)

User Feedback Interface:
- Success confirmation with playlist details
- Clear error explanations with suggested actions
- Progress summary (X of Y songs successfully added)
- Link to created playlist in Apple Music
- Option to retry failed song additions
- Export playlist information for manual review

Integration Features:
- Direct link to playlist in Apple Music
- Share playlist with standard iOS sharing
- Copy playlist link to clipboard
- Export playlist as text or file
- Save workflow results for future reference

Test Coverage:
- Chronological ordering algorithm
- Success/failure feedback systems
- Apple Music integration and linking
- Sharing functionality
- Edge case handling (empty playlists, all failures)
- Complete workflow integration testing

Final Integration:
- Connect all services in complete workflow
- Update ContentView with final result display
- Implement proper cleanup of temporary resources
- Add workflow restart capability
- Ensure proper error state recovery

Deliverables:
- Complete chronological ordering implementation
- Success/failure feedback UI
- Apple Music integration and sharing
- Workflow completion and cleanup
- Final integration of all components
- Comprehensive test suite (30+ tests)

Focus on providing a satisfying completion experience, clear communication of results, and seamless integration with Apple Music for the best user experience.
```

## Integration & Polish Week (Week 8)

### Prompt 8.1: End-to-End Integration and Testing

```
Complete the end-to-end integration of all components and implement comprehensive testing suite. Focus on reliability, performance, and error handling across the entire workflow.

Requirements:
1. Create comprehensive integration tests covering the complete workflow
2. Implement end-to-end testing with real (but controlled) data
3. Add performance testing for large files and long transcripts
4. Create memory leak detection and resource management testing
5. Implement error scenario testing for all failure points
6. Add logging and analytics for workflow monitoring
7. Create automated testing pipeline
8. Ensure all components work together seamlessly

Integration Testing:
- Complete workflow from file upload to playlist creation
- Test with various file types and sizes
- Validate error handling at each stage
- Verify progress tracking accuracy
- Test user interaction flows
- Validate data persistence and cleanup

Performance Testing:
- Large file processing (1+ hour audio)
- Memory usage monitoring
- CPU utilization optimization
- Network request efficiency
- UI responsiveness during processing
- Concurrent operation handling

Error Scenario Testing:
- Network failures at each API call
- File corruption and invalid formats
- API quota exhaustion
- User permission denials
- Partial failures and recovery
- Resource exhaustion scenarios

System Integration:
- Connect all services through ServiceContainer
- Implement proper resource cleanup
- Add comprehensive logging throughout
- Create debugging utilities and tools
- Ensure thread safety for async operations

Deliverables:
- Complete integration test suite (50+ tests)
- Performance benchmarking and optimization
- Memory leak detection and fixes
- Error scenario coverage and recovery
- Comprehensive logging system
- Documentation for debugging and maintenance

Focus on reliability, performance under stress, and ensuring the application handles real-world usage scenarios gracefully.
```

### Prompt 8.2: UI/UX Polish and Production Readiness

```
Complete the application with final UI/UX polish, accessibility features, and production-ready improvements. Ensure the app meets Apple's quality standards and provides an excellent user experience.

Requirements:
1. Write tests for all accessibility features and UI improvements
2. Implement comprehensive accessibility support (VoiceOver, keyboard navigation)
3. Create polished progress indicators and status messaging
4. Add proper error message design and user guidance
5. Implement app icon and visual branding
6. Create user onboarding and help documentation
7. Add preferences and settings management
8. Ensure compliance with Apple's Human Interface Guidelines

UI/UX Improvements:
- Refined progress bars with estimated time remaining
- Professional error messaging with helpful suggestions
- Smooth transitions and micro-interactions
- Consistent visual design throughout
- Responsive layout for different window sizes
- Keyboard shortcuts and menu bar integration

Accessibility Features:
- Full VoiceOver support for all UI elements
- Keyboard navigation throughout the application
- High contrast mode support
- Dynamic text size support
- Accessibility labels and hints
- Screen reader friendly progress updates

Production Features:
- App icon design and implementation
- Menu bar integration with standard macOS menus
- Preferences window with user settings
- Keyboard shortcuts and hotkeys
- Window state persistence
- User defaults and settings management

Quality Assurance:
- Final UI testing across different macOS versions
- Accessibility testing with assistive technologies
- Performance optimization and memory management
- Code review and documentation cleanup
- User acceptance testing scenarios
- App Store preparation (if applicable)

Deliverables:
- Complete accessibility implementation
- Polished UI with professional design
- App icon and branding elements
- Settings and preferences system
- Final testing and quality assurance
- Production-ready application build

Focus on creating a polished, professional application that provides an excellent user experience and meets all accessibility and quality standards for macOS applications.
```