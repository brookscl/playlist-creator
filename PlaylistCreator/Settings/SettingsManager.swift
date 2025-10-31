import Foundation

class SettingsManager {
    // MARK: - Singleton

    static let shared = SettingsManager()

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let keychainManager: KeychainManager

    // UserDefaults keys
    private enum Keys {
        static let openAIModel = "openAIModel"
        static let openAITemperature = "openAITemperature"
        static let openAIMaxTokens = "openAIMaxTokens"
    }

    // Default values
    private enum Defaults {
        static let openAIModel = "gpt-4"
        static let openAITemperature = 0.7
        static let openAIMaxTokens = 1500
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard,
         keychainManager: KeychainManager = KeychainManager()) {
        self.userDefaults = userDefaults
        self.keychainManager = keychainManager
    }

    // MARK: - API Key Management

    func saveAPIKey(_ apiKey: String) throws {
        try keychainManager.saveItem(apiKey)
    }

    func getAPIKey() throws -> String {
        return try keychainManager.getItem()
    }

    func hasAPIKey() -> Bool {
        return (try? keychainManager.getItem()) != nil
    }

    func clearAPIKey() throws {
        try keychainManager.deleteItem()
    }

    // MARK: - OpenAI Model Settings

    var openAIModel: String {
        get {
            return userDefaults.string(forKey: Keys.openAIModel) ?? Defaults.openAIModel
        }
        set {
            userDefaults.set(newValue, forKey: Keys.openAIModel)
        }
    }

    var openAITemperature: Double {
        get {
            let value = userDefaults.double(forKey: Keys.openAITemperature)
            return value == 0 ? Defaults.openAITemperature : value
        }
        set {
            userDefaults.set(newValue, forKey: Keys.openAITemperature)
        }
    }

    var openAIMaxTokens: Int {
        get {
            let value = userDefaults.integer(forKey: Keys.openAIMaxTokens)
            return value == 0 ? Defaults.openAIMaxTokens : value
        }
        set {
            userDefaults.set(newValue, forKey: Keys.openAIMaxTokens)
        }
    }

    // MARK: - Configuration Status

    func isConfigured() -> Bool {
        return hasAPIKey()
    }

    // MARK: - Clear All Settings

    func clearAll() {
        try? clearAPIKey()
        userDefaults.removeObject(forKey: Keys.openAIModel)
        userDefaults.removeObject(forKey: Keys.openAITemperature)
        userDefaults.removeObject(forKey: Keys.openAIMaxTokens)
    }
}
