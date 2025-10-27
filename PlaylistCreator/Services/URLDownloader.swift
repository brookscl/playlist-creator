import Foundation

class URLDownloader {

    // MARK: - Properties

    private let urlValidator = URLValidator()
    private let temporaryDirectory: URL
    var progressCallback: ((Double) -> Void)?
    var timeoutInterval: TimeInterval
    var isDownloading = false

    // MARK: - Initialization

    init(timeoutInterval: TimeInterval = 300.0) {
        self.timeoutInterval = timeoutInterval

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlaylistCreator")
            .appendingPathComponent("Downloads")
            .appendingPathComponent(UUID().uuidString)

        self.temporaryDirectory = tempDir

        try? FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    deinit {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    // MARK: - Public Methods

    func download(from url: URL) async throws -> URL {
        guard url.scheme == "http" || url.scheme == "https" else {
            throw AudioProcessingError.extractionFailed("Invalid URL")
        }

        isDownloading = true
        updateProgress(0.0)

        let fileName = url.lastPathComponent.isEmpty ? "downloaded_file" : url.lastPathComponent
        let destinationURL = temporaryDirectory.appendingPathComponent(fileName)

        do {
            let (tempFileURL, response) = try await downloadFile(from: url)

            updateProgress(0.9)

            // Move to permanent location
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)

            updateProgress(1.0)
            isDownloading = false

            return destinationURL
        } catch let error as AudioProcessingError {
            isDownloading = false
            throw error
        } catch {
            isDownloading = false
            throw AudioProcessingError.extractionFailed("Download failed: \(error.localizedDescription)")
        }
    }

    func detectFileType(from url: URL) -> URLType {
        return urlValidator.validateURL(url)
    }

    func cleanup(fileAt url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func updateProgress(_ progress: Double) {
        let clampedProgress = max(0.0, min(1.0, progress))
        progressCallback?(clampedProgress)
    }

    // MARK: - Private Methods

    private func downloadFile(from url: URL) async throws -> (URL, URLResponse) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = timeoutInterval

        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)

        do {
            let (tempURL, response) = try await session.download(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AudioProcessingError.extractionFailed("Invalid response from server")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw AudioProcessingError.extractionFailed("Server returned error: \(httpResponse.statusCode)")
            }

            return (tempURL, response)
        } catch let error as AudioProcessingError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw AudioProcessingError.extractionFailed("Download timed out")
            } else if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                throw AudioProcessingError.extractionFailed("No internet connection")
            } else if (error as NSError).domain == NSURLErrorDomain {
                throw AudioProcessingError.extractionFailed("Network error: \(error.localizedDescription)")
            } else {
                throw AudioProcessingError.extractionFailed("Download failed: \(error.localizedDescription)")
            }
        }
    }
}
