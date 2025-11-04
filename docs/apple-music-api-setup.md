# Apple Music API Setup Guide

## Overview

The Apple Music API integration has been implemented using the official REST API instead of MusicKit's limited library APIs on macOS. This provides full playlist creation functionality.

## Implementation Summary

### New Files Created

**Services:**
1. `PlaylistCreator/Services/AppleMusicAPIClient.swift` - REST API client for Apple Music
2. `PlaylistCreator/Services/DeveloperTokenGenerator.swift` - JWT token generation with ES256 signing
3. `PlaylistCreator/Configuration/AppleMusicConfig.swift` - Configuration management for credentials

**Tests:**
4. `PlaylistCreatorTests/Services/AppleMusicAPIClientTests.swift` - Comprehensive test suite (18 tests)

### Modified Files

1. `PlaylistCreator/Services/AppleMusicPlaylistService.swift`
   - Updated `RealMusicKitWrapper` to use `AppleMusicAPIClient`
   - Added `userToken` property to `MusicKitWrapperProtocol`
   - Improved error handling and conversion

2. `PlaylistCreatorTests/Services/AppleMusicPlaylistServiceTests.swift`
   - Added `userToken` property to `MockMusicKitWrapper`

## Setup Instructions

### Step 1: Add Files to Xcode Project

Open your Xcode project and add the following files:

**To PlaylistCreator target:**
- `PlaylistCreator/Services/AppleMusicAPIClient.swift`
- `PlaylistCreator/Services/DeveloperTokenGenerator.swift`
- `PlaylistCreator/Configuration/AppleMusicConfig.swift`

**To PlaylistCreatorTests target:**
- `PlaylistCreatorTests/Services/AppleMusicAPIClientTests.swift`

**How to add:**
1. Right-click on the appropriate folder in Xcode
2. Select "Add Files to PlaylistCreator..."
3. Select the files listed above
4. Ensure the appropriate target (PlaylistCreator or PlaylistCreatorTests) is checked

### Step 2: Get Apple Developer Credentials

You need three pieces of information from your Apple Developer account:

#### 1. Team ID (10 characters)
- Log in to https://developer.apple.com/account
- Your Team ID is shown at the top right
- Example: `AB12CD34EF`

#### 2. MusicKit Key ID (10 characters)
- Go to https://developer.apple.com/account/resources/authkeys/list
- Click the "+" button to create a new key
- Check "MusicKit" under "Key Services"
- Enter a key name (e.g., "Playlist Creator MusicKit Key")
- Click "Continue" then "Register"
- **Save the Key ID** (10 characters, e.g., `1A2B3C4D5E`)
- Download the `.p8` private key file (you can only download once!)

#### 3. Private Key (.p8 file)
- Download the `.p8` file when creating the key (see step 2)
- Save it securely - you cannot download it again
- The file contains your ES256 private key in PEM format

### Step 3: Configure Environment Variables

Set the following environment variables:

```bash
export APPLE_MUSIC_TEAM_ID="AB12CD34EF"
export APPLE_MUSIC_KEY_ID="1A2B3C4D5E"
export APPLE_MUSIC_PRIVATE_KEY_FILE="/path/to/AuthKey_1A2B3C4D5E.p8"
```

**Option 1: Terminal (temporary)**
```bash
export APPLE_MUSIC_TEAM_ID="YOUR_TEAM_ID"
export APPLE_MUSIC_KEY_ID="YOUR_KEY_ID"
export APPLE_MUSIC_PRIVATE_KEY_FILE="/path/to/your/AuthKey_XXXXX.p8"
```

**Option 2: Xcode Scheme (recommended for development)**
1. In Xcode, select your scheme (PlaylistCreator) and click "Edit Scheme..."
2. Select "Run" from the left sidebar
3. Go to the "Arguments" tab
4. Under "Environment Variables", click "+" to add:
   - Name: `APPLE_MUSIC_TEAM_ID`, Value: `YOUR_TEAM_ID`
   - Name: `APPLE_MUSIC_KEY_ID`, Value: `YOUR_KEY_ID`
   - Name: `APPLE_MUSIC_PRIVATE_KEY_FILE`, Value: `/path/to/AuthKey_XXXXX.p8`

**Option 3: Configuration File**
Create a `AppleMusicConfig.plist` file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>TeamID</key>
    <string>AB12CD34EF</string>
    <key>KeyID</key>
    <string>1A2B3C4D5E</string>
    <key>PrivateKeyFile</key>
    <string>/path/to/AuthKey_1A2B3C4D5E.p8</string>
</dict>
</plist>
```

### Step 4: Update ServiceContainer (Optional)

If you want to use the real API client instead of mocks, update the `ServiceContainer.swift` file to initialize `RealMusicKitWrapper` with the API client:

```swift
func configureProduction() {
    // ... other services ...

    if #available(macOS 12.0, *) {
        do {
            // Load configuration from environment
            let config = try AppleMusicConfig.loadFromEnvironment()
            let apiClient = try config.buildAPIClient()
            let musicKitWrapper = RealMusicKitWrapper(apiClient: apiClient)

            register(PlaylistCreator.self) {
                AppleMusicPlaylistService(musicKitWrapper: musicKitWrapper)
            }
        } catch {
            print("⚠️ Failed to configure Apple Music API: \(error)")
            print("   Falling back to mock implementation")
            // Fallback to mock if configuration fails
            register(PlaylistCreator.self) { MockPlaylistCreator() }
        }
    } else {
        register(PlaylistCreator.self) { DefaultPlaylistCreator() }
    }
}
```

### Step 5: Build and Test

1. Build the project: `Cmd+B`
2. Run tests: `Cmd+U`
3. You should see 18 new tests passing for `AppleMusicAPIClientTests`

## How It Works

### Authentication Flow

1. **Developer Token Generation**
   - Your Team ID, Key ID, and private key are used to generate a JWT token
   - Token is signed with ES256 (ECDSA using P-256 and SHA-256)
   - Token is valid for 6 months (max allowed by Apple)
   - Token is cached to avoid regeneration

2. **User Authorization**
   - App requests authorization via MusicKit
   - User grants permission in System Settings
   - MusicKit provides a user-specific token
   - Both developer and user tokens are required for API calls

3. **Playlist Creation**
   - App makes POST request to `https://api.music.apple.com/v1/me/library/playlists`
   - Request includes both tokens in headers:
     - `Authorization: Bearer <developer_token>`
     - `Music-User-Token: <user_token>`
   - Apple Music API creates the playlist and returns playlist ID and URL

### API Endpoints Used

**Create Playlist:**
```
POST https://api.music.apple.com/v1/me/library/playlists
```

**Add Songs to Playlist:**
```
POST https://api.music.apple.com/v1/me/library/playlists/{id}/tracks
```

## Security Notes

- **Never commit your private key (.p8 file) to version control**
- Add `*.p8` to your `.gitignore`
- Store credentials securely using environment variables or Keychain
- The private key cannot be regenerated if lost
- Developer tokens expire after 6 months (handled automatically by caching)
- User tokens are session-specific and managed by MusicKit

## Troubleshooting

### "Missing environment variable" error
- Ensure all three environment variables are set
- Check that paths are absolute, not relative
- Verify the `.p8` file exists at the specified path

### "Invalid Team ID" or "Invalid Key ID" errors
- Team ID and Key ID must be exactly 10 characters
- Check for typos or extra spaces

### "Invalid private key format" error
- Ensure the `.p8` file is the original download from Apple Developer
- File should start with `-----BEGIN PRIVATE KEY-----`
- File should be in PEM format, not DER or other formats

### "Unauthorized" API errors
- Verify Team ID matches the key's team
- Ensure Key ID matches the downloaded `.p8` file
- Check that MusicKit is enabled for the key
- Verify user has granted Apple Music authorization

### Build errors about missing types
- Ensure all new files are added to the Xcode project
- Check that files are included in the correct targets
- Clean build folder (Cmd+Shift+K) and rebuild

## Testing

### Mock Testing
All tests use mock implementations and don't require real credentials:
```bash
xcodebuild test -scheme PlaylistCreator
```

### Integration Testing
To test with real Apple Music API (requires credentials):
1. Set environment variables with real credentials
2. Configure production services in ServiceContainer
3. Run the app and test playlist creation

## Next Steps

1. ✅ Add files to Xcode project
2. ✅ Get Apple Developer credentials
3. ✅ Set environment variables
4. ✅ Build and verify tests pass
5. ✅ Test playlist creation with real account

After completing these steps, your app will create playlists directly in users' Apple Music libraries using the official Apple Music API!

## References

- [Apple Music API Documentation](https://developer.apple.com/documentation/applemusicapi)
- [Create Library Playlist Endpoint](https://developer.apple.com/documentation/applemusicapi/create-a-new-library-playlist)
- [MusicKit Authentication](https://developer.apple.com/documentation/applemusicapi/generating_developer_tokens)
- [JWT Token Generation](https://developer.apple.com/documentation/applemusicapi/generating_developer_tokens)
