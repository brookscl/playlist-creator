import Foundation
import Security

// MARK: - Developer Token Generator Protocol

protocol DeveloperTokenGenerator {
    func generateToken() throws -> (token: String, expiresAt: Date)
}

// MARK: - JWT Token Generator

/// Generates JWT tokens for Apple Music API authentication
///
/// This generator creates ES256-signed JWT tokens using the developer's private key.
/// Tokens are valid for 6 months (max allowed by Apple) and include:
/// - Team ID (iss)
/// - Issue time (iat)
/// - Expiration time (exp)
/// - Key ID in header (kid)
class JWTTokenGenerator: DeveloperTokenGenerator {
    private let teamID: String
    private let keyID: String
    private let privateKey: SecKey

    // Token lifetime: 6 months (max allowed by Apple Music API)
    private let tokenLifetime: TimeInterval = 60 * 60 * 24 * 180 // 180 days

    /// Initialize with developer credentials
    ///
    /// - Parameters:
    ///   - teamID: Apple Developer Team ID (10-character string)
    ///   - keyID: MusicKit Key ID (10-character string)
    ///   - privateKey: P-256 private key from Apple Developer portal
    init(teamID: String, keyID: String, privateKey: SecKey) throws {
        guard teamID.count == 10 else {
            throw TokenGenerationError.invalidTeamID
        }
        guard keyID.count == 10 else {
            throw TokenGenerationError.invalidKeyID
        }

        self.teamID = teamID
        self.keyID = keyID
        self.privateKey = privateKey
    }

    /// Convenience initializer with PEM-encoded private key
    ///
    /// - Parameters:
    ///   - teamID: Apple Developer Team ID
    ///   - keyID: MusicKit Key ID
    ///   - privateKeyPEM: PEM-encoded P-256 private key string
    convenience init(teamID: String, keyID: String, privateKeyPEM: String) throws {
        let privateKey = try Self.parsePrivateKey(from: privateKeyPEM)
        try self.init(teamID: teamID, keyID: keyID, privateKey: privateKey)
    }

    func generateToken() throws -> (token: String, expiresAt: Date) {
        let now = Date()
        let expiresAt = now.addingTimeInterval(tokenLifetime)

        // Create JWT header
        let header = JWTHeader(
            alg: "ES256",
            kid: keyID
        )

        // Create JWT payload
        let payload = JWTPayload(
            iss: teamID,
            iat: Int(now.timeIntervalSince1970),
            exp: Int(expiresAt.timeIntervalSince1970)
        )

        // Encode header and payload
        let headerJSON = try JSONEncoder().encode(header)
        let payloadJSON = try JSONEncoder().encode(payload)

        let headerBase64 = headerJSON.base64URLEncodedString()
        let payloadBase64 = payloadJSON.base64URLEncodedString()

        let signingInput = "\(headerBase64).\(payloadBase64)"

        // Sign with private key
        let signature = try sign(message: signingInput, with: privateKey)
        let signatureBase64 = signature.base64URLEncodedString()

        let token = "\(signingInput).\(signatureBase64)"

        return (token, expiresAt)
    }

    // MARK: - Private Key Parsing

    private static func parsePrivateKey(from pem: String) throws -> SecKey {
        // Remove PEM header/footer and whitespace
        var keyString = pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let keyData = Data(base64Encoded: keyString) else {
            throw TokenGenerationError.invalidPrivateKeyFormat
        }

        // Parse PKCS#8 format
        let strippedData = try stripPKCS8Header(from: keyData)

        // Create SecKey from raw key data
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 256
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(strippedData as CFData, attributes as CFDictionary, &error) else {
            if let error = error?.takeRetainedValue() {
                throw TokenGenerationError.privateKeyCreationFailed(error as Error)
            }
            throw TokenGenerationError.invalidPrivateKeyFormat
        }

        return secKey
    }

    private static func stripPKCS8Header(from keyData: Data) throws -> Data {
        // PKCS#8 header for EC P-256 private key
        // This is a simplified parser - production code should use a proper ASN.1 parser
        let bytes = [UInt8](keyData)

        // Look for the EC private key sequence (should be 32 bytes for P-256)
        // Skip PKCS#8 wrapper to get raw key
        if bytes.count > 36 {
            // Typical PKCS#8 wrapper is about 26-36 bytes
            // Raw P-256 key is 32 bytes
            if let keyStart = findPrivateKeyStart(in: bytes) {
                return keyData.suffix(from: keyStart)
            }
        }

        // If we can't parse, return as-is and let SecKey handle it
        return keyData
    }

    private static func findPrivateKeyStart(in bytes: [UInt8]) -> Int? {
        // Look for octet string tag (0x04) followed by length (0x20 = 32 bytes)
        for i in 0..<(bytes.count - 33) {
            if bytes[i] == 0x04 && bytes[i + 1] == 0x20 {
                return i + 2
            }
        }
        return nil
    }

    // MARK: - Signing

    private func sign(message: String, with key: SecKey) throws -> Data {
        guard let messageData = message.data(using: .utf8) else {
            throw TokenGenerationError.encodingFailed
        }

        // Hash the message with SHA-256
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        messageData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        let hashData = Data(hash)

        // Sign the hash
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            key,
            .ecdsaSignatureDigestX962SHA256,
            hashData as CFData,
            &error
        ) else {
            if let error = error?.takeRetainedValue() {
                throw TokenGenerationError.signingFailed(error as Error)
            }
            throw TokenGenerationError.signingFailed(nil)
        }

        return signature as Data
    }
}

// MARK: - JWT Models

private struct JWTHeader: Codable {
    let alg: String
    let kid: String
}

private struct JWTPayload: Codable {
    let iss: String // Team ID
    let iat: Int    // Issued at
    let exp: Int    // Expiration
}

// MARK: - Token Generation Errors

enum TokenGenerationError: Error, LocalizedError {
    case invalidTeamID
    case invalidKeyID
    case invalidPrivateKeyFormat
    case privateKeyCreationFailed(Error)
    case encodingFailed
    case signingFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .invalidTeamID:
            return "Team ID must be a 10-character string"
        case .invalidKeyID:
            return "Key ID must be a 10-character string"
        case .invalidPrivateKeyFormat:
            return "Private key must be in PEM format"
        case .privateKeyCreationFailed(let error):
            return "Failed to create private key: \(error.localizedDescription)"
        case .encodingFailed:
            return "Failed to encode JWT data"
        case .signingFailed(let error):
            return "Failed to sign token: \(error?.localizedDescription ?? "unknown error")"
        }
    }
}

// MARK: - Data Extensions

extension Data {
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - CommonCrypto Bridge

import CommonCrypto

// Note: CC_SHA256 is imported from CommonCrypto which is available on macOS
