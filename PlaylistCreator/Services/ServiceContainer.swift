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
        register(AudioProcessor.self) { DefaultAudioProcessor() }
        register(Transcriber.self) { DefaultTranscriber() }
        register(MusicExtractor.self) { DefaultMusicExtractor() }
        register(MusicSearcher.self) { DefaultMusicSearcher() }
        register(PlaylistCreator.self) { DefaultPlaylistCreator() }
    }
}

let serviceContainer = DefaultServiceContainer()
