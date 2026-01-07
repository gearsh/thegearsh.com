# 🚀 Gearsh App - Quick Start Publishing Checklist

## Before You Begin

Run these commands in your terminal:

```powershell
cd C:\Users\admin\StudioProjects\thegearsh.com
flutter pub get
flutter analyze
```

---

## 📱 ANDROID - Google Play Store

### Step 1: Generate Upload Keystore (One-time only)

```powershell
# Create keystore directory
mkdir -p android\keystore

# Generate keystore
keytool -genkey -v -keystore android\keystore\gearsh-upload.keystore -alias gearsh-upload -keyalg RSA -keysize 2048 -validity 10000

# Remember your passwords!
```

### Step 2: Configure key.properties

Create file `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gearsh-upload
storeFile=keystore/gearsh-upload.keystore
```

### Step 3: Build Release

```powershell
# Clean and build
flutter clean
flutter pub get
flutter build appbundle --release

# Output: build\app\outputs\bundle\release\app-release.aab
```

### Step 4: Upload to Play Console

1. Go to https://play.google.com/console
2. Create new app → "Gearsh"
3. Upload the `.aab` file
4. Complete store listing (use descriptions from STORE_PUBLISHING_GUIDE.md)
5. Upload screenshots
6. Submit for review

---

## 🍎 iOS - Apple App Store (Requires Mac)

### Step 1: Configure Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Set Team to your Apple Developer account
4. Bundle ID: `com.thegearsh.app`

### Step 2: Build Release

```bash
# On macOS
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release

# Output: build/ios/ipa/Gearsh.ipa
```

### Step 3: Upload to App Store Connect

1. Open Xcode → Transporter app
2. Upload the `.ipa` file
3. Or use: `xcrun altool --upload-app -f build/ios/ipa/Gearsh.ipa`

### Step 4: App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Create new app → "Gearsh"
3. Select the build you uploaded
4. Complete app information
5. Submit for review

---

## ✅ Final Checklist

### Required for Both Stores
- [ ] App icon (512x512 for Android, 1024x1024 for iOS)
- [ ] Feature graphic 1024x500 (Android)
- [ ] Screenshots (phones and tablets)
- [ ] Privacy Policy URL
- [ ] Terms of Service URL

### Content
- [ ] App description
- [ ] Short description
- [ ] Keywords
- [ ] What's New text

### Legal
- [ ] Privacy Policy published at thegearsh.com/privacy
- [ ] Terms of Service published at thegearsh.com/terms
- [ ] Content rating questionnaire completed
- [ ] Age rating set

---

## 📞 Support Info to Add

- **Developer Name:** Gearsh (Pty) Ltd
- **Email:** support@thegearsh.com
- **Website:** https://thegearsh.com
- **Privacy Policy:** https://thegearsh.com/privacy

---

## 🔧 PayFast Configuration (Before Release!)

Update `lib/services/payfast_service.dart`:

```dart
// Change from sandbox to live
static const String _merchantId = 'YOUR_LIVE_MERCHANT_ID';
static const String _merchantKey = 'YOUR_LIVE_MERCHANT_KEY';
static const String _passphrase = 'YOUR_LIVE_PASSPHRASE';
static const bool _isSandbox = false; // SET TO FALSE FOR PRODUCTION!
```

---

## 📊 After Publishing

1. **Monitor Crashlytics** - Firebase Console → Crashlytics
2. **Track Analytics** - Firebase Console → Analytics
3. **Respond to Reviews** - Both stores
4. **Monitor Downloads** - Play Console / App Store Connect

Good luck with your launch! 🎉

