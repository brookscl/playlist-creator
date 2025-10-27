import Foundation

enum URLType: Equatable {
    case youtube
    case podcast
    case directAudio
    case directVideo
    case unsupported
}

class URLValidator {

    // MARK: - Properties

    private let audioExtensions = Set(["mp3", "wav", "m4a", "aac", "flac", "ogg"])
    private let videoExtensions = Set(["mp4", "mov", "avi", "mkv", "webm", "m4v"])
    private let podcastExtensions = Set(["rss", "xml"])

    // MARK: - Public Methods

    func validateURL(_ url: URL) -> URLType {
        let urlString = url.absoluteString.lowercased()
        let host = url.host?.lowercased() ?? ""
        let pathExtension = url.pathExtension.lowercased()

        // Check for YouTube URLs
        if isYouTubeURL(host: host, urlString: urlString) {
            return .youtube
        }

        // Check for podcast/RSS feeds
        if podcastExtensions.contains(pathExtension) {
            return .podcast
        }

        // Check for direct audio URLs
        if audioExtensions.contains(pathExtension) {
            return .directAudio
        }

        // Check for direct video URLs
        if videoExtensions.contains(pathExtension) {
            return .directVideo
        }

        return .unsupported
    }

    func isValidURLString(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return false
        }

        // Try to create a URL
        let normalizedString = normalizeURLString(trimmed)
        guard let _ = URL(string: normalizedString) else {
            return false
        }

        return true
    }

    func normalizeURLString(_ string: String) -> String {
        var normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add https:// if no protocol is specified
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "https://" + normalized
        }

        return normalized
    }

    func extractYouTubeVideoID(from url: URL) -> String? {
        let urlString = url.absoluteString
        let host = url.host?.lowercased() ?? ""

        // Check if it's a YouTube URL
        guard isYouTubeURL(host: host, urlString: urlString) else {
            return nil
        }

        // Handle youtu.be format
        if host.contains("youtu.be") {
            let path = url.path
            let videoID = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return videoID.isEmpty ? nil : videoID
        }

        // Handle youtube.com format (extract v parameter)
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                if item.name == "v", let value = item.value, !value.isEmpty {
                    return value
                }
            }
        }

        return nil
    }

    // MARK: - Private Helpers

    private func isYouTubeURL(host: String, urlString: String) -> Bool {
        return host.contains("youtube.com") ||
               host.contains("youtu.be") ||
               host.contains("m.youtube.com") ||
               urlString.contains("youtube.com") ||
               urlString.contains("youtu.be")
    }
}
