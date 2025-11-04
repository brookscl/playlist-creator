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
        if #available(macOS 12.0, *) {
            // Use iTunes Search API (no registration required)
            register(MusicSearcher.self) {
                AppleMusicSearchService(musicKitClient: ITunesMusicKitClient())
            }
            // To use real MusicKit (requires Apple Developer registration):
            // register(MusicSearcher.self) {
            //     AppleMusicSearchService(musicKitClient: RealMusicKitClient())
            // }

            // Use real MusicKit for playlist creation
            // Note: Requires developer credentials to be configured
            // For now, use mock until credentials are set up
            register(PlaylistCreator.self) { MockPlaylistCreator() }

            // To use real Apple Music API:
            // 1. Set up developer credentials (see docs/apple-music-api-setup.md)
            // 2. Uncomment and configure:
            // register(PlaylistCreator.self) {
            //     do {
            //         let config = try AppleMusicConfig.loadFromEnvironment()
            //         let apiClient = try config.buildAPIClient()
            //         let wrapper = RealMusicKitWrapper(apiClient: apiClient)
            //         return AppleMusicPlaylistService(musicKitWrapper: wrapper)
            //     } catch {
            //         print("⚠️ Failed to configure Apple Music API: \(error)")
            //         return MockPlaylistCreator()
            //     }
            // }
        } else {
            register(MusicSearcher.self) { DefaultMusicSearcher() }
            register(PlaylistCreator.self) { DefaultPlaylistCreator() }
        }
    }
}

let serviceContainer = DefaultServiceContainer()
