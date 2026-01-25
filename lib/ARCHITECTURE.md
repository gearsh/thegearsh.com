// Gearsh App - Clean Architecture Structure
// 
// This file documents the clean architecture pattern used in Gearsh.
//
// ============================================================================
// ARCHITECTURE OVERVIEW
// ============================================================================
//
// lib/
// ├── core/                     # Core utilities and shared code
// │   ├── constants/            # App-wide constants
// │   │   └── app_constants.dart
// │   ├── errors/               # Custom exceptions and failures
// │   │   ├── exceptions.dart
// │   │   └── failures.dart
// │   ├── responsive.dart       # Responsive utilities
// │   └── core.dart             # Barrel export file
// │
// ├── domain/                   # Business Logic Layer (Pure Dart)
// │   ├── entities/             # Business entities (immutable)
// │   │   ├── artist.dart       # Artist entity
// │   │   ├── booking.dart      # Booking entity
// │   │   ├── mastery.dart      # Mastery system
// │   │   ├── service.dart      # Service entity
// │   │   └── user.dart         # User entity
// │   ├── repositories/         # Repository interfaces (contracts)
// │   │   └── artist_repository.dart
// │   ├── usecases/             # Use cases (single responsibility)
// │   │   └── artist_usecases.dart
// │   └── domain.dart           # Barrel export file
// │
// ├── data/                     # Data Layer
// │   ├── datasources/          # Remote and local data sources
// │   │   ├── local/
// │   │   │   └── artist_local_datasource.dart
// │   │   └── remote/           # API data sources (future)
// │   ├── repositories/         # Repository implementations
// │   │   └── artist_repository_impl.dart
// │   └── gearsh_artists.dart   # Local artist data
// │
// ├── presentation/             # Presentation Layer (Flutter)
// │   └── (features, pages, widgets are in existing folders)
// │
// ├── services/                 # External services
// │   ├── auth_service.dart
// │   ├── firebase_auth_service.dart
// │   ├── twitter_api_service.dart
// │   └── ...
// │
// └── injection.dart            # Dependency injection (Riverpod providers)
//
// ============================================================================
// DEPENDENCY RULE
// ============================================================================
//
// Dependencies flow inward:
//   Presentation → Domain ← Data
//
// - Domain layer has NO dependencies on other layers
// - Data layer depends on Domain (implements interfaces)
// - Presentation depends on Domain (uses interfaces)
//
// ============================================================================
// SOLID PRINCIPLES APPLIED
// ============================================================================
//
// S - Single Responsibility:
//   - Each entity has one job (Artist, Booking, User, Service)
//   - Each use case does one thing (GetArtistById, SearchArtists)
//   - Each repository handles one domain (artists, bookings)
//
// O - Open/Closed:
//   - Entities can be extended via copyWith
//   - Repository interfaces allow new implementations
//   - Use cases can be added without modifying existing ones
//
// L - Liskov Substitution:
//   - ArtistRepositoryImpl can replace IArtistRepository
//   - Any data source implementing the interface works
//
// I - Interface Segregation:
//   - IArtistRepository only has artist methods
//   - Separate interfaces for auth, bookings, etc.
//
// D - Dependency Inversion:
//   - Domain defines IArtistRepository interface
//   - Data layer implements it
//   - Presentation depends on the abstraction
//
// ============================================================================
// USAGE EXAMPLES
// ============================================================================
//
// 1. Import the domain layer:
//    import 'package:gearsh_app/domain/domain.dart';
//
// 2. Use providers in widgets:
//    final artists = ref.watch(allArtistsProvider);
//    final artist = ref.watch(artistByIdProvider(artistId));
//
// 3. Use the Result type:
//    final result = await repository.getArtistById(id);
//    result.onSuccess((artist) => print(artist.name));
//    result.onFailure((error) => print(error));
//
// ============================================================================
// ADDING NEW FEATURES
// ============================================================================
//
// 1. Create entity in domain/entities/
// 2. Create repository interface in domain/repositories/
// 3. Create use cases in domain/usecases/
// 4. Implement repository in data/repositories/
// 5. Add data source in data/datasources/
// 6. Register providers in injection.dart
//
