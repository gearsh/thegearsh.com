# Gearsh App - Store Publishing Guide

## 📱 App Information

- **App Name:** Gearsh
- **Bundle ID (iOS):** com.thegearsh.app
- **Package Name (Android):** com.gearsh.app
- **Version:** 1.0.0
- **Build Number:** 1

---

## 🤖 Google Play Store Checklist

### 1. Developer Account
- [ ] Google Play Developer Account ($25 one-time fee)
- [ ] Create account at: https://play.google.com/console

### 2. App Signing
- [ ] Generate Upload Key (already configured in `android/key.properties`)
- [ ] App Bundle signing enabled in Play Console

### 3. Build Release APK/AAB
```powershell
cd C:\Users\admin\StudioProjects\thegearsh.com

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Or build APK
flutter build apk --release --split-per-abi
```

### 4. Store Listing Requirements
- [ ] **App Name:** Gearsh (max 30 characters)
- [ ] **Short Description:** Book DJs, Photographers & Creative Talent (max 80 characters)
- [ ] **Full Description:** (see below)
- [ ] **App Category:** Entertainment or Lifestyle
- [ ] **Content Rating:** Complete questionnaire
- [ ] **Privacy Policy URL:** Required

### 5. Graphics Assets Required
| Asset | Size | Quantity |
|-------|------|----------|
| App Icon | 512x512 px | 1 |
| Feature Graphic | 1024x500 px | 1 |
| Phone Screenshots | 16:9 or 9:16 | 2-8 |
| Tablet Screenshots (7") | 16:9 or 9:16 | Optional |
| Tablet Screenshots (10") | 16:9 or 9:16 | Optional |

### 6. key.properties Setup
Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gearsh-upload
storeFile=../keys/gearsh-upload.keystore
```

### 7. Generate Keystore (if not done)
```powershell
keytool -genkey -v -keystore gearsh-upload.keystore -alias gearsh-upload -keyalg RSA -keysize 2048 -validity 10000
```

---

## 🍎 Apple App Store Checklist

### 1. Developer Account
- [ ] Apple Developer Program ($99/year)
- [ ] Enroll at: https://developer.apple.com/programs/

### 2. Certificates & Profiles
- [ ] Create Distribution Certificate
- [ ] Create App Store Provisioning Profile
- [ ] Configure in Xcode

### 3. Build for App Store
```bash
# On macOS only
cd ios
pod install
cd ..
flutter build ipa --release
```

### 4. App Store Connect Setup
- [ ] Create App in App Store Connect
- [ ] Set Bundle ID: `com.thegearsh.app`
- [ ] Configure In-App Purchases (if any)
- [ ] Set up TestFlight for beta testing

### 5. Required Screenshots
| Device | Size | Quantity |
|--------|------|----------|
| iPhone 6.7" | 1290x2796 px | 3-10 |
| iPhone 6.5" | 1284x2778 px | 3-10 |
| iPhone 5.5" | 1242x2208 px | 3-10 |
| iPad Pro 12.9" (6th gen) | 2048x2732 px | Optional |
| iPad Pro 12.9" (2nd gen) | 2048x2732 px | Optional |

### 6. App Privacy
- [ ] Complete App Privacy questionnaire
- [ ] Data collection disclosure
- [ ] Tracking transparency (if applicable)

---

## 📝 Store Descriptions

### Short Description (80 characters)
```
Book DJs, Photographers, Videographers & Creative Talent for Your Events
```

### Full Description
```
🎵 GEARSH - Your Gateway to Creative Talent 🎵

Discover and book the best artists for your events! Whether you're planning a wedding, corporate event, birthday party, or any special occasion, Gearsh connects you with verified creative professionals.

🎭 FIND THE PERFECT ARTIST
• DJs & Musicians
• Photographers & Videographers  
• Makeup Artists & Stylists
• Event Planners & Decorators
• Content Creators & Influencers
• And many more categories!

📅 BOOK WITH CONFIDENCE
• View detailed artist profiles & portfolios
• Check ratings and reviews from real clients
• See transparent pricing upfront
• Instant booking confirmation
• Secure payments via PayFast

💬 DIRECT COMMUNICATION
• Chat directly with artists
• Discuss your event requirements
• Get personalized quotes
• Share inspiration and ideas

❤️ FOR FANS
• Follow your favourite artists
• Discover upcoming gigs and events
• Buy tickets to live performances
• Shop exclusive merch

🌟 FOR ARTISTS
• Showcase your talent to millions worldwide
• Manage bookings in one place
• Get paid securely in your local currency
• Grow your creative business globally

Download Gearsh today and make your next event unforgettable!

🌍 Available Worldwide
```

### Keywords (for App Store)
```
book artist, dj booking, photographer, event planning, wedding dj, party entertainment, creative talent, live music, booking app, global events, worldwide artists, music booking, entertainment app, hire performers
```

---

## 🔒 Privacy Policy Requirements

Your privacy policy must include:
- [ ] What data is collected
- [ ] How data is used
- [ ] Third-party services (Firebase, Payment providers)
- [ ] User rights (GDPR, CCPA, POPIA compliance)
- [ ] Contact information
- [ ] Data retention policy

**Privacy Policy URL:** https://thegearsh.com/privacy

---

## ✅ Pre-Launch Checklist

### Code Quality
- [ ] Remove all debug prints
- [ ] Test on multiple devices
- [ ] Test offline behavior
- [ ] Test payment flow (sandbox)
- [ ] Verify deep links work
- [ ] Check crash analytics setup

### Security
- [ ] API keys in environment variables
- [ ] ProGuard enabled for Android
- [ ] Certificate pinning configured
- [ ] Sensitive data encrypted

### Performance
- [ ] App loads within 3 seconds
- [ ] Images optimized
- [ ] No memory leaks
- [ ] Battery usage optimized

### Legal
- [ ] Terms of Service published
- [ ] Privacy Policy published
- [ ] POPIA compliance (South Africa)
- [ ] Age rating appropriate

---

## 🚀 Build Commands

### Android Release Build
```powershell
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle for Play Store
flutter build appbundle --release --build-name=1.0.0 --build-number=1

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS Release Build (macOS required)
```bash
# Clean previous builds
flutter clean

# Get dependencies  
flutter pub get

# Install CocoaPods
cd ios && pod install && cd ..

# Build IPA for App Store
flutter build ipa --release --build-name=1.0.0 --build-number=1

# Output: build/ios/ipa/Gearsh.ipa
```

---

## 📊 Analytics & Monitoring

### Recommended Services
- [ ] Firebase Analytics (already integrated)
- [ ] Firebase Crashlytics
- [ ] Firebase Performance Monitoring

### Add Crashlytics
```yaml
# Add to pubspec.yaml
firebase_crashlytics: ^3.4.8
```

---

## 🔄 Post-Launch

### Week 1
- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Track key metrics (downloads, retention)

### Month 1
- [ ] Analyze user behavior
- [ ] Plan first update based on feedback
- [ ] A/B test store listing

---

## 📞 Support Information

- **Support Email:** support@thegearsh.com
- **Website:** https://thegearsh.com
- **Privacy Policy:** https://thegearsh.com/privacy
- **Terms of Service:** https://thegearsh.com/terms

