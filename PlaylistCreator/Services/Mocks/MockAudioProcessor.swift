import Foundation

class MockAudioProcessor: AudioProcessor {
    var shouldThrowError = false
    var processFileUploadResult: ProcessedAudio?
    var processURLResult: ProcessedAudio?
    var extractAudioResult: URL?
    var normalizeAudioResult: URL?
    
    func processFileUpload(_ url: URL) async throws -> ProcessedAudio {
        if shouldThrowError {
            throw AudioProcessingError.fileNotFound(url.path)
        }
        return processFileUploadResult ?? ProcessedAudio(
            url: url,
            duration: 180.0,
            format: .wav,
            sampleRate: 16000
        )
    }
    
    func processURL(_ url: URL) async throws -> ProcessedAudio {
        if shouldThrowError {
            throw AudioProcessingError.extractionFailed("Mock error")
        }
        return processURLResult ?? ProcessedAudio(
            url: url,
            duration: 240.0,
            format: .wav,
            sampleRate: 16000
        )
    }
    
    func extractAudioFromVideo(_ videoURL: URL) async throws -> URL {
        if shouldThrowError {
            throw AudioProcessingError.extractionFailed("Mock error")
        }
        return extractAudioResult ?? URL(fileURLWithPath: "/tmp/extracted_audio.wav")
    }
    
    func normalizeAudioFormat(_ audioURL: URL) async throws -> URL {
        if shouldThrowError {
            throw AudioProcessingError.normalizationFailed("Mock error")
        }
        return normalizeAudioResult ?? URL(fileURLWithPath: "/tmp/normalized_audio.wav")
    }
}
