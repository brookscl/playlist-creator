import Foundation

class MockTranscriber: Transcriber {
    var shouldThrowError = false
    var transcribeResult: Transcript?
    var transcribeWithTimestampsResult: Transcript?
    
    func transcribe(_ audio: ProcessedAudio) async throws -> Transcript {
        if shouldThrowError {
            throw TranscriptionError.transcriptionEmpty
        }
        return transcribeResult ?? Transcript(
            text: "This is a mock transcription of the audio content.",
            segments: [],
            language: "en",
            confidence: 0.95
        )
    }
    
    func transcribeWithTimestamps(_ audio: ProcessedAudio) async throws -> Transcript {
        if shouldThrowError {
            throw TranscriptionError.apiRequestFailed("Mock error")
        }
        return transcribeWithTimestampsResult ?? Transcript(
            text: "This is a mock transcription with timestamps.",
            segments: [
                TranscriptSegment(text: "This is a mock transcription", startTime: 0.0, endTime: 2.5, confidence: 0.9),
                TranscriptSegment(text: "with timestamps.", startTime: 2.5, endTime: 4.0, confidence: 0.95)
            ],
            language: "en",
            confidence: 0.92
        )
    }
}
