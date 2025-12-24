# Google Sign-In Setup Guide for Gearsh

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Name it "Gearsh" or similar

## Step 2: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Fill in:
   - App name: `Gearsh`
   - User support email: Your email
   - Developer contact: Your email
4. Add scopes: `email`, `profile`, `openid`
5. Save and continue

## Step 3: Create OAuth 2.0 Credentials

### For Android:

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Select **Android**
4. Fill in:
   - Name: `Gearsh Android`
   - Package name: `com.gearsh.app`
   - SHA-1 fingerprint: (see below how to get it)

### Get SHA-1 Fingerprint:

Run this command in your terminal:
```powershell
cd C:\Users\admin\StudioProjects\thegearsh.com\android
.\gradlew signingReport
```

Look for the **SHA1** under the `debug` variant. It looks like:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Or use keytool:
```powershell
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### For Web:

1. Click **Create Credentials** → **OAuth client ID**
2. Select **Web application**
3. Name: `Gearsh Web`
4. Authorized JavaScript origins:
   - `http://localhost`
   - `https://thegearsh-com.pages.dev`
5. Authorized redirect URIs:
   - `https://thegearsh-com.pages.dev`
6. Copy the **Client ID** (ends with `.apps.googleusercontent.com`)

## Step 4: Update Your App

### Update `social_auth_service.dart`:

Replace `YOUR_WEB_CLIENT_ID` with your actual Web Client ID:
```dart
static const String _webClientId = 'XXXXX.apps.googleusercontent.com';
```

### No google-services.json needed!

The `google_sign_in` package for Flutter doesn't require Firebase or google-services.json for basic sign-in. It uses the OAuth client ID directly.

## Step 5: Test

1. Rebuild the app: `flutter clean && flutter run`
2. Try Google Sign-In

## Common Errors:

- **Error 10**: SHA-1 not registered or package name mismatch
- **Error 12500**: OAuth consent screen not configured
- **Error 7**: Network error

## Your Package Name

Make sure Google Cloud Console has: `com.gearsh.app`

(Check your `android/app/build.gradle.kts` - applicationId should match)

