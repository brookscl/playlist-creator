# Transcript File Upload Feature

## Overview

Added support for direct transcript file upload to bypass the expensive audio transcription step. This enables much faster testing and supports users who already have transcripts from podcasts, YouTube videos, or other sources.

## Supported Formats

### 1. Plain Text (.txt)
Simple text files containing the transcript without timestamps.

```txt
Welcome to the podcast! Today we're discussing some great music.
I really recommend "Song Title" by Artist Name...
```

**Use case:** Manual transcripts, simple text dumps, podcast show notes

### 2. JSON (.json)
Structured format matching our Transcript model with optional segments and timestamps.

```json
{
  "text": "Full transcript text here.",
  "segments": [
    {
      "text": "First segment",
      "startTime": 0.0,
      "endTime": 5.0,
      "confidence": 0.95
    }
  ],
  "language": "en",
  "confidence": 0.96
}
```

**Use case:** Exported transcripts from Whisper API, pre-processed data, test fixtures

### 3. SubRip (.srt)
Standard subtitle format with timestamp ranges.

```srt
1
00:00:00,000 --> 00:00:05,000
First subtitle line

2
00:00:05,000 --> 00:00:10,000
Second subtitle line
```

**Use case:** YouTube auto-captions, video subtitles, podcast episode subtitles

### 4. WebVTT (.vtt)
Web Video Text Tracks format with WEBVTT header.

```vtt
WEBVTT

00:00:00.000 --> 00:00:05.000
First caption

00:00:05.000 --> 00:00:10.000
Second caption
```

**Use case:** Web video captions, streaming service subtitles

## How to Use

### Via UI

1. Open the app
2. Select "Transcript" from the input method segmented control
3. Either:
   - Drag and drop a transcript file (.txt, .json, .srt, .vtt)
   - Click "Choose Transcript File" to select from file picker
4. The transcript loads instantly (no transcription needed!)
5. Click "Continue" to proceed to music extraction

### Workflow Comparison

**Traditional Audio Workflow:**
1. Upload audio/video file (10s - 1min depending on size)
2. Extract audio if video (10s - 30s)
3. Transcribe via Whisper API (2-10 minutes for podcast)
4. Continue to music extraction

**New Transcript Workflow:**
1. Upload transcript file (< 1 second)
2. Continue to music extraction

**Time Savings:** ~2-10 minutes per test!

## Implementation Details

### TranscriptFileService
- File format detection based on extension
- Parsing implementations for each format
- URL download support for remote transcripts
- Progress tracking during load/parse
- Comprehensive error handling

### Parser Features
- **Plain Text:** Simple string loading with whitespace trimming
- **JSON:** Full Codable support matching Transcript model
- **SRT:** Timestamp parsing (HH:MM:SS,mmm format), multiline subtitle support
- **VTT:** WEBVTT header validation, cue identifier handling, NOTE comment filtering

### UI Integration
- Three-way segmented picker: Audio/Video | URL | Transcript
- Dedicated upload area for transcripts
- Drag-and-drop support for transcript files
- File type validation and user feedback
- Success messaging distinguishes workflows

### Testing
- 31 comprehensive unit tests
- Format parser tests for all types
- Edge case handling (empty files, invalid formats, malformed data)
- URL validation tests
- Sample transcript included: `TestFiles/sample-transcript.txt`

## Benefits

1. **Faster Testing:** Develop and test music extraction without waiting for transcription
2. **Existing Transcripts:** Support users who already have transcripts
3. **Alternative Sources:** Enable workflows with show notes, video captions, manual transcripts
4. **Timestamp Preservation:** SRT and VTT formats maintain chronological ordering
5. **No Breaking Changes:** Existing audio/video workflow unchanged

## Example Use Cases

### Podcast Episode Testing
Use podcast show notes or existing transcripts to quickly test playlist creation without re-transcribing.

### YouTube Video Captions
Download auto-generated or community captions from YouTube (.srt or .vtt) and upload directly.

### Manual Curation
Create custom transcript files with specific music mentions for testing edge cases.

### Batch Processing
Pre-transcribe multiple files offline, then quickly process them through the music extraction workflow.

## API

### TranscriptFileService

```swift
let service = TranscriptFileService()

// Load from local file
let transcript = try await service.loadTranscript(from: fileURL)

// Load from URL
let transcript = try await service.loadTranscript(from: "https://example.com/transcript.txt")

// Detect format
let format = service.detectFormat(from: fileURL)
// Returns: .plainText, .json, .srt, .vtt, or .unsupported

// Validate URL
let isValid = service.isValidTranscriptURL("https://example.com/file.srt")
```

### FileUploadViewModel

```swift
// Process transcript file
await viewModel.processTranscript(fileURL)

// After processing, transcript is available
if let transcript = viewModel.transcript {
    // Continue to music extraction
}
```

## Future Enhancements

- [ ] Support for additional formats (ASS/SSA subtitles, Word docs, etc.)
- [ ] Batch transcript processing (multiple files at once)
- [ ] Transcript editing/preview before processing
- [ ] Auto-detection of format without file extension
- [ ] Transcript export after processing (save Whisper output)
- [ ] Cloud storage integration (Dropbox, Google Drive URLs)

## Sample Transcript

A sample transcript file is included at `TestFiles/sample-transcript.txt` with 8 song recommendations from various artists. This can be used for quick testing of the complete workflow.

Songs mentioned in sample:
- Bohemian Rhapsody - Queen
- Stairway to Heaven - Led Zeppelin
- Blinding Lights - The Weeknd
- drivers license - Olivia Rodrigo
- Imagine - John Lennon
- Superstition - Stevie Wonder
- Mr. Brightside - The Killers
- Shallow - Lady Gaga & Bradley Cooper
