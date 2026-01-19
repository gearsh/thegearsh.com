# Gearsh v1.0.0 - App Store Screenshots Guide

## 🚀 Launch Date: January 20, 2026

This document outlines the 10 key screens for app store screenshots, all using **real Gearsh artists** (Y.D.E, ZJ90, Rix Elton).

---

## ✅ Responsive Optimizations Applied

All screens have been optimized for:
- **Small phones** (width < 360dp) - Samsung Galaxy A series, older devices
- **Standard phones** (360-600dp) - Most Android phones
- **Tablets** (600dp+) - Samsung Tab, iPad

### Key Responsive Fixes:
- Text overflow prevention with `maxLines` and `overflow: TextOverflow.ellipsis`
- `FittedBox` for price displays and buttons
- Flexible layouts with `Expanded` and `Flexible` widgets
- Reduced padding/spacing on small screens
- Responsive font sizes based on screen width
- ScrollViews added to prevent content overflow

---

## Screenshot Checklist

### Core User Journey Screens

#### 1. Onboarding/Welcome Screen ✅
- **File:** `lib/screens/onboarding_page.dart`
- **Content:**
  - "Discover Amazing Talent" - DJs, Photographers, Producers
  - "Book in Seconds" - Fast, secure & hassle-free
  - "Grow Your Career" - For artists & creatives
- **Theme:** Sky blue gradient with animated glows

#### 2. Profile Type Selection (Signup Step 1) ✅
- **File:** `lib/screens/onboarding_page.dart` (Role Selection)
- **File:** `lib/features/profile/signup_page.dart`
- **Content:**
  - Client/Booker (Blue) - Book artists for events
  - Artist/Creative (Purple) - Get discovered & booked
  - Fan/Supporter (Pink) - Follow & support artists
- **Shows:** Multi-sided marketplace

#### 3. Artist Profile/Portfolio ✅
- **File:** `lib/features/profile/artist_view_profile_page.dart`
- **Demo Artist:** Y.D.E, ZJ90, or Rix Elton
- **Shows:**
  - Artist bio, skills, photos
  - Services with pricing
  - Booking button
  - Mastery progress (10,000 hours system)

#### 4. Artist Discovery/Browse Feed ✅
- **File:** `lib/features/discover/discover_page.dart`
- **Content:**
  - "Discover Talent" header
  - Featured Artists section
  - Browse by category (Music, Visual Arts, etc.)
  - Real artists: Y.D.E, ZJ90, Rix Elton

#### 5. Booking Flow ✅
- **File:** `lib/features/booking/booking_flow_page.dart`
- **Demo:** Booking Y.D.E for "Live Performance (1 hour)"
- **Shows:**
  - Date/time selection
  - Event location input
  - Price breakdown with service fee
  - PayFast payment integration

---

### Engagement & Features

#### 6. Artist Dashboard ✅
- **File:** `lib/features/dashboard/artist_dashboard_page.dart`
- **Demo Data:**
  - R8,450 this month (+32%)
  - 156 total bookings (+18%)
  - 5 pending, 12 confirmed
  - 4.9 rating
- **Shows:** Earnings, analytics, upcoming events

#### 7. Messaging/Chat Screen ✅
- **File:** `lib/features/messages/messages_screen.dart`
- **Demo Conversations:**
  - Y.D.E: "Thanks for the booking! I'll be ready at 6 PM 🎤"
  - ZJ90: "I can bring my full DJ setup with lighting"
  - Rix Elton: "Looking forward to the event! 🔥"
- **Shows:** Direct client-artist communication

#### 8. Event Details / Gigs Page ✅
- **File:** `lib/features/gigs/gigs_page.dart`
- **Shows:**
  - Upcoming events with real artists
  - Date, venue, time
  - Ticket prices (Standard & VIP)
  - Get Tickets button

#### 9. Search with Filters ✅
- **File:** `lib/features/search/presentation/screens/search_screen.dart`
- **Categories:**
  - Music, Visual Arts, Performance
  - Tech & Digital, Content Creation
  - Beauty & Fashion, Events & Services
- **Filters:** Verified only, rating, location

#### 10. Profile Settings/Edit Profile ✅
- **File:** `lib/features/profile/profile_settings_page.dart`
- **File:** `lib/features/profile/edit_profile_page.dart`
- **Shows:**
  - User profile card
  - Region & currency settings
  - Account settings
  - Dark slate + sky blue theme

---

## Real Artists on Gearsh v1.0.0

| Artist | Category | Location | Price |
|--------|----------|----------|-------|
| **Y.D.E** | Emerging Artist/Rap | Louis Trichardt, SA | R2,000 (80% OFF) |
| **ZJ90** | DJ/House/Amapiano | Johannesburg, SA | R25,000 |
| **Rix Elton** | Amapiano/DJ/Producer | Johannesburg, SA | R20,000 |

---

## Screenshot Tips

1. **Use iPhone/Android demo mode** - Full battery, clean status bar
2. **Highlight the gradient theme** - Sky blue (#0EA5E9) to cyan (#06B6D4)
3. **Show real artist photos** - Y.D.E, ZJ90, Rix Elton
4. **Capture key user flows:**
   - Onboarding → Role Selection → Browse → Profile → Book
   - Artist Dashboard with earnings & bookings
   - Messages with active conversations

---

## Build Commands

```bash
# Android Release Build
flutter build appbundle --release

# iOS Release Build
flutter build ios --release

# Web Build
flutter build web --release
```

---

## Version Info

- **Version:** 1.0.0
- **Build:** Ready for App Store/Play Store
- **Last Updated:** January 19, 2026
