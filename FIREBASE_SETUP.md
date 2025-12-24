# Firebase Setup for Gearsh App (Hybrid Approach)

## Overview
This app uses a **hybrid architecture**:
- **Firebase Auth**: For authentication (Google Sign-In, Apple Sign-In, Email/Password)
- **Cloudflare D1**: For all other data (users, artists, bookings, etc.)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `gearsh-app`
4. Enable/disable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Android App

1. In Firebase Console, click the Android icon to add an Android app
2. Enter package name: `com.gearsh.app.gearsh_app`
3. Enter app nickname: `Gearsh Android`
4. Get your SHA-1 fingerprint by running:
   ```cmd
   cd C:\Users\admin\StudioProjects\thegearsh.com\android
   gradlew.bat signingReport
   ```
   Or run `get_sha1.bat` in the project root
5. Click "Register app"
6. Download `google-services.json`
7. Place it in: `android/app/google-services.json`

## Step 3: Add Web App

1. In Firebase Console, click the Web icon to add a web app
2. Enter app nickname: `Gearsh Web`
3. Check "Also set up Firebase Hosting" if desired
4. Click "Register app"
5. Copy the firebaseConfig object

## Step 4: Enable Authentication Methods

1. In Firebase Console, go to **Build > Authentication**
2. Click "Get started"
3. Go to **Sign-in method** tab
4. Enable the following providers:
   - **Email/Password** (enable email link too)
   - **Google** (add your SHA-1 for Android)
   - **Apple** (requires Apple Developer account configuration)

## Step 5: Configure Google Sign-In

1. In Firebase Console, go to **Settings (gear icon) > Project settings**
2. Scroll to "Your apps" and select your Android app
3. Add SHA-1 fingerprints for both debug and release builds

### Getting SHA-1 fingerprints:

**Debug build:**
```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android
```

**Release build:**
```cmd
keytool -list -v -keystore your_keystore.jks -alias your_alias
```

## Step 6: Configure Apple Sign-In

1. In Apple Developer Console, create a Service ID
2. Enable "Sign In with Apple"
3. Configure domains and return URLs:
   - Domain: `thegearsh-com.pages.dev`
   - Return URL: `https://gearsh-app.firebaseapp.com/__/auth/handler`
4. Add the Service ID to Firebase Apple provider settings

## Step 7: Update Web Configuration

Create `lib/config/firebase_config.dart`:

```dart
// Firebase configuration - DO NOT commit to public repos
class FirebaseConfig {
  static const String apiKey = 'YOUR_API_KEY';
  static const String authDomain = 'YOUR_PROJECT_ID.firebaseapp.com';
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String storageBucket = 'YOUR_PROJECT_ID.appspot.com';
  static const String messagingSenderId = 'YOUR_SENDER_ID';
  static const String appId = 'YOUR_APP_ID';
}
```

## Files to Add (from Firebase Console)

1. `android/app/google-services.json` - Download from Firebase Console
2. `ios/Runner/GoogleService-Info.plist` - Download from Firebase Console (if doing iOS)
3. `web/firebase-config.js` - Web configuration

## Testing

After setup, run:
```cmd
flutter pub get
flutter run
```

Try signing in with Google - it should now work without error code 10!

## Security Notes

- Never commit `google-services.json` to public repositories
- Add to `.gitignore`:
  ```
  **/google-services.json
  **/GoogleService-Info.plist
  lib/config/firebase_config.dart
  ```

## Architecture Benefits

| Feature | Service | Why |
|---------|---------|-----|
| Authentication | Firebase Auth | Handles OAuth complexity, built-in Google/Apple support |
| User Data | Cloudflare D1 | Your existing schema, full control |
| Artists | Cloudflare D1 | Your existing data |
| Bookings | Cloudflare D1 | Your existing schema |
| Real-time Chat | Firebase (future) | Easy real-time sync |
| Notifications | Firebase Cloud Messaging (future) | Push notifications |

