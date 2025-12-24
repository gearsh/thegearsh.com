# Play Store Graphics Requirements

## Required Assets

### 1. App Icon
- **Size**: 512 x 512 px
- **Format**: PNG (32-bit, no alpha/transparency)
- **Location**: `store/graphics/icon_512.png`

### 2. Feature Graphic
- **Size**: 1024 x 500 px
- **Format**: PNG or JPG
- **Purpose**: Displayed at top of store listing
- **Location**: `store/graphics/feature_graphic.png`

### 3. Phone Screenshots (Required: 2-8)
- **Size**: 16:9 or 9:16 aspect ratio
- **Recommended**: 1080 x 1920 px (portrait)
- **Location**: `store/screenshots/phone/`

Suggested screenshots:
1. `01_home.png` - Home screen with featured artists
2. `02_search.png` - Search and discover artists
3. `03_artist_profile.png` - Artist profile with services
4. `04_booking.png` - Booking flow
5. `05_messages.png` - Direct messaging
6. `06_dashboard.png` - Artist dashboard (optional)

### 4. 7-inch Tablet Screenshots (Optional)
- **Size**: 1024 x 768 px or similar 4:3 ratio
- **Location**: `store/screenshots/tablet_7/`

### 5. 10-inch Tablet Screenshots (Optional)
- **Size**: 1920 x 1200 px or similar 16:10 ratio
- **Location**: `store/screenshots/tablet_10/`

## Design Guidelines

### Color Palette
- Primary: #0EA5E9 (Sky Blue)
- Secondary: #06B6D4 (Cyan)
- Background: #020617 (Slate 950)
- Text: #FFFFFF (White)

### Typography
- Headlines: Bold, clean sans-serif
- Body: Regular weight, readable

### Style
- Dark theme preferred
- Show actual app UI
- Include device frames (optional)
- Add brief text overlays highlighting features

## Creating Screenshots

### Method 1: Flutter Screenshot
```dart
// Add to your app for testing
import 'package:screenshot/screenshot.dart';
```

### Method 2: Android Studio
1. Run app on emulator
2. Click camera icon in toolbar
3. Save screenshots

### Method 3: Physical Device
1. Run app on device
2. Use volume down + power button
3. Transfer to computer

## Tips for Great Screenshots

1. **Show value immediately** - First screenshot should hook users
2. **Use real content** - Show actual artists, not placeholder data
3. **Highlight key features** - Focus on what makes Gearsh unique
4. **Consistent style** - Use same device frame and overlay style
5. **Add captions** - Brief text explaining what user sees

## File Checklist

```
store/
├── graphics/
│   ├── icon_512.png
│   └── feature_graphic.png
├── screenshots/
│   ├── phone/
│   │   ├── 01_home.png
│   │   ├── 02_search.png
│   │   ├── 03_artist_profile.png
│   │   ├── 04_booking.png
│   │   └── 05_messages.png
│   ├── tablet_7/
│   └── tablet_10/
└── README.md
```

