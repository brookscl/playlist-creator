import XCTest
@testable import PlaylistCreator

final class SettingsManagerTests: XCTestCase {
    var settingsManager: SettingsManager!
    let testSuiteName = "com.playlistcreator.settings.tests"

    override func setUp() {
        super.setUp()
        // Use a test-specific UserDefaults suite
        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        let keychainManager = KeychainManager(service: "com.playlistcreator.tests", account: "test-api-key")
        settingsManager = SettingsManager(userDefaults: userDefaults, keychainManager: keychainManager)

        // Clean up any existing data
        settingsManager.clearAll()
    }

    override func tearDown() {
        settingsManager.clearAll()
        UserDefaults.standard.removeSuite(named: testSuiteName)
        settingsManager = nil
        super.tearDown()
    }

    // MARK: - API Key Tests

    func testSaveAndGetAPIKey() throws {
        let apiKey = "sk-test1234567890"

        try settingsManager.saveAPIKey(apiKey)
        let retrieved = try settingsManager.getAPIKey()

        XCTAssertEqual(retrieved, apiKey)
    }

    func testGetAPIKeyWhenNotSet() throws {
        XCTAssertNil(try? settingsManager.getAPIKey())
    }

    func testHasAPIKeyWhenSet() throws {
        XCTAssertFalse(settingsManager.hasAPIKey())

        try settingsManager.saveAPIKey("sk-test")

        XCTAssertTrue(settingsManager.hasAPIKey())
    }

    func testHasAPIKeyWhenNotSet() {
        XCTAssertFalse(settingsManager.hasAPIKey())
    }

    func testClearAPIKey() throws {
        try settingsManager.saveAPIKey("sk-test")
        XCTAssertTrue(settingsManager.hasAPIKey())

        try settingsManager.clearAPIKey()

        XCTAssertFalse(settingsManager.hasAPIKey())
        XCTAssertNil(try? settingsManager.getAPIKey())
    }

    // MARK: - Model Selection Tests

    func testDefaultModel() {
        XCTAssertEqual(settingsManager.openAIModel, "gpt-4")
    }

    func testSetModel() {
        settingsManager.openAIModel = "gpt-3.5-turbo"
        XCTAssertEqual(settingsManager.openAIModel, "gpt-3.5-turbo")
    }

    func testModelPersistence() {
        settingsManager.openAIModel = "gpt-4-turbo"

        // Create new instance with same UserDefaults
        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        let keychainManager = KeychainManager(service: "com.playlistcreator.tests", account: "test-api-key")
        let newManager = SettingsManager(userDefaults: userDefaults, keychainManager: keychainManager)

        XCTAssertEqual(newManager.openAIModel, "gpt-4-turbo")
    }

    // MARK: - Temperature Tests

    func testDefaultTemperature() {
        XCTAssertEqual(settingsManager.openAITemperature, 0.7, accuracy: 0.001)
    }

    func testSetTemperature() {
        settingsManager.openAITemperature = 0.5
        XCTAssertEqual(settingsManager.openAITemperature, 0.5, accuracy: 0.001)
    }

    func testTemperaturePersistence() {
        settingsManager.openAITemperature = 0.9

        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        let keychainManager = KeychainManager(service: "com.playlistcreator.tests", account: "test-api-key")
        let newManager = SettingsManager(userDefaults: userDefaults, keychainManager: keychainManager)

        XCTAssertEqual(newManager.openAITemperature, 0.9, accuracy: 0.001)
    }

    // MARK: - Max Tokens Tests

    func testDefaultMaxTokens() {
        XCTAssertEqual(settingsManager.openAIMaxTokens, 1500)
    }

    func testSetMaxTokens() {
        settingsManager.openAIMaxTokens = 2000
        XCTAssertEqual(settingsManager.openAIMaxTokens, 2000)
    }

    func testMaxTokensPersistence() {
        settingsManager.openAIMaxTokens = 3000

        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        let keychainManager = KeychainManager(service: "com.playlistcreator.tests", account: "test-api-key")
        let newManager = SettingsManager(userDefaults: userDefaults, keychainManager: keychainManager)

        XCTAssertEqual(newManager.openAIMaxTokens, 3000)
    }

    // MARK: - Clear All Tests

    func testClearAll() throws {
        // Set some values
        try settingsManager.saveAPIKey("sk-test")
        settingsManager.openAIModel = "gpt-3.5-turbo"
        settingsManager.openAITemperature = 0.5
        settingsManager.openAIMaxTokens = 2000

        // Clear everything
        settingsManager.clearAll()

        // Verify all cleared/reset to defaults
        XCTAssertFalse(settingsManager.hasAPIKey())
        XCTAssertEqual(settingsManager.openAIModel, "gpt-4")
        XCTAssertEqual(settingsManager.openAITemperature, 0.7, accuracy: 0.001)
        XCTAssertEqual(settingsManager.openAIMaxTokens, 1500)
    }

    // MARK: - Validation Tests

    func testIsConfiguredWhenAPIKeySet() throws {
        XCTAssertFalse(settingsManager.isConfigured())

        try settingsManager.saveAPIKey("sk-test")

        XCTAssertTrue(settingsManager.isConfigured())
    }

    func testIsConfiguredWhenAPIKeyNotSet() {
        XCTAssertFalse(settingsManager.isConfigured())
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let shared1 = SettingsManager.shared
        let shared2 = SettingsManager.shared

        XCTAssertTrue(shared1 === shared2)
    }
}
