import Foundation
import MusicKit

// MARK: - HTTP Client Protocol

protocol HTTPClient {
    func request(
        url: URL,
        method: String,
        headers: [String: String]?,
        body: Data?
    ) async throws -> (Data, HTTPURLResponse)
}

// MARK: - Apple Music API Client

/// Client for interacting with Apple Music API
///
/// This client handles:
/// - Developer token generation and caching
/// - User token retrieval from MusicKit
/// - REST API calls to Apple Music API endpoints
/// - Playlist creation and management
@available(macOS 12.0, *)
class AppleMusicAPIClient {
    private let httpClient: HTTPClient
    private let developerTokenGenerator: DeveloperTokenGenerator
    private let musicKitWrapper: MusicKitWrapperProtocol

    // Token caching
    private var cachedDeveloperToken: String?
    private var developerTokenExpiresAt: Date?

    // Apple Music API base URL
    private let baseURL = "https://api.music.apple.com/v1"

    init(
        httpClient: HTTPClient,
        developerTokenGenerator: DeveloperTokenGenerator,
        musicKitWrapper: MusicKitWrapperProtocol
    ) {
        self.httpClient = httpClient
        self.developerTokenGenerator = developerTokenGenerator
        self.musicKitWrapper = musicKitWrapper
    }

    // MARK: - Token Management

    /// Get a valid developer token (cached or newly generated)
    func getDeveloperToken() async throws -> String {
        // Check if cached token is still valid
        if let cached = cachedDeveloperToken,
           let expiresAt = developerTokenExpiresAt,
           Date() < expiresAt.addingTimeInterval(-60) { // Refresh 1 minute before expiry
            return cached
        }

        // Generate new token
        let (token, expiresAt) = try developerTokenGenerator.generateToken()
        cachedDeveloperToken = token
        developerTokenExpiresAt = expiresAt

        return token
    }

    /// Get user token from MusicKit
    func getUserToken() async throws -> String {
        // Ensure user is authorized
        let status = musicKitWrapper.currentAuthorizationStatus

        guard status == .authorized else {
            throw AppleMusicAPIError.notAuthorized
        }

        // Request authorization if needed to ensure we have a valid token
        if status != .authorized {
            let authorized = try await musicKitWrapper.requestAuthorization()
            guard authorized else {
                throw AppleMusicAPIError.notAuthorized
            }
        }

        // On macOS, MusicKit manages the user token internally
        // We retrieve it from the MusicAuthorization directly
        // Note: This is a placeholder - actual implementation may need platform-specific handling
        // For now, we'll rely on MusicKit's internal token management

        // Generate a dummy token for testing - in production this would come from MusicKit
        // The actual token retrieval mechanism depends on MusicKit's internal implementation
        return "music-user-token-placeholder"
    }

    /// Clear cached tokens (for testing or logout)
    func clearTokenCache() {
        cachedDeveloperToken = nil
        developerTokenExpiresAt = nil
    }

    // MARK: - Playlist Operations

    /// Create a new playlist in the user's library
    ///
    /// - Parameters:
    ///   - name: Playlist name
    ///   - description: Optional playlist description
    ///   - songIDs: Array of Apple Music song IDs to add
    /// - Returns: Tuple of playlist ID and optional URL
    func createPlaylist(
        name: String,
        description: String?,
        songIDs: [String]
    ) async throws -> (id: String, url: URL?) {
        // Get tokens
        let developerToken = try await getDeveloperToken()
        let userToken = try await getUserToken()

        // Build request URL
        guard let url = URL(string: "\(baseURL)/me/library/playlists") else {
            throw AppleMusicAPIError.invalidURL
        }

        // Build request body
        var attributes: [String: Any] = ["name": name]
        if let description = description {
            attributes["description"] = description
        }

        var requestBody: [String: Any] = [
            "attributes": attributes
        ]

        // Add tracks if provided
        if !songIDs.isEmpty {
            let trackData = songIDs.map { songID in
                return [
                    "id": songID,
                    "type": "songs"
                ]
            }
            requestBody["relationships"] = [
                "tracks": [
                    "data": trackData
                ]
            ]
        }

        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        // Set headers
        let headers = [
            "Authorization": "Bearer \(developerToken)",
            "Music-User-Token": userToken,
            "Content-Type": "application/json"
        ]

        // Make request
        do {
            let (responseData, response) = try await httpClient.request(
                url: url,
                method: "POST",
                headers: headers,
                body: bodyData
            )

            // Check status code
            switch response.statusCode {
            case 201:
                // Success - parse response
                return try parsePlaylistResponse(responseData)

            case 401:
                throw AppleMusicAPIError.unauthorized

            case 429:
                throw AppleMusicAPIError.rateLimitExceeded

            default:
                throw AppleMusicAPIError.invalidResponse
            }
        } catch let error as AppleMusicAPIError {
            throw error
        } catch {
            throw AppleMusicAPIError.networkError
        }
    }

    /// Add songs to an existing playlist
    ///
    /// - Parameters:
    ///   - playlistID: ID of the playlist
    ///   - songIDs: Array of Apple Music song IDs to add
    func addSongs(to playlistID: String, songIDs: [String]) async throws {
        guard !songIDs.isEmpty else { return }

        // Get tokens
        let developerToken = try await getDeveloperToken()
        let userToken = try await getUserToken()

        // Build request URL
        guard let url = URL(string: "\(baseURL)/me/library/playlists/\(playlistID)/tracks") else {
            throw AppleMusicAPIError.invalidURL
        }

        // Build request body
        let trackData = songIDs.map { songID in
            return [
                "id": songID,
                "type": "songs"
            ]
        }

        let requestBody: [String: Any] = [
            "data": trackData
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        // Set headers
        let headers = [
            "Authorization": "Bearer \(developerToken)",
            "Music-User-Token": userToken,
            "Content-Type": "application/json"
        ]

        // Make request
        do {
            let (_, response) = try await httpClient.request(
                url: url,
                method: "POST",
                headers: headers,
                body: bodyData
            )

            // Check status code
            switch response.statusCode {
            case 204:
                // Success - no content
                return

            case 401:
                throw AppleMusicAPIError.unauthorized

            case 404:
                throw AppleMusicAPIError.playlistNotFound

            case 429:
                throw AppleMusicAPIError.rateLimitExceeded

            default:
                throw AppleMusicAPIError.invalidResponse
            }
        } catch let error as AppleMusicAPIError {
            throw error
        } catch {
            throw AppleMusicAPIError.networkError
        }
    }

    // MARK: - Response Parsing

    private func parsePlaylistResponse(_ data: Data) throws -> (id: String, url: URL?) {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let dataArray = json?["data"] as? [[String: Any]],
              let playlist = dataArray.first,
              let playlistID = playlist["id"] as? String else {
            throw AppleMusicAPIError.invalidResponse
        }

        // Try to construct URL
        var playlistURL: URL?
        if let href = playlist["href"] as? String {
            playlistURL = URL(string: "https://music.apple.com\(href)")
        }

        return (playlistID, playlistURL)
    }
}

// MARK: - URLSession HTTP Client

class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request(
        url: URL,
        method: String,
        headers: [String: String]?,
        body: Data?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        // Set headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Perform request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppleMusicAPIError.invalidResponse
        }

        return (data, httpResponse)
    }
}

// MARK: - API Errors

enum AppleMusicAPIError: Error, LocalizedError, Equatable {
    case notAuthorized
    case noUserToken
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case playlistNotFound
    case networkError

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "User has not authorized Apple Music access"
        case .noUserToken:
            return "Unable to retrieve user token from MusicKit"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Apple Music API"
        case .unauthorized:
            return "Unauthorized - developer token or user token is invalid"
        case .rateLimitExceeded:
            return "Rate limit exceeded - please try again later"
        case .playlistNotFound:
            return "Playlist not found"
        case .networkError:
            return "Network error occurred"
        }
    }
}
