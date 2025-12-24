# Gearsh Play Store Preparation Guide

## 1. Generate Signing Key

First, create a directory for your keystore:
```powershell
mkdir android\keystore
```

Generate the release keystore:
```powershell
keytool -genkey -v -keystore android\keystore\gearsh-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gearsh
```

You'll be prompted for:
- Keystore password (save this securely!)
- Key password
- Your name, organization, etc.

## 2. Configure Signing

Copy the example key.properties file:
```powershell
copy android\key.properties.example android\key.properties
```

Edit `android/key.properties` with your actual values:
```properties
storePassword=YOUR_ACTUAL_STORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=gearsh
storeFile=../keystore/gearsh-release-key.jks
```

⚠️ **IMPORTANT**: Never commit `key.properties` or your `.jks` file to version control!

## 3. Build App Bundle for Play Store

```powershell
flutter build appbundle --release
```

The output will be at:
`build/app/outputs/bundle/release/app-release.aab`

## 4. Play Store Requirements Checklist

### Store Listing
- [ ] App name: "Gearsh" (max 30 characters)
- [ ] Short description (max 80 characters)
- [ ] Full description (max 4000 characters)
- [ ] App category: Entertainment or Lifestyle
- [ ] Content rating questionnaire completed

### Graphics Assets Required
- [ ] App icon: 512x512 PNG (32-bit, no alpha)
- [ ] Feature graphic: 1024x500 PNG or JPG
- [ ] Screenshots:
  - Phone: 2-8 screenshots (16:9 or 9:16)
  - 7" tablet: optional
  - 10" tablet: optional

### Privacy & Policies
- [ ] Privacy Policy URL: https://www.thegearsh.com/privacy
- [ ] Terms of Service URL: https://www.thegearsh.com/terms
- [ ] Data safety form completed

### App Content
- [ ] Target audience and content defined
- [ ] App access (if login required, provide test credentials)
- [ ] Ads declaration
- [ ] App contains ads: No (update if you add ads)

## 5. App Signing by Google Play

When uploading for the first time:
1. Choose "Let Google manage and protect your app signing key"
2. Upload your `.aab` file
3. Google will sign the app for distribution

## 6. Test Before Release

### Internal Testing
1. Create an internal test track
2. Add testers by email
3. Upload your AAB
4. Test on multiple devices

### Pre-launch Report
- Review the automated test results
- Fix any crashes or ANRs
- Address accessibility issues

## 7. Release Checklist

Before going live:
- [ ] All screenshots are high quality
- [ ] Description is compelling and accurate
- [ ] Privacy policy is accessible
- [ ] App has been tested on multiple devices
- [ ] All features work with production API
- [ ] Analytics/crash reporting is configured
- [ ] Version code and name are correct

## 8. Version Management

For future updates, increment in `pubspec.yaml`:
```yaml
version: 1.0.1+2  # 1.0.1 = versionName, 2 = versionCode
```

The versionCode must always increase for Play Store updates.

## Useful Commands

```powershell
# Build release APK (for testing)
flutter build apk --release

# Build app bundle (for Play Store)
flutter build appbundle --release

# Analyze APK size
flutter build apk --analyze-size

# Run release build on device
flutter run --release
```

## Support

For issues, contact: support@thegearsh.com

