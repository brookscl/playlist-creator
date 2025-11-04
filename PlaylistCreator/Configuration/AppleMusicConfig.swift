import Foundation
import MusicKit

/// Configuration for Apple Music API credentials
///
/// This handles loading developer credentials from:
/// 1. Environment variables (recommended for development)
/// 2. Configuration file (for production deployment)
/// 3. Keychain (for secure storage)
struct AppleMusicConfig {
    let teamID: String
    let keyID: String
    let privateKeyPEM: String

    // MARK: - Environment Variable Keys

    private static let teamIDKey = "APPLE_MUSIC_TEAM_ID"
    private static let keyIDKey = "APPLE_MUSIC_KEY_ID"
    private static let privateKeyKey = "APPLE_MUSIC_PRIVATE_KEY"
    private static let privateKeyFileKey = "APPLE_MUSIC_PRIVATE_KEY_FILE"

    // MARK: - Initialization

    /// Load configuration from environment variables
    ///
    /// Environment variables:
    /// - APPLE_MUSIC_TEAM_ID: Your Apple Developer Team ID (10 characters)
    /// - APPLE_MUSIC_KEY_ID: Your MusicKit Key ID (10 characters)
    /// - APPLE_MUSIC_PRIVATE_KEY: PEM-encoded private key (base64 or multiline)
    /// - APPLE_MUSIC_PRIVATE_KEY_FILE: Path to PEM file (alternative to PRIVATE_KEY)
    static func loadFromEnvironment() throws -> AppleMusicConfig {
        guard let teamID = ProcessInfo.processInfo.environment[teamIDKey] else {
            throw ConfigurationError.missingEnvironmentVariable(teamIDKey)
        }

        guard let keyID = ProcessInfo.processInfo.environment[keyIDKey] else {
            throw ConfigurationError.missingEnvironmentVariable(keyIDKey)
        }

        // Try to load private key from environment variable first
        var privateKeyPEM: String?

        if let keyFromEnv = ProcessInfo.processInfo.environment[privateKeyKey] {
            // Handle both base64-encoded and direct PEM format
            if keyFromEnv.contains("BEGIN PRIVATE KEY") {
                privateKeyPEM = keyFromEnv
            } else {
                // Try to decode as base64
                if let decoded = Data(base64Encoded: keyFromEnv),
                   let decodedString = String(data: decoded, encoding: .utf8) {
                    privateKeyPEM = decodedString
                } else {
                    privateKeyPEM = keyFromEnv // Use as-is
                }
            }
        }

        // If not in environment variable, try to load from file
        if privateKeyPEM == nil,
           let keyFilePath = ProcessInfo.processInfo.environment[privateKeyFileKey] {
            privateKeyPEM = try loadPrivateKeyFromFile(path: keyFilePath)
        }

        guard let privateKey = privateKeyPEM else {
            throw ConfigurationError.missingPrivateKey
        }

        return AppleMusicConfig(
            teamID: teamID,
            keyID: keyID,
            privateKeyPEM: privateKey
        )
    }

    /// Load configuration from a plist file
    static func loadFromFile(path: String) throws -> AppleMusicConfig {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)

        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: String] else {
            throw ConfigurationError.invalidConfigurationFile
        }

        guard let teamID = plist["TeamID"] else {
            throw ConfigurationError.missingConfigurationValue("TeamID")
        }

        guard let keyID = plist["KeyID"] else {
            throw ConfigurationError.missingConfigurationValue("KeyID")
        }

        guard let privateKeyFile = plist["PrivateKeyFile"] else {
            throw ConfigurationError.missingConfigurationValue("PrivateKeyFile")
        }

        // Resolve relative path if needed
        let keyFileURL = URL(fileURLWithPath: privateKeyFile, relativeTo: url.deletingLastPathComponent())
        let privateKeyPEM = try loadPrivateKeyFromFile(path: keyFileURL.path)

        return AppleMusicConfig(
            teamID: teamID,
            keyID: keyID,
            privateKeyPEM: privateKeyPEM
        )
    }

    // MARK: - Private Helpers

    private static func loadPrivateKeyFromFile(path: String) throws -> String {
        do {
            let keyContent = try String(contentsOfFile: path, encoding: .utf8)

            // Validate it looks like a PEM file
            guard keyContent.contains("BEGIN PRIVATE KEY") else {
                throw ConfigurationError.invalidPrivateKeyFormat
            }

            return keyContent
        } catch {
            throw ConfigurationError.privateKeyFileNotFound(path)
        }
    }

    // MARK: - Validation

    func validate() throws {
        guard teamID.count == 10 else {
            throw ConfigurationError.invalidTeamID(teamID)
        }

        guard keyID.count == 10 else {
            throw ConfigurationError.invalidKeyID(keyID)
        }

        guard privateKeyPEM.contains("BEGIN PRIVATE KEY") else {
            throw ConfigurationError.invalidPrivateKeyFormat
        }
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: Error, LocalizedError {
    case missingEnvironmentVariable(String)
    case missingPrivateKey
    case invalidConfigurationFile
    case missingConfigurationValue(String)
    case privateKeyFileNotFound(String)
    case invalidPrivateKeyFormat
    case invalidTeamID(String)
    case invalidKeyID(String)

    var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let key):
            return "Missing required environment variable: \(key)"
        case .missingPrivateKey:
            return "Private key not found. Set APPLE_MUSIC_PRIVATE_KEY or APPLE_MUSIC_PRIVATE_KEY_FILE environment variable"
        case .invalidConfigurationFile:
            return "Invalid configuration file format. Expected plist with TeamID, KeyID, and PrivateKeyFile"
        case .missingConfigurationValue(let key):
            return "Missing required configuration value: \(key)"
        case .privateKeyFileNotFound(let path):
            return "Private key file not found at path: \(path)"
        case .invalidPrivateKeyFormat:
            return "Invalid private key format. Expected PEM format with 'BEGIN PRIVATE KEY' header"
        case .invalidTeamID(let teamID):
            return "Invalid Team ID '\(teamID)'. Must be exactly 10 characters"
        case .invalidKeyID(let keyID):
            return "Invalid Key ID '\(keyID)'. Must be exactly 10 characters"
        }
    }
}

// MARK: - Configuration Builder

@available(macOS 12.0, *)
extension AppleMusicConfig {
    /// Build a complete AppleMusicAPIClient with this configuration
    func buildAPIClient() throws -> AppleMusicAPIClient {
        // Validate configuration first
        try validate()

        // Create token generator
        let tokenGenerator = try JWTTokenGenerator(
            teamID: teamID,
            keyID: keyID,
            privateKeyPEM: privateKeyPEM
        )

        // Create a wrapper that will be initialized properly
        let wrapper = SimpleMusicKitWrapper()

        // Create HTTP client
        let httpClient = URLSessionHTTPClient()

        // Create API client
        let apiClient = AppleMusicAPIClient(
            httpClient: httpClient,
            developerTokenGenerator: tokenGenerator,
            musicKitWrapper: wrapper
        )

        return apiClient
    }
}

// MARK: - Simple MusicKit Wrapper for API Client

@available(macOS 12.0, *)
class SimpleMusicKitWrapper: MusicKitWrapperProtocol {
    var currentAuthorizationStatus: MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }

    var userToken: String? {
        // This will need to be retrieved after authorization
        // For now, return nil - will be populated after requestAuthorization
        return nil
    }

    func requestAuthorization() async throws -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }

    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws -> (id: String, url: URL?) {
        // Not used - API client handles this
        fatalError("Not implemented - use AppleMusicAPIClient directly")
    }

    func addSongs(to playlistID: String, songIDs: [String]) async throws {
        // Not used - API client handles this
        fatalError("Not implemented - use AppleMusicAPIClient directly")
    }

    func deletePlaylist(_ playlistID: String) async throws {
        // Not used - API client handles this
        fatalError("Not implemented - use AppleMusicAPIClient directly")
    }
}
