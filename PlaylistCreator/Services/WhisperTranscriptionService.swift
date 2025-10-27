import Foundation
import AVFoundation

struct AudioChunk {
    let url: URL
    let startTime: TimeInterval
    let duration: TimeInterval
}

class WhisperTranscriptionService: Transcriber {

    // MARK: - Properties

    private let whisperCLIPath: String
    private let modelPath: String?
    var maxRetries = 3
    var progressCallback: ((Double) -> Void)?

    // MARK: - Initialization

    init(whisperCLIPath: String = "/opt/homebrew/bin/whisper-cli",
         modelPath: String? = "/Users/chrisbrooks/bin/ggml-large-v3-turbo-q8_0.bin") {
        self.whisperCLIPath = whisperCLIPath
        self.modelPath = modelPath
    }

    // MARK: - Transcriber Protocol

    func transcribe(_ audio: ProcessedAudio) async throws -> Transcript {
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
        // Build command arguments
        var arguments = [String]()

        // Add model path if provided
        if let modelPath = modelPath {
            arguments.append(contentsOf: ["-m", modelPath])
        }

        // Output JSON for parsing
        arguments.append("--output-json")

        // Include detailed JSON with timestamps if requested
        if includeTimestamps {
            arguments.append("--output-json-full")
        }

        // Disable console output
        arguments.append("--no-prints")

        // Add the audio file path
        arguments.append(audio.url.path)

        // Execute CLI command
        return try await executeWhisperCLI(arguments: arguments, includeTimestamps: includeTimestamps, audioURL: audio.url)
    }

    private func executeWhisperCLI(arguments: [String], includeTimestamps: Bool, audioURL: URL, attempt: Int = 0) async throws -> Transcript {
        updateProgress(0.2)

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: whisperCLIPath)
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            updateProgress(0.3)

            try process.run()
            process.waitUntilExit()

            updateProgress(0.8)

            _ = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            guard process.terminationStatus == 0 else {
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw TranscriptionError.apiRequestFailed("Whisper CLI failed with status \(process.terminationStatus): \(errorMessage)")
            }

            updateProgress(0.9)

            // Parse JSON output file - whisper-cli appends .json to the full filename
            let jsonURL = URL(fileURLWithPath: audioURL.path + ".json")
            return try parseWhisperJSONOutput(jsonURL: jsonURL, includeTimestamps: includeTimestamps)

        } catch {
            if attempt < maxRetries {
                // Exponential backoff
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWhisperCLI(arguments: arguments, includeTimestamps: includeTimestamps, audioURL: audioURL, attempt: attempt + 1)
            }
            throw TranscriptionError.apiRequestFailed(error.localizedDescription)
        }
    }

    private func parseWhisperJSONOutput(jsonURL: URL, includeTimestamps: Bool) throws -> Transcript {
        struct WhisperCLIResponse: Codable {
            let systeminfo: String?
            let model: ModelInfo?
            let params: ParamsInfo?
            let result: ResultInfo?
            let transcription: [TranscriptionSegment]?

            struct ModelInfo: Codable {
                let type: String?
                let multilingual: Bool?
                let vocab: Int?
                let audio: AudioInfo?

                struct AudioInfo: Codable {
                    let ctx: Int?
                    let state: Int?
                    let head: Int?
                    let layer: Int?
                }
            }

            struct ParamsInfo: Codable {
                let language: String?
                let translate: Bool?
            }

            struct ResultInfo: Codable {
                let language: String?
            }

            struct TranscriptionSegment: Codable {
                let timestamps: Timestamps?
                let offsets: Offsets?
                let text: String

                struct Timestamps: Codable {
                    let from: String
                    let to: String
                }

                struct Offsets: Codable {
                    let from: Int
                    let to: Int
                }
            }
        }

        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw TranscriptionError.apiRequestFailed("JSON output file not found at \(jsonURL.path)")
        }

        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        let response = try decoder.decode(WhisperCLIResponse.self, from: data)

        // Clean up JSON file
        try? FileManager.default.removeItem(at: jsonURL)

        // Extract full text
        let fullText = response.transcription?.map { $0.text }.joined(separator: " ") ?? ""

        // Extract segments with timestamps if requested
        let segments: [TranscriptSegment]
        if includeTimestamps, let transcriptionSegments = response.transcription {
            segments = transcriptionSegments.compactMap { segment in
                guard let offsets = segment.offsets else { return nil }
                let startTime = Double(offsets.from) / 1000.0  // Convert ms to seconds
                let endTime = Double(offsets.to) / 1000.0

                return TranscriptSegment(
                    text: segment.text.trimmingCharacters(in: .whitespaces),
                    startTime: startTime,
                    endTime: endTime,
                    confidence: 0.9  // CLI doesn't provide confidence scores
                )
            }
        } else {
            segments = []
        }

        let language = response.result?.language ?? response.params?.language ?? "en"

        return Transcript(
            text: fullText.trimmingCharacters(in: .whitespaces),
            segments: segments,
            language: language,
            confidence: 0.9
        )
    }

    // MARK: - Progress Tracking

    func updateProgress(_ progress: Double) {
        let clampedProgress = max(0.0, min(1.0, progress))
        progressCallback?(clampedProgress)
    }
}
