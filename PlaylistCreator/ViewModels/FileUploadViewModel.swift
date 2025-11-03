import Foundation
import Combine

@MainActor
class FileUploadViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var hasProcessedFile = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var errorMessage: String?
    @Published var currentFileName: String?
    @Published var processedFileName: String?
    @Published var transcriptText: String?
    @Published var transcript: Transcript?
    @Published var isTranscribing = false

    private let fileUploadService: FileUploadService
    private let transcriptionService: Transcriber
    private var cancellables = Set<AnyCancellable>()

    init(fileUploadService: FileUploadService = FileUploadService(),
         transcriptionService: Transcriber = serviceContainer.resolve(Transcriber.self)) {
        self.fileUploadService = fileUploadService
        self.transcriptionService = transcriptionService
        setupProgressTracking()
    }
    
    private func setupProgressTracking() {
        fileUploadService.progressCallback = { [weak self] progress in
            Task { @MainActor in
                self?.progress = progress
                self?.updateStatusMessage(for: progress)
            }
        }
    }
    
    func processFile(_ url: URL) async {
        isProcessing = true
        hasProcessedFile = false
        errorMessage = nil
        currentFileName = url.lastPathComponent
        progress = 0.0

        do {
            // Step 1: Process audio (0-50% progress)
            let processedAudio = try await fileUploadService.processFileUpload(url)
            progress = 0.5

            // Step 2: Transcribe audio (50-100% progress)
            isTranscribing = true
            statusMessage = "Transcribing audio..."
            let transcript = try await transcribeAudio(processedAudio)

            // Success
            hasProcessedFile = true
            processedFileName = currentFileName
            transcriptText = transcript.text
            self.transcript = transcript
            statusMessage = "Processing complete!"
            progress = 1.0

        } catch {
            setError("Processing failed: \(error.localizedDescription)")
        }

        isProcessing = false
        isTranscribing = false
    }

    func processURL(_ url: URL) async {
        isProcessing = true
        hasProcessedFile = false
        errorMessage = nil
        currentFileName = url.absoluteString
        progress = 0.0

        do {
            // Step 1: Download and process audio (0-50% progress)
            let processedAudio = try await fileUploadService.processURL(url)
            progress = 0.5

            // Step 2: Transcribe audio (50-100% progress)
            isTranscribing = true
            statusMessage = "Transcribing audio..."
            let transcript = try await transcribeAudio(processedAudio)

            // Success
            hasProcessedFile = true
            processedFileName = url.lastPathComponent.isEmpty ? "Downloaded file" : url.lastPathComponent
            transcriptText = transcript.text
            self.transcript = transcript
            statusMessage = "Processing complete!"
            progress = 1.0

        } catch {
            setError("Processing failed: \(error.localizedDescription)")
        }

        isProcessing = false
        isTranscribing = false
    }
    
    func setError(_ message: String) {
        errorMessage = message
        isProcessing = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func reset() {
        isProcessing = false
        hasProcessedFile = false
        progress = 0.0
        statusMessage = ""
        errorMessage = nil
        currentFileName = nil
        processedFileName = nil
        transcriptText = nil
        transcript = nil

        // Clean up any temporary files
        fileUploadService.cleanupAllTemporaryFiles()
    }
    
    private func transcribeAudio(_ audio: ProcessedAudio) async throws -> Transcript {
        // Set up progress tracking for transcription
        if let transcriptionService = transcriptionService as? WhisperTranscriptionService {
            transcriptionService.progressCallback = { [weak self] transcriptionProgress in
                Task { @MainActor in
                    // Map transcription progress (0.0-1.0) to overall progress (0.5-1.0)
                    self?.progress = 0.5 + (transcriptionProgress * 0.5)
                    self?.updateTranscriptionStatus(for: transcriptionProgress)
                }
            }
        }

        return try await transcriptionService.transcribeWithTimestamps(audio)
    }

    private func updateStatusMessage(for progress: Double) {
        if isTranscribing {
            updateTranscriptionStatus(for: (progress - 0.5) * 2.0)
        } else {
            switch progress {
            case 0.0..<0.1:
                statusMessage = "Validating file..."
            case 0.1..<0.2:
                statusMessage = "Preparing file..."
            case 0.2..<0.3:
                statusMessage = "Processing audio..."
            case 0.3..<0.4:
                statusMessage = "Normalizing format..."
            case 0.4..<0.5:
                statusMessage = "Finalizing audio processing..."
            default:
                statusMessage = "Processing..."
            }
        }
    }

    private func updateTranscriptionStatus(for progress: Double) {
        switch progress {
        case 0.0..<0.1:
            statusMessage = "Preparing transcription..."
        case 0.1..<0.3:
            statusMessage = "Transcribing audio..."
        case 0.3..<0.7:
            statusMessage = "Processing transcription..."
        case 0.7..<0.95:
            statusMessage = "Finalizing transcription..."
        case 0.95...1.0:
            statusMessage = "Transcription complete!"
        default:
            statusMessage = "Transcribing..."
        }
    }
}
