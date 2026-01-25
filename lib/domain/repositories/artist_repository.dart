// Gearsh App - Domain Layer: Artist Repository Interface
// This is the contract that the data layer must implement
// Follows Dependency Inversion Principle - depend on abstractions

import '../entities/artist.dart';

/// Result wrapper for repository operations
/// Follows functional error handling pattern
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(String error) => Result._(error: error, isSuccess: false);

  /// Execute callback on success
  Result<T> onSuccess(void Function(T data) callback) {
    if (isSuccess && data != null) callback(data as T);
    return this;
  }

  /// Execute callback on failure
  Result<T> onFailure(void Function(String error) callback) {
    if (!isSuccess && error != null) callback(error!);
    return this;
  }

  /// Map the result to another type
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return Result.success(mapper(data as T));
    }
    return Result.failure(error ?? 'Unknown error');
  }
}

/// Artist repository interface - contract for data layer
///
/// Follows:
/// - Interface Segregation: Only artist-related operations
/// - Dependency Inversion: Domain defines the interface
abstract class IArtistRepository {
  /// Get all artists
  Future<Result<List<Artist>>> getAllArtists();

  /// Get artist by ID
  Future<Result<Artist>> getArtistById(String id);

  /// Get artist by username
  Future<Result<Artist>> getArtistByUsername(String username);

  /// Search artists by query
  Future<Result<List<Artist>>> searchArtists(String query);

  /// Get artists by category
  Future<Result<List<Artist>>> getArtistsByCategory(String category);

  /// Get artists by location
  Future<Result<List<Artist>>> getArtistsByLocation(String location);

  /// Get featured/trending artists
  Future<Result<List<Artist>>> getFeaturedArtists();

  /// Get available artists (ready to book)
  Future<Result<List<Artist>>> getAvailableArtists();

  /// Get artists sorted by criteria
  Future<Result<List<Artist>>> getArtistsSorted({
    required ArtistSortCriteria criteria,
    bool ascending = true,
  });

  /// Get nearby artists (requires location)
  Future<Result<List<Artist>>> getNearbyArtists({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  });
}

/// Sort criteria for artists
enum ArtistSortCriteria {
  name,
  rating,
  price,
  hoursBooked,
  reviewCount,
}

/// Filter options for artist search
class ArtistFilter {
  final List<String>? categories;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? verifiedOnly;
  final bool? availableOnly;
  final String? location;
  final int? minHoursBooked;

  const ArtistFilter({
    this.categories,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.verifiedOnly,
    this.availableOnly,
    this.location,
    this.minHoursBooked,
  });

  /// Create empty filter
  factory ArtistFilter.empty() => const ArtistFilter();

  /// Check if filter is empty
  bool get isEmpty =>
      categories == null &&
      minPrice == null &&
      maxPrice == null &&
      minRating == null &&
      verifiedOnly == null &&
      availableOnly == null &&
      location == null &&
      minHoursBooked == null;

  /// Copy with modifications
  ArtistFilter copyWith({
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? verifiedOnly,
    bool? availableOnly,
    String? location,
    int? minHoursBooked,
  }) {
    return ArtistFilter(
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      availableOnly: availableOnly ?? this.availableOnly,
      location: location ?? this.location,
      minHoursBooked: minHoursBooked ?? this.minHoursBooked,
    );
  }
}
