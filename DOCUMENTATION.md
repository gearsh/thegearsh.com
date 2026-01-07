Gearsh App — Project Documentation
=================================

*Last Updated: December 2025*

Table of Contents
-----------------

- Overview
- Quick Start
  - Requirements
  - Local setup
  - Build & Run
- Project Structure
- Architecture & Key Patterns
  - State Management
  - Navigation & Page Transitions
  - Theming
  - Scroll Behavior
- Core Features
  - Discover & Search
  - Artist Profile
  - Cart & Multi-Artist Booking
  - Checkout & Payments
  - User/Profile Flow
- Global Support
  - Supported Regions
  - Multi-Currency
  - Payment Providers
- Booking Infrastructure
  - Booking Agreements
  - Escrow Payments
  - Lifecycle Tracking
  - Incident Reporting
  - Communication Logs
  - Reliability Index
- Legal & Compliance
  - Privacy Policy
  - Terms of Service
  - FAQ & Help
- Important Files and Locations
- Data Models (high level)
- Providers and Notifiers
- Services
- UI/UX Notes
- Platform / Build Notes
  - Android (Gradle/AGP notes)
  - iOS notes
- Troubleshooting & Known Issues
- Testing
- Contributing
- Changelog (high level)
- Contact


Overview
--------

Gearsh is a **global Flutter mobile application** that helps users discover, follow, and book creative professionals (artists) such as DJs, musicians, photographers, videographers, visual artists, developers, actors, and other creators worldwide. 

**The Story**: Gearsh is a fusion of "gear" and "share" — the name reflects its origin as a gear-sharing platform. Founded in 2016 by a computer science student who aspired to be a DJ but couldn't afford the equipment, Gearsh started as an "Uber for gear" concept. The idea was to let musicians share equipment — owners earn money from idle gear, borrowers access expensive equipment affordably. Today, Gearsh has evolved into the ultimate artist e-booking service, connecting talent with those who want to book them.

The app provides:
- **Discovery feed** with categorised browsing and powerful search
- **Artist profiles** with services, ratings, and verification badges
- **Multi-artist booking cart** with checkout flow
- **Global support** for 20+ countries and 15+ currencies
- **Booking infrastructure** with escrow payments, status tracking, and dispute prevention
- **Smooth navigation** with custom page transitions

**Core Principle**: Gearsh records facts. It does not take sides in disputes — it provides a neutral infrastructure for booking creative talent.

This documentation describes the codebase as it stands in this repository, including project structure, key implementation details, how to run the app locally, and developer notes.


Quick Start
-----------

Requirements
- Flutter (the project uses a modern stable Flutter — ensure your `flutter` in `PATH` is up to date). See `flutter --version`.
- Android SDK and Android Studio (for Android builds)
- Optional: Xcode (for iOS builds on macOS)
- Java / JDK (the project is configured to use the Android Studio JBR)

Local setup (typical)
1. Clone the repo and cd into the project root.
2. Install Dart/Flutter dependencies:

```bash
flutter pub get
```

3. Ensure Android toolchain is configured (Android SDK, license acceptance):

```bash
flutter doctor
```

4. Run on a connected Android device or emulator:

```bash
flutter run
```

Build & Run (release)

```bash
# Android release (APK)
flutter build apk --release

# iOS release (requires macOS)
flutter build ios --release
```


Project Structure
-----------------

Top-level / important folders (lib/ is the main Dart code):

- android/ — Android platform configuration, Gradle wrapper, AGP settings
- ios/ — iOS platform files
- lib/ — Flutter application source
  - features/ — Feature modules (discover, cart, profile, bookings, search, dashboard, etc.)
  - data/ — Seed/static data (artists, images) and models
  - providers/ — Riverpod providers and notifiers
  - routes/ — App route configuration (GoRouter)
  - services/ — External services (payments, utilities)
  - widgets/ — Reusable UI components (search bar, background, nav bar)
  - main.dart — App entry point
  - gearsh_app.dart — App root widget and theme wiring
- assets/ — Images and static assets
- test/ — Tests (if any)


Architecture & Key Patterns
---------------------------

- Modular features: UI and logic are grouped under `lib/features/<feature_name>`.
- State management: Riverpod v3 Notifier/NotifierProvider pattern is used for app state (e.g., cart, search query, selection provider).
- Navigation: GoRouter is used for route management with custom page transitions.
- Theming: Centralised theme and consistent colours (see `lib/theme.dart` and colour constants used in widgets).
- Booking Infrastructure: Modular services for agreements, escrow, lifecycle tracking, incidents, and communication.

State Management
- Riverpod NotifierProvider pattern is used. Example providers include:
  - `cartProvider` (a NotifierProvider managing `CartState`)
  - `searchQueryProvider` (a simple Notifier for the search query)
  - `selectedArtistIdProvider` (artist selection)
  - `globalConfigProvider` (region and currency settings)

Navigation & Page Transitions
- `go_router` defines routes such as `/discover`, `/artist/:id`, `/cart`, `/profile`, etc.
- Custom `buildPageWithTransition()` function provides smooth transitions:
  - **Fade**: For tab switching (Home, Messages, Bookings, Profile) — instant feel
  - **Slide Up**: For modals/overlays (Cart, Search, Auth) — sheet-like appearance  
  - **Slide Right**: For detail pages (Artist profiles, Booking flow) — forward navigation
  - **Scale**: For success states — celebratory effect
- Transition duration: 250ms in, 200ms out with `Curves.easeOutCubic`
- **Swipe Right to Go Back**: Edge swipe from left side navigates to previous page
  - 40px edge detection zone
  - Visual indicator (glowing blue line) during swipe
  - Triggers on 80px drag distance or fast velocity
  - Smooth animation with content parallax effect

Scroll Behavior
- Custom `GearshScrollBehavior` class provides ultra-smooth scrolling
- Uses `BouncingScrollPhysics` with fast deceleration
- No scrollbars for cleaner mobile look
- Applied globally via `MaterialApp.router`

Theming
- The app uses dark background and a distinct primary colour (Deep Sky Blue). Colours are defined in `lib/theme.dart` and used throughout.


Core Features
-------------

Discover & Search
- Rich discover page with hero header, featured artists, browse categories, trending, and genre sections.
- Search uses `searchQueryProvider` and a custom ranking algorithm that supports fuzzy matching and multi-term ranking. Search triggers after two characters.
- Browse categories are grouped into 7 main categories (Music, Visual Arts, Performance, Tech & Digital, Content Creation, Beauty & Fashion, Events & Services).
- Filter panel for location, rating, and price filtering

Artist Profile
- Each artist has image, name, category, availability, verification badge, rating, services list, and contact/booking details.
- Artists have `countryCode` and `currencyCode` for global support
- Circular avatar design for premium brand look

Cart & Multi-Artist Booking
- Users can add multiple artists and their services to a cart.
- The `CartItem` data model stores artist/service/date/time/location/notes.
- Cart provides subtotal, service fee (12.6%), and total calculation.
- The app prevents adding duplicate artist-service combinations.
- Prices displayed in user's selected currency

Checkout & Payments
- The checkout page prepares a payment request and integrates payment services
- Region-specific payment providers (PayFast, Flutterwave, Stripe, etc.)
- After successful payment, escrow holds funds until performance completion
- Cart cleared after successful redirect

User/Profile Flow
- Three user types: **Client** (book artists), **Artist** (get booked), **Fan** (follow performances)
- Profile settings with region selector
- FAQ & Help section with About Gearsh, Privacy Policy, Terms & Conditions


Global Support
--------------

Supported Regions (20+ countries)
- **Africa**: South Africa 🇿🇦, Nigeria 🇳🇬, Kenya 🇰🇪, Ghana 🇬🇭, Botswana 🇧🇼, Namibia 🇳🇦, Zimbabwe 🇿🇼, Tanzania 🇹🇿, Uganda 🇺🇬, Rwanda 🇷🇼
- **Americas**: United States 🇺🇸, Canada 🇨🇦, Brazil 🇧🇷
- **Europe**: United Kingdom 🇬🇧, Germany 🇩🇪, France 🇫🇷
- **Asia Pacific**: Australia 🇦🇺, India 🇮🇳, UAE 🇦🇪, Japan 🇯🇵

Multi-Currency (15+ currencies)
- ZAR, USD, GBP, EUR, NGN, KES, GHS, AUD, CAD, INR, AED, BRL, BWP, NAD, JPY
- Artists set prices in local currency
- Clients see prices converted to their selected currency
- Exchange rates stored in `GlobalConfigService`

Payment Providers by Region
| Region | Providers |
|--------|-----------|
| South Africa | PayFast, PayStack, Card |
| Nigeria, Ghana, Kenya | Flutterwave, PayStack, M-Pesa |
| USA, Canada, UK, Europe | Stripe, PayPal, Card |
| Australia | Stripe, PayPal, Card |
| India | Razorpay, PayTM, UPI |
| UAE | Stripe, PayTabs, Card |
| Brazil | PagSeguro, MercadoPago, PIX |


Booking Infrastructure
----------------------

The booking infrastructure provides neutral, time-stamped record-keeping for dispute prevention.

Booking Agreements (`lib/models/booking_agreement.dart`)
- Immutable contracts with performance details, financial terms, rider
- Digital signatures from both parties
- Amendment process for changes after confirmation
- Locked rider enforcement

Escrow Payments (`lib/models/escrow_payment.dart`)
- Conditional payment holds
- Release conditions (check-in, performance start, completion)
- Automatic resolution paths (full release, partial, refund, credit)
- Dispute handling

Lifecycle Tracking (`lib/models/booking_lifecycle.dart`)
- Time-stamped status tracking: Scheduled → En Route → Arrived → Checked In → Performing → Completed
- Verification types: location-based, photo, QR code, other party confirmation
- Arrival tracking with grace periods

Incident Reporting (`lib/models/incident_report.dart`)
- Private incident logging (no public visibility)
- Neutral language (Environment Concern, Communication Issue, Agreement Discrepancy)
- Auto-escalation for critical incidents
- Used for resolution logic only

Communication Logs (`lib/models/communication_log.dart`)
- Booking-scoped messaging threads
- Read receipts and timestamps
- No deletion (marked but preserved)
- Silence periods logged for audit

Reliability Index (`lib/models/reliability_index.dart`)
- Private, non-punitive metrics
- Completion rate, on-time rate, response rate
- **Never public** — no badges or labels
- Used for internal context only


Legal & Compliance
------------------

Privacy Policy (`lib/screens/privacy_policy_page.dart`)
- Global compliance: GDPR (Europe), CCPA (California), POPIA (South Africa)
- Data collection, use, and protection explained
- Regional user rights section
- International data transfer safeguards

Terms of Service (`lib/screens/terms_of_service_page.dart`)
- Dynamic jurisdiction based on user's region
- Multi-currency payment terms
- Cancellation and refund policies
- Artist and client obligations

FAQ & Help (`lib/screens/faq_page.dart`)
- 4 tabs: FAQ, About Gearsh, Privacy summary, Terms summary
- Getting Started, Booking Artists, For Artists, Cancellations, Safety sections
- The Gearsh story and mission
- Global presence information


Important Files and Locations
-----------------------------
- `lib/main.dart` — App initialisation, Firebase init, Crashlytics setup, global config init.
- `lib/gearsh_app.dart` — Root app widget, theme binding, custom scroll behaviour.
- `lib/routes/app_router.dart` — GoRouter configuration with custom page transitions.
- `lib/features/discover/discover_page.dart` — The primary discovery UI (hero, search, featured, categories, sections).
- `lib/features/cart/cart_page.dart` — Cart UI.
- `lib/features/cart/cart_checkout_page.dart` — Checkout and payment initiation.
- `lib/screens/faq_page.dart` — FAQ, About, Privacy, Terms tabs.
- `lib/screens/privacy_policy_page.dart` — Full privacy policy.
- `lib/screens/terms_of_service_page.dart` — Full terms of service.
- `lib/providers/cart_provider.dart` — Cart state and Notifier provider.
- `lib/providers/global_config_providers.dart` — Region and currency providers.
- `lib/providers/selection_provider.dart` — Selected artist id provider and helpers.
- `lib/services/global_config_service.dart` — Global configuration (regions, currencies, exchange rates).
- `lib/services/booking_infrastructure_service.dart` — Central booking orchestration.
- `lib/widgets/gearsh_search_bar.dart` — App-wide search bar.
- `lib/widgets/bottom_nav_bar.dart` — Bottom navigation with smooth animations.
- `lib/widgets/gearsh_background.dart` — Themed background wrapper.
- `lib/widgets/region_selector.dart` — Region selection UI.
- `lib/widgets/price_display.dart` — Currency-aware price widgets.
- `lib/data/gearsh_artists.dart` — Seed data for artists (images, categories, services).


Data Models (high level)
------------------------
- `GearshArtist` (`lib/data/gearsh_artists.dart`) — fields include `id`, `name`, `image`, `category`, `subcategories`, `location`, `countryCode`, `currencyCode`, `isVerified`, `isAvailable`, `rating`, list of `services`.
- `CartItem` — represents a selected service for booking. Tracks artist id, service id, price, date/time, location, and notes.
- `BookingAgreement` (`lib/models/booking_agreement.dart`) — immutable booking contract with performance details, financial terms, rider.
- `EscrowPayment` (`lib/models/escrow_payment.dart`) — conditional payment hold with release conditions.
- `BookingLifecycle` (`lib/models/booking_lifecycle.dart`) — time-stamped status tracking.
- `IncidentReport` (`lib/models/incident_report.dart`) — private incident logging.
- `CommunicationMessage` (`lib/models/communication_log.dart`) — booking-scoped messages.
- `ReliabilityIndex` (`lib/models/reliability_index.dart`) — private reliability metrics.


Providers and Notifiers
-----------------------

### Authentication State
- `authStateProvider` (`lib/providers/auth_state.dart`) — Central auth state with `AuthStateNotifier`:
  - `AuthStatus` enum (initial, loading, authenticated, unauthenticated, error)
  - Sign up, sign in, sign out methods
  - Firebase auth state sync
- `currentUserProvider` — Current `GearshUser` or null
- `isAuthenticatedProvider` — Boolean auth check
- `authLoadingProvider` — Loading state for auth operations
- `authErrorProvider` — Current auth error if any
- `userRoleProvider` — Current user role (client, artist, fan, guest)
- `isArtistProvider` / `isClientProvider` — Role checks

### Cart & Booking
- `CartNotifier` (`lib/providers/cart_provider.dart`) — manages `CartState` and exposes add/remove/clear/update operations.
- `cartItemCountProvider` — Item count for badge display
- `cartTotalProvider` — Total price calculation

### Search & Discovery
- `searchQueryProvider` (`lib/features/discover/discover_page.dart`) — Notifier used by the discover page.
- `selectedArtistIdProvider` — used to track and navigate to selected artist profiles.
- `searchFiltersProvider` (`lib/providers/search_provider.dart`) — search filters state.

### Global Config
- `globalConfigProvider` (`lib/providers/global_config_providers.dart`) — access to global config service.
- `currentRegionProvider` — current user's region.


Services
--------

### Core API Services (Production-Grade)
- `GearshApiClient` (`lib/services/api_client.dart`) — Production HTTP client with:
  - Automatic retry logic with exponential backoff
  - Request/response interceptors
  - Request deduplication
  - Configurable timeouts
  - Auth token management
  
- `AuthApiService` (`lib/services/auth_api.dart`) — Complete authentication:
  - Firebase Auth integration
  - Email/password sign up & sign in
  - Google Sign-In
  - Backend sync for user data
  - Token refresh
  - Account deletion
  
- `BookingApiService` (`lib/services/booking_api.dart`) — Booking management:
  - Create/update/cancel bookings
  - Status lifecycle (pending → confirmed → completed)
  - Booking statistics
  - Review submission
  
- `ArtistApiService` (`lib/services/artist_api.dart`) — Artist operations:
  - Search with filters (category, location, rating, price)
  - Pagination support
  - Save/unsave artists
  - Artist reviews

### Error Handling
- `GearshException` (`lib/services/error_handling.dart`) — Typed exceptions:
  - `NetworkException` — connection issues
  - `TimeoutException` — request timeouts
  - `AuthException` — authentication errors
  - `ValidationException` — input validation
  - `ServerException` — backend errors
  - `RateLimitException` — rate limiting
  - `NotFoundException` — resource not found
  
- `ErrorHandler` — Utility for parsing errors and logging

### Infrastructure Services
- `GlobalConfigService` (`lib/services/global_config_service.dart`) — region management, currency conversion, payment providers.
- `BookingInfrastructureService` (`lib/services/booking_infrastructure_service.dart`) — central orchestration for booking lifecycle.
- `BookingAgreementService` (`lib/services/booking_agreement_service.dart`) — agreement creation, signing, amendments.
- `EscrowService` (`lib/services/escrow_service.dart`) — escrow funding, conditional releases, refunds.
- `BookingLifecycleService` (`lib/services/booking_lifecycle_service.dart`) — status tracking, check-in, completion.
- `IncidentReportService` (`lib/services/incident_report_service.dart`) — private incident submission.
- `CommunicationLogService` (`lib/services/communication_log_service.dart`) — messaging threads, read receipts.
- `ReliabilityIndexService` (`lib/services/reliability_index_service.dart`) — private reliability tracking.
- `PayfastService` (`lib/services/payfast_service.dart`) — PayFast payment integration.
- `UserRoleService` (`lib/services/user_role_service.dart`) — user role management (Client, Artist, Fan).


UI/UX Notes
-----------
- Circular artist avatars across the Discover page are intentionally the same size to give consistent visual rhythm.
- The discover page uses a compact search bar that appears on scroll and an expanded active search bar when searching.
- Categories use rounded tiles with a two-color gradient accent.


Platform / Build Notes
----------------------
Android
- The Android Gradle Plugin was updated to 8.9.1 and Gradle wrapper to 8.11.1 in this project to satisfy newer AndroidX dependency requirements (androidx.core 1.17.0, androidx.browser 1.9.0).
- Gradle properties include memory tuning and Kotlin daemon settings to prevent Kotlin daemon termination.
- If you see "Build failed due to use of deleted Android v1 embedding" — regenerate platform files or ensure your `MainActivity` uses the v2 embedding (the project ships with `MainActivity.kt` extending `FlutterActivity` and `flutterEmbedding` meta-data set to "2"). If you previously had old embedding code, run `flutter create . --platforms android` to refresh Android files (this project has had that run).

iOS
- Standard Flutter iOS project files reside in `ios/`. Ensure you open the workspace in Xcode and update signing when preparing a release.


Troubleshooting & Known Issues
-----------------------------
- withOpacity deprecation warnings: the codebase uses `Color.withOpacity()` in a few places. This currently issues a deprecation notice in recent Dart/Flutter releases — replace with `withValues()` if needed.
- Android AGP mismatch: If you encounter AAR metadata errors about AGP version, ensure `android/build.gradle` and `gradle-wrapper.properties` are aligned to AGP 8.9.1 and Gradle 8.11.1.
- v1 embedding error: If you see a runtime error referencing the deleted Android v1 embedding, regenerate Android project files with `flutter create . --platforms android` and confirm `MainActivity` extends `FlutterActivity` (v2 embedding).


Testing
-------
- Unit tests: Add unit tests under `test/`.
- Widget tests: Add widget tests under `test/widgets/` or similar.
- Integration tests: Use `integration_test/` for end-to-end flows.

Run tests with:
```bash
flutter test
```


Contributing
------------
Contributions are welcome. Suggested workflow:
1. Create a new branch for your change.
2. Write or update unit and widget tests for new behavior.
3. Ensure `flutter format` and `flutter analyze` pass.
4. Open a PR with a clear description and testing steps.


Changelog (high level)
----------------------

### December 2025
- **Premium UI Components**: Uber/Airbnb quality components with haptic feedback
  - `PremiumButton`: Animated button with scale effect and haptics
  - `PremiumCard`: Glassmorphism cards with subtle animations
  - `PremiumTextField`: Focus-aware text fields with shadows
  - `SkeletonLoader`: Shimmer loading placeholders
  - `AnimatedSuccessCheck`: Animated checkmark for success states
  - `AnimatedCounter`: Smooth number transitions
  - `GearshToast`: Custom toast notifications
  - `EmptyStateWidget`: Consistent empty state designs
- **Navigation Overhaul**: Custom page transitions (fade, slide, scale) for ultra-smooth navigation
- **Swipe Right to Go Back**: Edge swipe gesture from left side to navigate back with visual feedback
- **Scroll Behaviour**: Custom `GearshScrollBehavior` with bouncing physics
- **Bottom Nav Enhancement**: Smoother animations, gradient active state, faster response
- **FAQ Page**: 4-tab help system with About Gearsh, Privacy, Terms summaries
- **Privacy Policy**: Updated for global compliance (GDPR, CCPA, POPIA)
- **Terms of Service**: Dynamic jurisdiction, multi-currency terms
- **Booking Infrastructure**: Full dispute prevention system
  - Booking agreements with digital signatures
  - Escrow payments with conditional release
  - Lifecycle tracking (Scheduled → Completed)
  - Private incident reporting
  - Communication logs with read receipts
  - Reliability index (private, non-punitive)
- **Global Support**: 20+ countries, 15+ currencies, region-specific payment providers
- **UK English**: Changed all language to British English (colour, centre, etc.)
- **Filter System**: Location, rating, and price filters on search
- **Artist Dashboard**: Verification and dispute handling

### Earlier Updates
- Migrated cart state to Riverpod Notifier pattern (3.x)
- Added multi-artist cart and checkout flow
- Upgraded Android Gradle Plugin and Gradle wrapper for compatibility with newer AndroidX
- Regenerated Android files to fix embedding issues


Contact
-------
For questions about the codebase, reach out to the repository owner or project maintainer listed in the repo.


Appendix — Useful commands
--------------------------
- Install dependencies: `flutter pub get`
- Run app: `flutter run`
- Build Android APK: `flutter build apk --release`
- Run analyzer: `flutter analyze`
- Run tests: `flutter test`


---
*Last Updated: December 29, 2025*

