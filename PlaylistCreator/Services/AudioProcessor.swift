import Foundation
import AVFoundation

protocol AudioProcessor {
    func processFileUpload(_ url: URL) async throws -> ProcessedAudio
    func processURL(_ url: URL) async throws -> ProcessedAudio
    func extractAudioFromVideo(_ videoURL: URL) async throws -> URL
    func normalizeAudioFormat(_ audioURL: URL) async throws -> URL
}

struct ProcessedAudio: Equatable {
    let url: URL
    let duration: TimeInterval
    let format: AudioFormat
    let sampleRate: Double
    
    init(url: URL, duration: TimeInterval, format: AudioFormat = .wav, sampleRate: Double = 16000) {
        self.url = url
        self.duration = duration
        self.format = format
        self.sampleRate = sampleRate
    }
}

enum AudioFormat: String, CaseIterable {
    case wav = "wav"
    case mp3 = "mp3"
    case m4a = "m4a"
    case aac = "aac"
}

class DefaultAudioProcessor: AudioProcessor {
    func processFileUpload(_ url: URL) async throws -> ProcessedAudio {
        let audioURL = try await extractAudioIfNeeded(from: url)
        let normalizedURL = try await normalizeAudioFormat(audioURL)
        let duration = try await getAudioDuration(normalizedURL)
        
        return ProcessedAudio(
            url: normalizedURL,
            duration: duration,
            format: .wav,
            sampleRate: 16000
        )
    }
    
    func processURL(_ url: URL) async throws -> ProcessedAudio {
        throw AudioProcessingError.notImplemented
    }
    
    func extractAudioFromVideo(_ videoURL: URL) async throws -> URL {
        throw AudioProcessingError.notImplemented
    }
    
    func normalizeAudioFormat(_ audioURL: URL) async throws -> URL {
        throw AudioProcessingError.notImplemented
    }
    
    private func extractAudioIfNeeded(from url: URL) async throws -> URL {
        let fileExtension = url.pathExtension.lowercased()
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm"]
        
        if videoExtensions.contains(fileExtension) {
            return try await extractAudioFromVideo(url)
        }
        
        return url
    }
    
    private func getAudioDuration(_ url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        return try await asset.load(.duration).seconds
    }
}
