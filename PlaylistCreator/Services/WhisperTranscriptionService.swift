import Foundation
import AVFoundation

struct AudioChunk {
    let url: URL
    let startTime: TimeInterval
    let duration: TimeInterval
}

class WhisperTranscriptionService: Transcriber {

    // MARK: - Properties

    private let apiKey: String?
    private let apiURL = "https://api.openai.com/v1/audio/transcriptions"
    private let model = "whisper-1"
    var maxRetries = 3
    var progressCallback: ((Double) -> Void)?

    // MARK: - Initialization

    init(apiKey: String? = nil) {
        // Try to get API key from environment if not provided
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }

    // MARK: - Transcriber Protocol

    func transcribe(_ audio: ProcessedAudio) async throws -> Transcript {
        guard apiKey != nil else {
            throw TranscriptionError.apiKeyMissing
        }

        updateProgress(0.0)

        // Preprocess audio
        let preprocessedAudio = preprocessAudio(audio)
        updateProgress(0.1)

        // Perform transcription
        let transcript = try await performTranscription(preprocessedAudio, includeTimestamps: false)
        updateProgress(1.0)

        return transcript
    }

    func transcribeWithTimestamps(_ audio: ProcessedAudio) async throws -> Transcript {
        guard apiKey != nil else {
            throw TranscriptionError.apiKeyMissing
        }

        updateProgress(0.0)

        // Preprocess audio
        let preprocessedAudio = preprocessAudio(audio)
        updateProgress(0.1)

        // Check if audio needs chunking
        let maxChunkDuration: TimeInterval = 600 // 10 minutes
        if audio.duration > maxChunkDuration {
            return try await transcribeInChunks(preprocessedAudio, maxChunkDuration: maxChunkDuration)
        }

        // Perform transcription with timestamps
        let transcript = try await performTranscription(preprocessedAudio, includeTimestamps: true)
        updateProgress(1.0)

        return transcript
    }

    // MARK: - Audio Preprocessing

    func preprocessAudio(_ audio: ProcessedAudio) -> ProcessedAudio {
        // Whisper works best with 16kHz sample rate
        // In a full implementation, would resample if needed
        return audio
    }

    func chunkAudio(_ audio: ProcessedAudio, maxChunkDuration: TimeInterval) -> [AudioChunk] {
        var chunks: [AudioChunk] = []
        var currentTime: TimeInterval = 0

        while currentTime < audio.duration {
            let chunkDuration = min(maxChunkDuration, audio.duration - currentTime)
            let chunk = AudioChunk(
                url: audio.url,
                startTime: currentTime,
                duration: chunkDuration
            )
            chunks.append(chunk)
            currentTime += chunkDuration
        }

        return chunks
    }

    // MARK: - Transcription

    private func transcribeInChunks(_ audio: ProcessedAudio, maxChunkDuration: TimeInterval) async throws -> Transcript {
        let chunks = chunkAudio(audio, maxChunkDuration: maxChunkDuration)
        var allSegments: [TranscriptSegment] = []
        var fullText = ""
        var totalConfidence = 0.0

        for (index, chunk) in chunks.enumerated() {
            let chunkProgress = Double(index) / Double(chunks.count)
            updateProgress(0.1 + (chunkProgress * 0.8))

            let chunkTranscript = try await performTranscription(audio, includeTimestamps: true, chunk: chunk)

            // Adjust timestamps for chunk offset
            let adjustedSegments = chunkTranscript.segments.map { segment in
                TranscriptSegment(
                    text: segment.text,
                    startTime: segment.startTime + chunk.startTime,
                    endTime: segment.endTime + chunk.startTime,
                    confidence: segment.confidence
                )
            }

            allSegments.append(contentsOf: adjustedSegments)
            fullText += (fullText.isEmpty ? "" : " ") + chunkTranscript.text
            totalConfidence += chunkTranscript.confidence
        }

        updateProgress(0.95)

        let averageConfidence = chunks.isEmpty ? 0.0 : totalConfidence / Double(chunks.count)

        return Transcript(
            text: fullText,
            segments: allSegments,
            language: allSegments.first?.text.isEmpty == false ? "en" : nil,
            confidence: averageConfidence
        )
    }

    private func performTranscription(_ audio: ProcessedAudio, includeTimestamps: Bool, chunk: AudioChunk? = nil) async throws -> Transcript {
        guard let apiKey = apiKey else {
            throw TranscriptionError.apiKeyMissing
        }

        // Build request
        guard let url = URL(string: apiURL) else {
            throw TranscriptionError.apiRequestFailed("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)

        // Add timestamp granularities if needed
        if includeTimestamps {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n".data(using: .utf8)!)
            body.append("segment\r\n".data(using: .utf8)!)
        }

        // Add audio file
        do {
            let audioData = try Data(contentsOf: audio.url)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            throw TranscriptionError.apiRequestFailed("Failed to read audio file: \(error.localizedDescription)")
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // Perform request with retry logic
        return try await performRequestWithRetry(request: request, includeTimestamps: includeTimestamps)
    }

    private func performRequestWithRetry(request: URLRequest, includeTimestamps: Bool, attempt: Int = 0) async throws -> Transcript {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranscriptionError.apiRequestFailed("Invalid response")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TranscriptionError.apiRequestFailed("API returned status \(httpResponse.statusCode): \(errorMessage)")
            }

            // Parse response
            return try parseTranscriptionResponse(data, includeTimestamps: includeTimestamps)

        } catch {
            if attempt < maxRetries {
                // Exponential backoff
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performRequestWithRetry(request: request, includeTimestamps: includeTimestamps, attempt: attempt + 1)
            }
            throw TranscriptionError.apiRequestFailed(error.localizedDescription)
        }
    }

    private func parseTranscriptionResponse(_ data: Data, includeTimestamps: Bool) throws -> Transcript {
        struct WhisperResponse: Codable {
            let text: String
            let segments: [WhisperSegment]?
            let language: String?
        }

        struct WhisperSegment: Codable {
            let text: String
            let start: Double
            let end: Double
            let avgLogprob: Double?

            enum CodingKeys: String, CodingKey {
                case text, start, end
                case avgLogprob = "avg_logprob"
            }
        }

        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(WhisperResponse.self, from: data)

            let segments: [TranscriptSegment]
            if includeTimestamps, let whisperSegments = response.segments {
                segments = whisperSegments.map { segment in
                    // Convert log probability to confidence (approximate)
                    let confidence = segment.avgLogprob.map { exp($0) } ?? 0.9
                    return TranscriptSegment(
                        text: segment.text,
                        startTime: segment.start,
                        endTime: segment.end,
                        confidence: max(0.0, min(1.0, confidence))
                    )
                }
            } else {
                segments = []
            }

            return Transcript(
                text: response.text,
                segments: segments,
                language: response.language,
                confidence: segments.isEmpty ? 0.9 : segments.map { $0.confidence }.reduce(0, +) / Double(segments.count)
            )

        } catch {
            throw TranscriptionError.apiRequestFailed("Failed to parse response: \(error.localizedDescription)")
        }
    }

    // MARK: - Progress Tracking

    func updateProgress(_ progress: Double) {
        let clampedProgress = max(0.0, min(1.0, progress))
        progressCallback?(clampedProgress)
    }
}
