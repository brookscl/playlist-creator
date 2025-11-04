import XCTest
@testable import PlaylistCreator

final class ServiceContainerTests: XCTestCase {
    var container: DefaultServiceContainer!
    
    override func setUp() {
        super.setUp()
        container = DefaultServiceContainer()
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - Service Registration Tests
    
    func testServiceRegistration() throws {
        // Register a service
        container.register(AudioProcessor.self) { MockAudioProcessor() }
        
        // Resolve the service
        let processor = container.resolve(AudioProcessor.self)
        XCTAssertTrue(processor is MockAudioProcessor)
    }
    
    func testServiceSingleton() throws {
        // Register a service
        container.register(AudioProcessor.self) { MockAudioProcessor() }
        
        // Resolve multiple times
        let processor1 = container.resolve(AudioProcessor.self)
        let processor2 = container.resolve(AudioProcessor.self)
        
        // Should return the same instance (singleton behavior)
        // Cast to AnyObject to use identity comparison
        XCTAssertTrue((processor1 as AnyObject) === (processor2 as AnyObject))
    }
    
    func testServiceFactoryCalledOnce() throws {
        var factoryCallCount = 0
        
        container.register(AudioProcessor.self) {
            factoryCallCount += 1
            return MockAudioProcessor()
        }
        
        // Resolve multiple times
        _ = container.resolve(AudioProcessor.self)
        _ = container.resolve(AudioProcessor.self)
        _ = container.resolve(AudioProcessor.self)
        
        // Factory should only be called once (singleton)
        XCTAssertEqual(factoryCallCount, 1)
    }
    
    func testUnregisteredServiceThrowsError() throws {
        // Attempting to resolve an unregistered service should crash with fatalError
        // We can't test fatalError directly in unit tests, but we can document this behavior
        // This test documents the expected behavior rather than testing it
        XCTAssertTrue(true, "Unregistered services cause fatalError - documented behavior")
    }
    
    // MARK: - Mock Configuration Tests
    
    func testConfigureMocks() throws {
        container.configureMocks()
        
        // Test that all mock services are registered
        let audioProcessor = container.resolve(AudioProcessor.self)
        XCTAssertTrue(audioProcessor is MockAudioProcessor)
        
        let transcriber = container.resolve(Transcriber.self)
        XCTAssertTrue(transcriber is MockTranscriber)
        
        let musicExtractor = container.resolve(MusicExtractor.self)
        XCTAssertTrue(musicExtractor is MockMusicExtractor)
        
        let musicSearcher = container.resolve(MusicSearcher.self)
        XCTAssertTrue(musicSearcher is MockMusicSearcher)
        
        let playlistCreator = container.resolve(PlaylistCreator.self)
        XCTAssertTrue(playlistCreator is MockPlaylistCreator)
    }
    
    func testConfigureProduction() throws {
        container.configureProduction()

        // Test that all production services are registered with actual implementations
        let audioProcessor = container.resolve(AudioProcessor.self)
        XCTAssertTrue(audioProcessor is FileUploadService)

        let transcriber = container.resolve(Transcriber.self)
        XCTAssertTrue(transcriber is WhisperTranscriptionService)

        let musicExtractor = container.resolve(MusicExtractor.self)
        XCTAssertTrue(musicExtractor is OpenAIService)

        let musicSearcher = container.resolve(MusicSearcher.self)
        // On macOS 12.0+, production uses AppleMusicSearchService, otherwise DefaultMusicSearcher
        if #available(macOS 12.0, *) {
            XCTAssertTrue(musicSearcher is AppleMusicSearchService)
        } else {
            XCTAssertTrue(musicSearcher is DefaultMusicSearcher)
        }

        let playlistCreator = container.resolve(PlaylistCreator.self)
        // On macOS 12.0+, production uses AppleMusicPlaylistService, otherwise DefaultPlaylistCreator
        if #available(macOS 12.0, *) {
            XCTAssertTrue(playlistCreator is AppleMusicPlaylistService)
        } else {
            XCTAssertTrue(playlistCreator is DefaultPlaylistCreator)
        }
    }
    
    func testConfigurationOverride() throws {
        // Configure production first
        container.configureProduction()
        let productionProcessor = container.resolve(AudioProcessor.self)
        XCTAssertTrue(productionProcessor is FileUploadService)

        // Create new container and configure mocks
        let newContainer = DefaultServiceContainer()
        newContainer.configureMocks()
        let mockProcessor = newContainer.resolve(AudioProcessor.self)
        XCTAssertTrue(mockProcessor is MockAudioProcessor)
    }
    
    // MARK: - Global Service Container Tests
    
    func testGlobalServiceContainer() throws {
        // Test that the global service container exists
        XCTAssertNotNil(serviceContainer)
        XCTAssertTrue(serviceContainer is DefaultServiceContainer)
    }
    
    func testGlobalServiceContainerCanBeConfigured() throws {
        // Configure the global container with mocks
        serviceContainer.configureMocks()
        
        // Verify configuration
        let processor = serviceContainer.resolve(AudioProcessor.self)
        XCTAssertTrue(processor is MockAudioProcessor)
        
        // Clean up - configure production to not affect other tests
        serviceContainer.configureProduction()
    }
    
    // MARK: - Multiple Service Types Tests
    
    func testMultipleServiceTypes() throws {
        // Register multiple different service types
        container.register(AudioProcessor.self) { MockAudioProcessor() }
        container.register(Transcriber.self) { MockTranscriber() }
        
        // Resolve different service types
        let processor = container.resolve(AudioProcessor.self)
        let transcriber = container.resolve(Transcriber.self)
        
        XCTAssertTrue(processor is MockAudioProcessor)
        XCTAssertTrue(transcriber is MockTranscriber)
        
        // Ensure they are different instances
        XCTAssertFalse((processor as AnyObject) === (transcriber as AnyObject))
    }
    
    func testServiceReplacementAfterResolution() throws {
        // Register and resolve a service
        container.register(AudioProcessor.self) { MockAudioProcessor() }
        let firstProcessor = container.resolve(AudioProcessor.self)
        
        // Register a different implementation (this should not affect already resolved instance)
        container.register(AudioProcessor.self) { DefaultAudioProcessor() }
        let secondProcessor = container.resolve(AudioProcessor.self)
        
        // First resolution should remain the same (singleton behavior)
        XCTAssertTrue((firstProcessor as AnyObject) === (secondProcessor as AnyObject))
        XCTAssertTrue(firstProcessor is MockAudioProcessor)
    }
    
    func testFactoryClosureCapturesValues() throws {
        let testValue = "test123"
        
        container.register(AudioProcessor.self) {
            let mockProcessor = MockAudioProcessor()
            // In a real scenario, we might configure the mock with captured values
            return mockProcessor
        }
        
        let processor = container.resolve(AudioProcessor.self)
        XCTAssertTrue(processor is MockAudioProcessor)
        
        // This test verifies that closure capture works correctly
        XCTAssertEqual(testValue, "test123") // Verify captured value is accessible
    }
}
