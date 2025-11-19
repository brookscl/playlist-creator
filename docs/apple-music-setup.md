# Apple Music Setup Guide - iOS Native MusicKit

This guide explains the Apple Music setup for the Playlist Creator app, which uses **native iOS MusicKit APIs**.

## Important: No Developer Credentials Required!

The current implementation uses **native iOS MusicKit** which authenticates through the user's Apple Music subscription. You do NOT need:

- ❌ Developer tokens
- ❌ MusicKit private keys (.p8 files)
- ❌ REST API credentials
- ❌ Environment variables

## What You DO Need

### 1. Apple Developer Account

You need an active Apple Developer Program membership ($99/year) to:
- Code sign the app
- Test on physical devices
- Access MusicKit APIs

### 2. MusicKit Configuration in Xcode

The app is already configured with the necessary MusicKit settings:

#### a. Team ID
In `project.yml`, the following is set:
```yaml
DEVELOPMENT_TEAM: "JFK2G5292Q"
MusicKitDeveloperTeamIdentifier: "JFK2G5292Q"
```

**You need to update this to your own Team ID:**
1. Go to https://developer.apple.com/account
2. Sign in with your Apple ID
3. Copy your Team ID (10-character string in the top-right corner)
4. Update `project.yml` with your Team ID

#### b. Bundle ID
The app bundle ID is: `org.chrisbrooks.playlistcreator`

**You should change this to your own:**
1. Update `bundleIdPrefix` in `project.yml` to your domain
2. Update the bundle ID accordingly

#### c. MusicKit Entitlements
The app already has the necessary entitlements in `PlaylistCreator.entitlements`:
```xml
<key>com.apple.developer.musickit</key>
<true/>
```

### 3. User Requirements

Users of the app must have:
- ✅ iOS 17.0 or later
- ✅ An active Apple Music subscription
- ✅ Signed in to Apple Music on their device

## How It Works

### Authorization Flow

1. **User launches app** - No authentication happens yet
2. **User tries to create playlist** - App requests MusicKit authorization
3. **System shows permission dialog** - User grants or denies access
4. **If granted** - App can search Apple Music and create playlists

### Playlist Creation

The app uses `MusicLibrary.shared.createPlaylist()` which:
- Creates playlists directly in the user's Apple Music library
- Uses the user's Apple Music subscription for authentication
- Requires no developer tokens or API keys

## Setup Steps for Development

### 1. Update Team ID

Edit `project.yml`:
```yaml
settings:
  DEVELOPMENT_TEAM: "YOUR_TEAM_ID"  # Replace with your Team ID

targets:
  PlaylistCreator:
    info:
      properties:
        MusicKitDeveloperTeamIdentifier: "YOUR_TEAM_ID"  # Same Team ID
```

### 2. Update Bundle ID (Optional)

Edit `project.yml`:
```yaml
options:
  bundleIdPrefix: com.yourname  # Replace with your domain

targets:
  PlaylistCreator:
    info:
      properties:
        CFBundleIdentifier: com.yourname.playlistcreator
```

### 3. Regenerate Xcode Project

After updating `project.yml`, regenerate the Xcode project:
```bash
xcodegen generate
```

### 4. Open in Xcode

```bash
open PlaylistCreator.xcodeproj
```

### 5. Configure Code Signing

1. Select the PlaylistCreator target
2. Go to Signing & Capabilities
3. Select your team
4. Xcode will automatically provision the app

### 6. Build and Run

1. Connect your iPhone
2. Select it as the destination
3. Click Run (⌘R)
4. Trust the developer certificate on your iPhone if prompted

## Testing the App

### First Launch
1. Launch the app on your iPhone
2. Upload an audio file with music mentions (or use a test file)
3. Process through transcription and extraction
4. When creating the playlist, you'll see the MusicKit authorization dialog

### Grant Permission
1. Tap "Allow" when prompted for Apple Music access
2. The app will create the playlist in your library
3. Open Apple Music to verify the playlist was created

### Verify in Apple Music
1. Open the Apple Music app
2. Go to Library → Playlists
3. You should see your newly created playlist

## Troubleshooting

### "User has not authorized Apple Music access"

**Cause:** User denied MusicKit permission or has it disabled

**Solution:**
1. Go to Settings → Privacy & Security → Media & Apple Music
2. Find "Playlist Creator"
3. Enable access

### "Apple Music subscription required"

**Cause:** User is not signed in to Apple Music or doesn't have a subscription

**Solution:**
1. Open Apple Music app
2. Sign in with Apple ID
3. Verify you have an active subscription

### "Failed to create playlist" (generic error)

**Cause:** Various potential issues

**Solution:**
1. Check Xcode console for detailed error logs
2. Verify you're running iOS 17.0+
3. Verify user is signed in to Apple Music
4. Try restarting the app

### Build Error: "No profiles for 'org.chrisbrooks.playlistcreator'"

**Cause:** Bundle ID is not provisioned for your team

**Solution:**
1. Update the bundle ID in `project.yml` to use your own prefix
2. Regenerate the project with `xcodegen generate`
3. Let Xcode automatically create provisioning profile

### Build Error: "Invalid Team ID"

**Cause:** Team ID in project.yml doesn't match your Apple Developer account

**Solution:**
1. Get your Team ID from https://developer.apple.com/account
2. Update both DEVELOPMENT_TEAM and MusicKitDeveloperTeamIdentifier in `project.yml`
3. Regenerate the project

## Architecture Notes

### Current Implementation (iOS 17+)

```swift
class RealMusicKitWrapper: MusicKitWrapperProtocol {
    // Uses user's Apple Music subscription
    // No developer tokens needed

    func createPlaylist(name: String, description: String?, songIDs: [String]) async throws {
        // 1. Fetch songs from Apple Music catalog using user subscription
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: songIDs)
        let response = try await request.response()

        // 2. Create playlist in user's library
        let playlist = try await MusicLibrary.shared.createPlaylist(
            name: name,
            description: description,
            items: response.items
        )
    }
}
```

### Why No Developer Tokens?

Apple provides two ways to access MusicKit:

1. **REST API** (Web/Server apps)
   - Requires developer tokens (ES256 JWT)
   - Requires private keys (.p8 files)
   - Complex setup
   - For web apps or servers

2. **Native MusicKit** (iOS/macOS apps) ← **We use this!**
   - Uses user's Apple Music subscription
   - Simple authorization flow
   - No tokens or keys needed
   - For native apps only

## Security & Privacy

### What Data Is Accessed?

The app only accesses:
- Apple Music catalog for searching songs
- User's music library to create playlists
- User's Apple Music subscription for authentication

### What Data Is NOT Accessed?

The app does NOT access:
- User's listening history
- User's existing playlists (read-only)
- Any personal data beyond music library

### User Control

Users can:
- Revoke MusicKit access anytime in Settings
- Delete created playlists in Apple Music
- Uninstall the app to remove all data

## Next Steps

Once configured and running:
1. ✅ App requests user authorization automatically
2. ✅ User grants access via system dialog
3. ✅ App creates playlists in user's library
4. ✅ User can view/edit/delete playlists in Apple Music

For questions or issues, check the Xcode console logs for detailed error messages.
