# Swift Playlist Creator App - Specification

## Overview
A Swift app (initially MacOS, expanding to iOS/iPadOS) that creates Apple Music playlists by analyzing audio content for music mentions and recommendations.

## Primary Function
Create Apple Music playlists based on indirect or abstract input by analyzing content that discusses music.

## Core Workflow

### 1. Content Input
**Supported Formats:**
- URLs (podcasts, YouTube videos)
- Uploaded audio/video files

**Processing:**
- Extract audio from both audio-only and video content
- Process video files for audio portions only (ignore visual content)
- Handle entire content duration automatically

### 2. Transcription
- Use OpenAI Whisper (cloud service or downloadable local model)
- Generate complete transcript of audio content
- Process full duration without user-specified time ranges

### 3. Music Extraction
- Use language model (GPT) to parse transcript
- Identify song titles and artist names that are explicitly mentioned
- Capture album and artist recommendations
- Include ALL music mentions regardless of context
- Format extractions into clean "Artist - Song Title" structure

### 4. Apple Music Integration
**Search & Matching:**
- Query Apple Music catalog using LLM-formatted song data
- Auto-select obvious first matches without user confirmation
- Present multiple options via card-based interface for ambiguous matches

**User Interface for Match Selection:**
- Card-based interface where users swipe or tap to choose
- Handle uncertain matches requiring user review
- Skip confirmation for clear/obvious matches

### 5. Playlist Creation
**Organization:**
- Songs ordered chronologically based on mention order in original content
- Maintains narrative flow of source material
- Direct creation in user's Apple Music account (requires full API permissions)

## Technical Architecture

### Content Processing
- Audio extraction from URLs and uploaded files
- Support for both audio and video input formats

### Speech Recognition
- OpenAI Whisper for speech-to-text conversion
- Cloud service or local downloadable model option

### Music Recognition
- Language model (GPT) for context-aware music mention extraction
- Structured output formatting for Apple Music API queries

### User Experience
- Simple progress bar for entire workflow (upload → transcribe → extract → match → create)
- Silent error handling with final results display
- Card-based selection interface for ambiguous matches

## Key Design Decisions

1. **Comprehensive Inclusion:** Include every music mention regardless of context - users can delete unwanted songs post-creation
2. **Chronological Ordering:** Preserve narrative flow by maintaining mention order from source content
3. **Automated Processing:** Handle entire content duration without user segmentation
4. **Direct Integration:** Create playlists directly in Apple Music rather than generating shareable links
5. **Balanced Automation:** Auto-confirm obvious matches while allowing user choice for ambiguous ones
6. **Streamlined UX:** Simple progress indication with detailed failure handling behind the scenes

## Future Considerations
- Guided parameter feature (creating playlists from descriptive criteria like "songs from 2000s in style of Bowling for Soup")
- iOS/iPadOS expansion after MacOS implementation
- Enhanced filtering options for music mention detection