import Foundation

protocol ServiceContainer {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T
    func configureMocks()
    func configureProduction()
}

class DefaultServiceContainer: ServiceContainer {
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        if let service = services[key] as? T {
            return service
        }
        
        guard let factory = factories[key] else {
            fatalError("Service \(key) not registered")
        }
        
        let service = factory() as! T
        services[key] = service
        return service
    }

    private func loadAppleMusicCredentials() -> [String: String] {
        var credentials: [String: String] = [:]

        // Try to find .env file in common locations
        let possiblePaths = [
            // Development directory (when running from Xcode)
            FileManager.default.currentDirectoryPath + "/.env",
            // Project root
            (#file as NSString).deletingLastPathComponent + "/../../.env",
            // User home directory
            NSHomeDirectory() + "/Documents/files.chrisbrooks/Files/10-19 Life admin/14 💻 My online life/14.42 Software automation projects/playlist-maker/.env"
        ]

        for path in possiblePaths {
            if let contents = try? String(contentsOfFile: path, encoding: .utf8) {
                // Parse .env file
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    // Skip comments and empty lines
                    guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

                    // Parse KEY=VALUE
                    if let equalIndex = trimmed.firstIndex(of: "=") {
                        let key = String(trimmed[..<equalIndex])
                        let value = String(trimmed[trimmed.index(after: equalIndex)...])
                        credentials[key] = value
                    }
                }

                if !credentials.isEmpty {
                    break
                }
            }
        }

        return credentials
    }

    func configureMocks() {
        register(AudioProcessor.self) { MockAudioProcessor() }
        register(Transcriber.self) { MockTranscriber() }
        register(MusicExtractor.self) { MockMusicExtractor() }
        register(MusicSearcher.self) { MockMusicSearcher() }
        register(PlaylistCreator.self) { MockPlaylistCreator() }
    }
    
    func configureProduction() {
        register(AudioProcessor.self) { FileUploadService() }
        register(Transcriber.self) { WhisperTranscriptionService() }
        register(MusicExtractor.self) { OpenAIService(settingsManager: .shared) }
        if #available(iOS 17.0, *) {
            // Use iTunes Search API (no registration required)
            register(MusicSearcher.self) {
                AppleMusicSearchService(musicKitClient: ITunesMusicKitClient())
            }
            // To use real MusicKit catalog search (requires Apple Developer registration):
            // register(MusicSearcher.self) {
            //     AppleMusicSearchService(musicKitClient: RealMusicKitClient())
            // }

            // Use native MusicKit library APIs for playlist creation (iOS only)
            register(PlaylistCreator.self) {
                print("🎵 Configuring playlist creation...")
                print("   Using MusicKit library APIs (native iOS)")
                let wrapper = RealMusicKitWrapper()
                print("✅ Playlist service configured successfully")
                return AppleMusicPlaylistService(musicKitWrapper: wrapper)
            }
        } else {
            // Fallback for older iOS versions
            register(MusicSearcher.self) { DefaultMusicSearcher() }
            register(PlaylistCreator.self) { DefaultPlaylistCreator() }
        }
    }
}

let serviceContainer = DefaultServiceContainer()
