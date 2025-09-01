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
    
    private let fileUploadService: FileUploadService
    private var cancellables = Set<AnyCancellable>()
    
    init(fileUploadService: FileUploadService = FileUploadService()) {
        self.fileUploadService = fileUploadService
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
            let processedAudio = try await fileUploadService.processFileUpload(url)
            
            // Success
            hasProcessedFile = true
            processedFileName = currentFileName
            statusMessage = "Processing complete!"
            
            // Store processed audio result for next step
            // TODO: Pass to next stage of pipeline
            
        } catch {
            setError("Processing failed: \(error.localizedDescription)")
        }
        
        isProcessing = false
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
        
        // Clean up any temporary files
        fileUploadService.cleanupAllTemporaryFiles()
    }
    
    private func updateStatusMessage(for progress: Double) {
        switch progress {
        case 0.0..<0.2:
            statusMessage = "Validating file..."
        case 0.2..<0.4:
            statusMessage = "Preparing file..."
        case 0.4..<0.6:
            statusMessage = "Processing audio..."
        case 0.6..<0.9:
            statusMessage = "Normalizing format..."
        case 0.9..<1.0:
            statusMessage = "Finalizing..."
        default:
            statusMessage = "Processing complete!"
        }
    }
}
