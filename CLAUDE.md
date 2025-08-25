# Playlist Creator - Swift macOS Application

## Project Overview

This is a Swift macOS application that creates Apple Music playlists by analyzing audio/video content for music mentions. The app processes podcasts, YouTube videos, and uploaded files to extract song recommendations and automatically generate playlists.

## Core Functionality

**Primary Feature:** Create Apple Music playlists from indirect/abstract input by analyzing content that discusses music.

**Workflow:**
1. **Content Input** - Accept URLs (YouTube, podcasts) or uploaded audio/video files
2. **Audio Processing** - Extract audio from video files, normalize formats
3. **Transcription** - Use OpenAI Whisper to convert audio to text with timestamps
4. **Music Extraction** - Use GPT to identify song titles and artist mentions from transcript
5. **Apple Music Search** - Search Apple Music catalog and match songs with confidence scoring
6. **User Review** - Present ambiguous matches via card-based interface for user selection
7. **Playlist Creation** - Generate chronological playlist directly in user's Apple Music account

## Project Structure

```
playlist-maker/
├── docs/
│   ├── spec.md              # Complete application specification
│   ├── iteration-plan.md    # 8-week development plan with detailed steps
│   └── prompts.md          # Test-driven implementation prompts for each step
├── CLAUDE.md               # This context file
└── [Future: Xcode project files]
```

## Key Design Decisions

1. **Comprehensive Inclusion** - Include ALL music mentions regardless of context (users can delete unwanted songs)
2. **Chronological Ordering** - Preserve mention order from original content to maintain narrative flow  
3. **Test-Driven Development** - All implementation follows TDD principles with tests written first
4. **Protocol-Based Architecture** - Service layer uses protocols for testability and dependency injection
5. **Direct Apple Music Integration** - Create playlists directly in user's account via MusicKit
6. **Card-Based Selection** - Intuitive swipe/tap interface for reviewing ambiguous matches
7. **Silent Error Handling** - Handle failures gracefully with simple progress feedback

## Technical Stack

- **Platform:** macOS (SwiftUI), future iOS/iPadOS expansion
- **Audio Processing:** AVFoundation for extraction and preprocessing
- **Speech-to-Text:** OpenAI Whisper (local model or cloud API)
- **Music Intelligence:** OpenAI GPT for extracting music mentions from transcripts
- **Music Integration:** Apple MusicKit for search and playlist creation
- **Architecture:** Protocol-based services with dependency injection
- **Testing:** Comprehensive unit and integration test coverage

## Development Approach

### 8-Week Implementation Plan
- **Week 1:** Foundation and core architecture
- **Week 2:** Content input (file upload, URL processing, audio extraction)  
- **Week 3:** Transcription pipeline with Whisper integration
- **Week 4:** Music intelligence with OpenAI integration
- **Week 5:** Apple Music search and matching logic
- **Week 6:** Card-based UI for match selection
- **Week 7:** Playlist creation and workflow completion
- **Week 8:** Integration testing and production polish

### Key Principles
- **Test-First Development:** Write tests before implementation
- **Incremental Progress:** Each step builds on previous work
- **No Orphaned Code:** Everything integrates into the existing architecture
- **Best Practices:** Follow Swift conventions and Apple HIG guidelines
- **User Experience Focus:** Smooth progress feedback and intuitive interactions

## Service Architecture

**Core Services (Protocol-Based):**
- `AudioProcessor` - Handles file/URL audio extraction and processing
- `Transcriber` - Converts audio to text with timestamp preservation
- `MusicExtractor` - Extracts music mentions from transcripts using LLM
- `MusicSearcher` - Searches Apple Music catalog with confidence scoring
- `PlaylistCreator` - Creates and manages Apple Music playlists

**Supporting Components:**
- `ServiceContainer` - Dependency injection and service registration
- `Logger` - Debugging and monitoring utilities
- `ErrorHandling` - Comprehensive error types and recovery
- `ProgressTracking` - User feedback throughout workflow

## Data Models

**Core Models:**
- `Song` - Represents a song with title, artist, Apple ID, confidence score
- `ProcessingStatus` - Workflow state (idle, processing, complete, error)
- `MatchStatus` - Song match state (auto, pending, selected, skipped)
- `PlaylistRequest` - Complete workflow state and data container

## User Interface

**Main Workflow UI:**
- Clean file/URL input interface with drag-drop support
- Simple progress bar for entire workflow
- Card-based selection interface for ambiguous matches
- Success/failure feedback with playlist integration

**Key UX Features:**
- Drag-and-drop file upload
- URL validation and download progress
- Card swipe/tap gestures for match selection
- 30-second preview playback for song matches
- Direct "Open in Apple Music" integration

## Future Enhancements

1. **Guided Parameter Feature** - Create playlists from descriptive criteria ("songs from 2000s in style of Bowling for Soup")
2. **iOS/iPadOS Expansion** - Port to mobile platforms after macOS completion
3. **Enhanced Filtering** - More sophisticated music mention detection options
4. **Batch Processing** - Handle multiple files/URLs simultaneously
5. **Smart Recommendations** - Suggest additional songs based on detected patterns

## Development Notes

This project follows a methodical, test-driven approach with clear incremental milestones. The architecture is designed for maintainability, testability, and future expansion. Each component is protocol-based to enable comprehensive testing and flexible implementation.

The implementation prompts in `docs/prompts.md` provide detailed, step-by-step guidance for building each component following TDD principles. The iteration plan ensures steady progress with working software at each milestone.

## Current Status

**Planning Phase Complete** - Full specification, development plan, and implementation prompts ready for development.