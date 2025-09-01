import Foundation

protocol Transcriber {
    func transcribe(_ audio: ProcessedAudio) async throws -> Transcript
    func transcribeWithTimestamps(_ audio: ProcessedAudio) async throws -> Transcript
}

struct Transcript: Equatable {
    let text: String
    let segments: [TranscriptSegment]
    let language: String?
    let confidence: Double
    
    init(text: String, segments: [TranscriptSegment] = [], language: String? = nil, confidence: Double = 1.0) {
        self.text = text
        self.segments = segments
        self.language = language
        self.confidence = confidence
    }
}

struct TranscriptSegment: Equatable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Double
    
    init(text: String, startTime: TimeInterval, endTime: TimeInterval, confidence: Double = 1.0) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
}

class DefaultTranscriber: Transcriber {
    private let apiKey: String?
    
    init(apiKey: String? = nil) {
        self.apiKey = apiKey
    }
    
    func transcribe(_ audio: ProcessedAudio) async throws -> Transcript {
        throw TranscriptionError.notImplemented
    }
    
    func transcribeWithTimestamps(_ audio: ProcessedAudio) async throws -> Transcript {
        throw TranscriptionError.notImplemented
    }
}
