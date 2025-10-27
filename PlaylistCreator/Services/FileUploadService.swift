import Foundation
import AVFoundation
import UniformTypeIdentifiers

enum FileType {
    case audio
    case video
    case unsupported
}

struct FileValidation {
    let url: URL
    let fileExtension: String
    let fileType: FileType
    let isValid: Bool
    let fileSize: Int64?
    
    init(url: URL, fileExtension: String, fileType: FileType, isValid: Bool, fileSize: Int64? = nil) {
        self.url = url
        self.fileExtension = fileExtension
        self.fileType = fileType
        self.isValid = isValid
        self.fileSize = fileSize
    }
}

class FileUploadService: AudioProcessor {

    // MARK: - Properties

    private let supportedAudioFormats = Set([
        "mp3", "wav", "m4a", "aac", "flac", "ogg"
    ])

    private let supportedVideoFormats = Set([
        "mp4", "mov", "avi", "mkv", "webm", "m4v"
    ])

    private var temporaryFiles: [URL] = []
    private let temporaryDirectory: URL
    private let urlValidator = URLValidator()
    private let urlDownloader: URLDownloader

    var progressCallback: ((Double) -> Void)?
    
    // MARK: - Initialization

    init() {
        // Create a dedicated temporary directory for this service
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlaylistCreator")
            .appendingPathComponent(UUID().uuidString)

        self.temporaryDirectory = tempDir
        self.urlDownloader = URLDownloader()

        // Create the directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        // Setup URL downloader progress callback
        setupURLDownloaderProgress()
    }

    private func setupURLDownloaderProgress() {
        urlDownloader.progressCallback = { [weak self] progress in
            self?.progressCallback?(progress)
        }
    }
    
    deinit {
        cleanupAllTemporaryFiles()
    }
    
    // MARK: - AudioProcessor Protocol Implementation
    
    func processFileUpload(_ url: URL) async throws -> ProcessedAudio {
        updateProgress(0.0)
        
        // Validate file
        let validation = validateFile(url)
        let fileValidation: FileValidation
        switch validation {
        case .failure(let error):
            throw error
        case .success(let validationResult):
            fileValidation = validationResult
            if !validationResult.isValid {
                throw AudioProcessingError.unsupportedFormat(validationResult.fileExtension)
            }
        }
        
        updateProgress(0.2)
        
        // Create temporary copy
        let tempURL = try createTemporaryFile(from: url)
        updateProgress(0.4)
        
        // Extract audio if it's a video file
        let audioURL: URL
        if fileValidation.fileType == .video {
            audioURL = try await extractAudioFromVideo(tempURL)
            updateProgress(0.7)
        } else {
            audioURL = tempURL
            updateProgress(0.6)
        }
        
        // Normalize audio format
        let normalizedURL = try await normalizeAudioFormat(audioURL)
        updateProgress(0.9)
        
        // Get audio duration
        let duration = try await getAudioDuration(normalizedURL)
        updateProgress(1.0)
        
        return ProcessedAudio(
            url: normalizedURL,
            duration: duration,
            format: .wav,
            sampleRate: 16000
        )
    }
    
    func processURL(_ url: URL) async throws -> ProcessedAudio {
        updateProgress(0.0)

        // Check if it's a local file URL
        if url.isFileURL {
            return try await processFileUpload(url)
        }

        // Validate URL type
        let urlType = urlValidator.validateURL(url)

        guard urlType != .unsupported else {
            throw AudioProcessingError.unsupportedFormat("URL type not supported")
        }

        updateProgress(0.1)

        // Handle YouTube URLs - would need youtube-dl or similar
        if urlType == .youtube {
            throw AudioProcessingError.notImplemented // Will implement in future
        }

        // Handle podcast RSS feeds - would need RSS parser
        if urlType == .podcast {
            throw AudioProcessingError.notImplemented // Will implement in future
        }

        // Download direct audio/video files
        updateProgress(0.2)
        let downloadedURL = try await urlDownloader.download(from: url)
        temporaryFiles.append(downloadedURL)

        updateProgress(0.5)

        // Process the downloaded file
        return try await processDownloadedFile(downloadedURL, urlType: urlType)
    }

    private func processDownloadedFile(_ url: URL, urlType: URLType) async throws -> ProcessedAudio {
        // Extract audio if it's a video file
        let audioURL: URL
        if urlType == .directVideo {
            audioURL = try await extractAudioFromVideo(url)
            updateProgress(0.7)
        } else {
            audioURL = url
            updateProgress(0.6)
        }

        // Normalize audio format
        let normalizedURL = try await normalizeAudioFormat(audioURL)
        updateProgress(0.9)

        // Get audio duration
        let duration = try await getAudioDuration(normalizedURL)
        updateProgress(1.0)

        return ProcessedAudio(
            url: normalizedURL,
            duration: duration,
            format: .wav,
            sampleRate: 16000
        )
    }
    
    func extractAudioFromVideo(_ videoURL: URL) async throws -> URL {
        updateProgress(0.0)

        let asset = AVAsset(url: videoURL)

        // Check if asset has audio tracks
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw AudioProcessingError.extractionFailed("No audio tracks found in video")
        }

        updateProgress(0.3)

        // Create export session - use passthrough for WAV compatibility
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw AudioProcessingError.extractionFailed("Failed to create export session")
        }

        // Configure output as WAV for whisper-cli compatibility
        let outputURL = temporaryDirectory.appendingPathComponent("\(UUID().uuidString).wav")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .wav
        
        updateProgress(0.5)
        
        // Perform export
        await exportSession.export()
        
        updateProgress(0.9)
        
        switch exportSession.status {
        case .completed:
            temporaryFiles.append(outputURL)
            updateProgress(1.0)
            return outputURL
        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown export error"
            throw AudioProcessingError.extractionFailed(errorMessage)
        case .cancelled:
            throw AudioProcessingError.extractionFailed("Export was cancelled")
        default:
            throw AudioProcessingError.extractionFailed("Export failed with status: \(exportSession.status.rawValue)")
        }
    }
    
    func normalizeAudioFormat(_ audioURL: URL) async throws -> URL {
        updateProgress(0.0)

        let asset = AVAsset(url: audioURL)

        // Use WAV format for compatibility with whisper-cli (supports: flac, mp3, ogg, wav)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw AudioProcessingError.normalizationFailed("Failed to create normalization export session")
        }

        updateProgress(0.3)

        // Configure for WAV output (compatible with whisper-cli)
        let outputURL = temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_normalized.wav")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .wav
        
        updateProgress(0.5)
        
        // Perform normalization export
        await exportSession.export()
        
        updateProgress(0.9)
        
        switch exportSession.status {
        case .completed:
            temporaryFiles.append(outputURL)
            updateProgress(1.0)
            return outputURL
        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown normalization error"
            throw AudioProcessingError.normalizationFailed(errorMessage)
        case .cancelled:
            throw AudioProcessingError.normalizationFailed("Normalization was cancelled")
        default:
            throw AudioProcessingError.normalizationFailed("Normalization failed with status: \(exportSession.status.rawValue)")
        }
    }
    
    // MARK: - File Validation
    
    func validateFile(_ url: URL) -> Result<FileValidation, AudioProcessingError> {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failure(.fileNotFound(url.path))
        }
        
        let fileExtension = extractFileExtension(url.lastPathComponent)
        let fileType = determineFileType(fileExtension)
        let isValid = isValidFileFormat(fileExtension)
        
        // Get file size
        let fileSize: Int64?
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            fileSize = attributes[.size] as? Int64
        } catch {
            fileSize = nil
        }
        
        let validation = FileValidation(
            url: url,
            fileExtension: fileExtension,
            fileType: fileType,
            isValid: isValid,
            fileSize: fileSize
        )
        
        return .success(validation)
    }
    
    func isValidFileFormat(_ fileExtension: String) -> Bool {
        let lowercaseExtension = fileExtension.lowercased()
        return supportedAudioFormats.contains(lowercaseExtension) || 
               supportedVideoFormats.contains(lowercaseExtension)
    }
    
    func isValidAudioFormat(_ fileExtension: String) -> Bool {
        return supportedAudioFormats.contains(fileExtension.lowercased())
    }
    
    func isValidVideoFormat(_ fileExtension: String) -> Bool {
        return supportedVideoFormats.contains(fileExtension.lowercased())
    }
    
    func extractFileExtension(_ filename: String) -> String {
        guard let lastDotIndex = filename.lastIndex(of: ".") else {
            return ""
        }
        
        let extensionStartIndex = filename.index(after: lastDotIndex)
        let fileExtension = String(filename[extensionStartIndex...])
        
        return fileExtension.isEmpty ? "" : fileExtension
    }
    
    private func determineFileType(_ fileExtension: String) -> FileType {
        let lowercaseExtension = fileExtension.lowercased()
        
        if supportedAudioFormats.contains(lowercaseExtension) {
            return .audio
        } else if supportedVideoFormats.contains(lowercaseExtension) {
            return .video
        } else {
            return .unsupported
        }
    }
    
    // MARK: - Temporary File Management
    
    func createTemporaryFile(from originalURL: URL) throws -> URL {
        let filename = originalURL.lastPathComponent
        let tempURL = temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_\(filename)")
        
        do {
            try FileManager.default.copyItem(at: originalURL, to: tempURL)
            temporaryFiles.append(tempURL)
            return tempURL
        } catch {
            throw AudioProcessingError.fileNotFound("Failed to create temporary file: \(error.localizedDescription)")
        }
    }
    
    func cleanupTemporaryFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            temporaryFiles.removeAll { $0 == url }
        } catch {
            // Silently ignore cleanup errors - file might already be gone
        }
    }
    
    func cleanupAllTemporaryFiles() {
        for url in temporaryFiles {
            cleanupTemporaryFile(url)
        }
        temporaryFiles.removeAll()
        
        // Also remove the temporary directory if it's empty
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }
    
    func performPostProcessingCleanup() {
        cleanupAllTemporaryFiles()
    }
    
    // MARK: - Progress Tracking
    
    func updateProgress(_ progress: Double) {
        let clampedProgress = max(0.0, min(1.0, progress))
        progressCallback?(clampedProgress)
    }
    
    // MARK: - Helper Methods
    
    private func getAudioDuration(_ url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
}
