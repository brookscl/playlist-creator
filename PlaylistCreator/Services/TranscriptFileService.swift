import Foundation

enum TranscriptFileFormat {
    case plainText
    case json
    case srt
    case vtt
    case unsupported
}

enum TranscriptFileError: Error, LocalizedError {
    case fileNotFound
    case unsupportedFormat(String)
    case emptyFile
    case invalidFormat(String)
    case downloadFailed(String)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Transcript file not found"
        case .unsupportedFormat(let format):
            return "Unsupported file format: .\(format). Supported formats: .txt, .json, .srt, .vtt"
        case .emptyFile:
            return "Transcript file is empty"
        case .invalidFormat(let details):
            return "Invalid file format: \(details)"
        case .downloadFailed(let reason):
            return "Failed to download transcript: \(reason)"
        case .permissionDenied:
            return "Permission denied to access file"
        }
    }
}

class TranscriptFileService {

    // MARK: - Properties

    private let supportedFormats = Set(["txt", "json", "srt", "vtt"])
    private let urlDownloader: URLDownloader

    var progressCallback: ((Double) -> Void)?

    // MARK: - Initialization

    init(urlDownloader: URLDownloader = URLDownloader()) {
        self.urlDownloader = urlDownloader
    }

    // MARK: - Public Methods

    func loadTranscript(from url: URL) async throws -> Transcript {
        // Start accessing security-scoped resource (needed for iOS file picker)
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptFileError.fileNotFound
        }

        // Detect format
        let format = detectFormat(from: url)
        guard format != .unsupported else {
            throw TranscriptFileError.unsupportedFormat(url.pathExtension)
        }

        // Read file content
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw TranscriptFileError.invalidFormat("Unable to read file as UTF-8 text")
        }

        // Check not empty
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw TranscriptFileError.emptyFile
        }

        // Parse based on format
        switch format {
        case .plainText:
            return parsePlainText(trimmedContent)
        case .json:
            return try parseJSON(trimmedContent)
        case .srt:
            return try parseSRT(trimmedContent)
        case .vtt:
            return try parseVTT(trimmedContent)
        case .unsupported:
            throw TranscriptFileError.unsupportedFormat(url.pathExtension)
        }
    }

    func loadTranscript(from urlString: String) async throws -> Transcript {
        guard isValidTranscriptURL(urlString) else {
            throw TranscriptFileError.invalidFormat("Invalid URL")
        }

        guard let url = URL(string: urlString) else {
            throw TranscriptFileError.invalidFormat("Invalid URL format")
        }

        // Download to temporary file
        urlDownloader.progressCallback = { [weak self] progress in
            self?.progressCallback?(progress)
        }

        let localURL: URL
        do {
            localURL = try await urlDownloader.download(from: url)
        } catch {
            throw TranscriptFileError.downloadFailed(error.localizedDescription)
        }

        // Load from downloaded file
        defer {
            try? FileManager.default.removeItem(at: localURL)
        }

        return try await loadTranscript(from: localURL)
    }

    func detectFormat(from url: URL) -> TranscriptFileFormat {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "txt":
            return .plainText
        case "json":
            return .json
        case "srt":
            return .srt
        case "vtt":
            return .vtt
        default:
            return .unsupported
        }
    }

    func isValidTranscriptURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme) else {
            return false
        }

        let ext = url.pathExtension.lowercased()
        return supportedFormats.contains(ext)
    }

    // MARK: - Private Parsing Methods

    private func parsePlainText(_ content: String) -> Transcript {
        return Transcript(
            text: content,
            segments: [],
            language: nil,
            confidence: 1.0
        )
    }

    private func parseJSON(_ content: String) throws -> Transcript {
        guard let data = content.data(using: .utf8) else {
            throw TranscriptFileError.invalidFormat("Unable to convert JSON to data")
        }

        let decoder = JSONDecoder()

        // Try to decode as full Transcript structure
        do {
            struct JSONTranscript: Codable {
                let text: String
                let segments: [JSONSegment]?
                let language: String?
                let confidence: Double?

                struct JSONSegment: Codable {
                    let text: String
                    let startTime: TimeInterval
                    let endTime: TimeInterval
                    let confidence: Double?
                }
            }

            let jsonTranscript = try decoder.decode(JSONTranscript.self, from: data)

            let segments = jsonTranscript.segments?.map { seg in
                TranscriptSegment(
                    text: seg.text,
                    startTime: seg.startTime,
                    endTime: seg.endTime,
                    confidence: seg.confidence ?? 1.0
                )
            } ?? []

            return Transcript(
                text: jsonTranscript.text,
                segments: segments,
                language: jsonTranscript.language,
                confidence: jsonTranscript.confidence ?? 1.0
            )
        } catch {
            throw TranscriptFileError.invalidFormat("Invalid JSON structure: \(error.localizedDescription)")
        }
    }

    private func parseSRT(_ content: String) throws -> Transcript {
        let lines = content.components(separatedBy: .newlines)
        var segments: [TranscriptSegment] = []
        var fullText: [String] = []

        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            if line.isEmpty {
                i += 1
                continue
            }

            // Check if this is a subtitle number (should be a number)
            if Int(line) != nil {
                // Next line should be timestamp
                i += 1
                if i >= lines.count {
                    break
                }

                let timestampLine = lines[i]
                guard let (startTime, endTime) = parseSRTTimestamp(timestampLine) else {
                    throw TranscriptFileError.invalidFormat("Invalid SRT timestamp: \(timestampLine)")
                }

                // Collect subtitle text (may be multiple lines)
                var subtitleLines: [String] = []
                i += 1
                while i < lines.count {
                    let textLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if textLine.isEmpty {
                        break
                    }
                    subtitleLines.append(textLine)
                    i += 1
                }

                let text = subtitleLines.joined(separator: " ")
                if !text.isEmpty {
                    segments.append(TranscriptSegment(
                        text: text,
                        startTime: startTime,
                        endTime: endTime,
                        confidence: 1.0
                    ))
                    fullText.append(text)
                }
            } else {
                i += 1
            }
        }

        guard !segments.isEmpty else {
            throw TranscriptFileError.invalidFormat("No valid SRT subtitles found")
        }

        return Transcript(
            text: fullText.joined(separator: " "),
            segments: segments,
            language: nil,
            confidence: 1.0
        )
    }

    private func parseVTT(_ content: String) throws -> Transcript {
        let lines = content.components(separatedBy: .newlines)

        // Check for WEBVTT header
        guard let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
              firstLine.hasPrefix("WEBVTT") else {
            throw TranscriptFileError.invalidFormat("Missing WEBVTT header")
        }

        var segments: [TranscriptSegment] = []
        var fullText: [String] = []

        var i = 1 // Skip header
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // Skip empty lines and NOTE comments
            if line.isEmpty || line.hasPrefix("NOTE") {
                i += 1
                continue
            }

            // Check if this is a timestamp line or cue identifier
            if line.contains("-->") {
                // This is a timestamp line
                guard let (startTime, endTime) = parseVTTTimestamp(line) else {
                    throw TranscriptFileError.invalidFormat("Invalid VTT timestamp: \(line)")
                }

                // Collect caption text (may be multiple lines)
                var captionLines: [String] = []
                i += 1
                while i < lines.count {
                    let textLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if textLine.isEmpty || textLine.hasPrefix("NOTE") {
                        break
                    }
                    if !textLine.contains("-->") {
                        captionLines.append(textLine)
                    } else {
                        // Hit next timestamp, don't advance i
                        i -= 1
                        break
                    }
                    i += 1
                }

                let text = captionLines.joined(separator: " ")
                if !text.isEmpty {
                    segments.append(TranscriptSegment(
                        text: text,
                        startTime: startTime,
                        endTime: endTime,
                        confidence: 1.0
                    ))
                    fullText.append(text)
                }
            } else {
                // Might be a cue identifier, check next line for timestamp
                i += 1
                if i < lines.count {
                    let nextLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if nextLine.contains("-->") {
                        // Previous line was cue identifier, current line is timestamp
                        guard let (startTime, endTime) = parseVTTTimestamp(nextLine) else {
                            throw TranscriptFileError.invalidFormat("Invalid VTT timestamp: \(nextLine)")
                        }

                        // Collect caption text
                        var captionLines: [String] = []
                        i += 1
                        while i < lines.count {
                            let textLine = lines[i].trimmingCharacters(in: .whitespaces)
                            if textLine.isEmpty || textLine.hasPrefix("NOTE") {
                                break
                            }
                            if !textLine.contains("-->") {
                                captionLines.append(textLine)
                            } else {
                                i -= 1
                                break
                            }
                            i += 1
                        }

                        let text = captionLines.joined(separator: " ")
                        if !text.isEmpty {
                            segments.append(TranscriptSegment(
                                text: text,
                                startTime: startTime,
                                endTime: endTime,
                                confidence: 1.0
                            ))
                            fullText.append(text)
                        }
                    } else {
                        continue
                    }
                }
            }

            i += 1
        }

        guard !segments.isEmpty else {
            throw TranscriptFileError.invalidFormat("No valid VTT captions found")
        }

        return Transcript(
            text: fullText.joined(separator: " "),
            segments: segments,
            language: nil,
            confidence: 1.0
        )
    }

    // MARK: - Timestamp Parsing Helpers

    private func parseSRTTimestamp(_ line: String) -> (TimeInterval, TimeInterval)? {
        // Format: 00:00:00,000 --> 00:00:05,000
        let components = line.components(separatedBy: " --> ")
        guard components.count == 2 else {
            return nil
        }

        guard let startTime = parseSRTTime(components[0]),
              let endTime = parseSRTTime(components[1]) else {
            return nil
        }

        return (startTime, endTime)
    }

    private func parseSRTTime(_ timeString: String) -> TimeInterval? {
        // Format: 00:00:00,000 (hours:minutes:seconds,milliseconds)
        let cleaned = timeString.trimmingCharacters(in: .whitespaces)
        let parts = cleaned.components(separatedBy: ",")
        guard parts.count == 2 else {
            return nil
        }

        let timeParts = parts[0].components(separatedBy: ":")
        guard timeParts.count == 3,
              let hours = Double(timeParts[0]),
              let minutes = Double(timeParts[1]),
              let seconds = Double(timeParts[2]),
              let milliseconds = Double(parts[1]) else {
            return nil
        }

        return hours * 3600 + minutes * 60 + seconds + milliseconds / 1000
    }

    private func parseVTTTimestamp(_ line: String) -> (TimeInterval, TimeInterval)? {
        // Format: 00:00:00.000 --> 00:00:05.000
        let components = line.components(separatedBy: " --> ")
        guard components.count >= 2 else {
            return nil
        }

        guard let startTime = parseVTTTime(components[0]),
              let endTime = parseVTTTime(components[1]) else {
            return nil
        }

        return (startTime, endTime)
    }

    private func parseVTTTime(_ timeString: String) -> TimeInterval? {
        // Format: 00:00:00.000 or 00:00.000
        let cleaned = timeString.trimmingCharacters(in: .whitespaces)
        let parts = cleaned.components(separatedBy: ".")

        guard parts.count == 2,
              let milliseconds = Double(parts[1]) else {
            return nil
        }

        let timeParts = parts[0].components(separatedBy: ":")

        let time: TimeInterval
        if timeParts.count == 3 {
            // HH:MM:SS format
            guard let hours = Double(timeParts[0]),
                  let minutes = Double(timeParts[1]),
                  let seconds = Double(timeParts[2]) else {
                return nil
            }
            time = hours * 3600 + minutes * 60 + seconds
        } else if timeParts.count == 2 {
            // MM:SS format
            guard let minutes = Double(timeParts[0]),
                  let seconds = Double(timeParts[1]) else {
                return nil
            }
            time = minutes * 60 + seconds
        } else {
            return nil
        }

        return time + milliseconds / 1000
    }
}
