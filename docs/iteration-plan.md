# Swift Playlist Creator - Implementation Plan

## Detailed Project Blueprint

### Phase 1: Foundation & Setup
1. **Project Setup**
   - Create Xcode project with SwiftUI
   - Configure Apple Music API integration (MusicKit)
   - Set up development certificates and capabilities
   - Configure third-party dependencies (Whisper, OpenAI)

2. **Core Architecture**
   - Define data models (Song, Artist, Playlist, ProcessingStatus)
   - Create service layer abstractions
   - Implement basic error handling framework
   - Set up async/await patterns for workflow

### Phase 2: Content Processing Pipeline
3. **Audio Extraction Service**
   - URL download and validation
   - File upload handling
   - Audio extraction from video files (AVFoundation)
   - Temporary file management

4. **Transcription Service**
   - Whisper integration (local model)
   - Audio preprocessing and chunking
   - Transcript generation and validation
   - Error handling for failed transcriptions

### Phase 3: Music Intelligence
5. **Music Extraction Service**
   - OpenAI API integration
   - Prompt engineering for music mention detection
   - Response parsing and validation
   - Artist-Song formatting and cleaning

6. **Apple Music Integration**
   - MusicKit search implementation
   - Match confidence scoring
   - Search result ranking and filtering
   - Batch search optimization

### Phase 4: User Interface
7. **Basic UI Framework**
   - Main window layout
   - File/URL input interface
   - Progress tracking UI
   - Basic navigation structure

8. **Match Selection Interface**
   - Card-based selection UI
   - Swipe/tap gesture handling
   - Match preview and playback
   - Bulk selection actions

### Phase 5: Playlist Management
9. **Playlist Creation**
   - Apple Music playlist generation
   - Chronological ordering logic
   - Error handling for failed additions
   - User confirmation and feedback

10. **Testing & Polish**
    - Unit tests for all services
    - Integration testing
    - Error scenario testing
    - UI/UX refinements

## Iterative Chunks (Building on Each Other)

### Chunk 1: Foundation (Weeks 1-2)
- **1.1**: Xcode project setup + basic SwiftUI app
- **1.2**: Data models and core architecture
- **1.3**: Apple Music API integration basics
- **1.4**: Basic error handling and logging

### Chunk 2: Content Input (Week 3)
- **2.1**: File upload functionality
- **2.2**: URL input and validation
- **2.3**: Audio extraction from files
- **2.4**: Basic progress UI

### Chunk 3: Transcription Pipeline (Weeks 4-5)
- **3.1**: Whisper integration (local model)
- **3.2**: Audio preprocessing and chunking
- **3.3**: Transcript generation service
- **3.4**: Progress tracking for transcription

### Chunk 4: Music Intelligence (Weeks 6-7)
- **4.1**: OpenAI API integration
- **4.2**: Music mention extraction prompts
- **4.3**: Response parsing and validation
- **4.4**: Artist-Song formatting service

### Chunk 5: Apple Music Search (Week 8)
- **5.1**: Basic MusicKit search implementation
- **5.2**: Match confidence scoring
- **5.3**: Search result processing
- **5.4**: Automatic match selection logic

### Chunk 6: Match Selection UI (Weeks 9-10)
- **6.1**: Card-based UI framework
- **6.2**: Gesture handling (swipe/tap)
- **6.3**: Match preview functionality
- **6.4**: Selection state management

### Chunk 7: Playlist Creation (Week 11)
- **7.1**: Apple Music playlist generation
- **7.2**: Chronological ordering implementation
- **7.3**: Error handling for playlist operations
- **7.4**: Success/failure feedback

### Chunk 8: Integration & Testing (Weeks 12-13)
- **8.1**: End-to-end workflow integration
- **8.2**: Comprehensive error handling
- **8.3**: Unit and integration tests
- **8.4**: Performance optimization and polish

## Final Right-Sized Implementation Steps

### Chunk 1: Foundation (Week 1)
**1.1: Project Setup (Day 1-2)**
- Create new Xcode project with SwiftUI + macOS target
- Configure Info.plist for file access and network permissions
- Add MusicKit capability
- Create basic app structure with ContentView

**1.2: Core Data Models (Day 3)**
- Define `Song` struct (title, artist, appleID, confidence)
- Define `ProcessingStatus` enum (idle, processing, complete, error)
- Define `MatchStatus` enum (auto, pending, selected, skipped)
- Create `PlaylistRequest` model for workflow state

**1.3: Service Architecture (Day 4-5)**
- Create protocol-based service layer (`AudioProcessor`, `Transcriber`, etc.)
- Implement basic dependency injection container
- Set up async/await error handling patterns
- Create logging utility

### Chunk 2: Content Input (Week 2)
**2.1: File Upload (Day 1-2)**
- Implement file picker UI with drag-drop support
- File validation (audio/video formats)
- Temporary file storage management
- Basic progress feedback

**2.2: URL Input (Day 3)**
- URL input field with validation
- Support for YouTube/podcast URL formats
- Download progress tracking
- Error handling for invalid/unreachable URLs

**2.3: Audio Extraction (Day 4-5)**
- AVFoundation integration for audio extraction
- Video-to-audio conversion pipeline
- File format normalization (to WAV/MP3)
- Cleanup of temporary files

### Chunk 3: Transcription (Week 3)
**3.1: Whisper Integration (Day 1-3)**
- Local Whisper model setup
- Audio preprocessing (chunking, normalization)
- Transcription service implementation
- Progress callback integration

**3.2: Transcript Processing (Day 4-5)**
- Timestamp preservation for chronological ordering
- Text cleaning and formatting
- Error handling for transcription failures
- Basic transcript display for debugging

### Chunk 4: Music Intelligence (Week 4)
**4.1: OpenAI Integration (Day 1-2)**
- OpenAI API client setup
- Secure API key management
- Rate limiting and retry logic
- Response parsing framework

**4.2: Music Extraction (Day 3-5)**
- Craft prompts for music mention detection
- Implement structured JSON response parsing
- Artist-Song normalization and cleaning
- Confidence scoring for extracted matches

### Chunk 5: Apple Music Search (Week 5)
**5.1: MusicKit Search (Day 1-3)**
- Basic MusicKit search implementation
- Search query optimization
- Result filtering and ranking
- Handle API rate limits

**5.2: Match Logic (Day 4-5)**
- Confidence scoring algorithm
- Auto-selection criteria implementation
- Fuzzy matching for close results
- Batch search optimization

### Chunk 6: Match Selection UI (Week 6)
**6.1: Card Interface (Day 1-3)**
- SwiftUI card component design
- Basic swipe gesture recognition
- Card stack layout and animation
- Selection state visualization

**6.2: Interaction Logic (Day 4-5)**
- Tap vs swipe gesture handling
- Match preview with 30-second clips
- Skip/select action implementation
- Progress through ambiguous matches

### Chunk 7: Playlist Creation (Week 7)
**7.1: Apple Music Integration (Day 1-3)**
- MusicKit playlist creation
- Handle user permissions and auth
- Song addition with error handling
- Playlist metadata (name, description)

**7.2: Workflow Completion (Day 4-5)**
- Chronological ordering implementation
- Success/failure feedback UI
- Final playlist preview
- Open in Apple Music functionality

### Chunk 8: Integration & Polish (Week 8)
**8.1: End-to-End Testing (Day 1-3)**
- Integration test suite
- Error scenario testing
- Performance testing with large files
- Memory leak detection

**8.2: UI/UX Polish (Day 4-5)**
- Progress bar refinements
- Error message improvements
- Accessibility features
- App icon and branding

## Step Size Analysis & Validation

**✅ Right-Sized Steps:**
- Each step is 1-5 days of focused development
- Steps build incrementally with clear dependencies
- Each step produces testable, demonstrable progress
- Risk is minimized with early validation points
- Each step can be thoroughly tested before moving forward

**✅ Safe Implementation:**
- Foundation established before complex features
- External API integrations isolated and testable
- UI components built incrementally
- Error handling built in from the start

**✅ Forward Progress:**
- Week 1: Working app with basic file input
- Week 2: Audio processing pipeline functional
- Week 3: Transcription working end-to-end
- Week 4: Music extraction producing results
- Week 5: Apple Music search operational
- Week 6: User can review and select matches
- Week 7: Complete workflow creating playlists
- Week 8: Production-ready polish

This 8-week plan provides an optimal balance of safety, testability, and meaningful progress milestones. Each step is small enough to implement confidently while being substantial enough to advance the project meaningfully toward the final goal.