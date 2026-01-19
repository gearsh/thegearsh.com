// Gearsh Artist API Service
// Complete artist management with proper error handling

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/services/api_client.dart';
import 'package:gearsh_app/services/error_handling.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';

/// Provider for artist API service
final artistApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ArtistApiService(apiClient);
});

/// Artist search filters
class ArtistFilters {
  final String? category;
  final String? location;
  final double? minRating;
  final double? maxPrice;
  final double? minPrice;
  final bool? isVerified;
  final bool? isAvailable;
  final String? sortBy; // 'rating', 'price_low', 'price_high', 'bookings'
  final int page;
  final int limit;

  const ArtistFilters({
    this.category,
    this.location,
    this.minRating,
    this.maxPrice,
    this.minPrice,
    this.isVerified,
    this.isAvailable,
    this.sortBy,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null) params['category'] = category!;
    if (location != null) params['location'] = location!;
    if (minRating != null) params['min_rating'] = minRating.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (isVerified != null) params['is_verified'] = isVerified.toString();
    if (isAvailable != null) params['is_available'] = isAvailable.toString();
    if (sortBy != null) params['sort_by'] = sortBy!;

    return params;
  }

  ArtistFilters copyWith({
    String? category,
    String? location,
    double? minRating,
    double? maxPrice,
    double? minPrice,
    bool? isVerified,
    bool? isAvailable,
    String? sortBy,
    int? page,
    int? limit,
  }) {
    return ArtistFilters(
      category: category ?? this.category,
      location: location ?? this.location,
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      minPrice: minPrice ?? this.minPrice,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Artist search result
class ArtistSearchResult {
  final List<GearshArtist> artists;
  final int totalCount;
  final int page;
  final int totalPages;
  final bool hasMore;

  const ArtistSearchResult({
    required this.artists,
    required this.totalCount,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });

  factory ArtistSearchResult.fromJson(Map<String, dynamic> json, List<GearshArtist> artists) {
    final totalCount = json['total_count'] as int? ?? artists.length;
    final page = json['page'] as int? ?? 1;
    final limit = json['limit'] as int? ?? 20;
    final totalPages = (totalCount / limit).ceil();

    return ArtistSearchResult(
      artists: artists,
      totalCount: totalCount,
      page: page,
      totalPages: totalPages,
      hasMore: page < totalPages,
    );
  }

  factory ArtistSearchResult.empty() => const ArtistSearchResult(
    artists: [],
    totalCount: 0,
    page: 1,
    totalPages: 0,
    hasMore: false,
  );
}

/// Artist review model
class ArtistReview {
  final String id;
  final String artistId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerImage;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? bookingId;

  const ArtistReview({
    required this.id,
    required this.artistId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImage,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.bookingId,
  });

  factory ArtistReview.fromJson(Map<String, dynamic> json) {
    return ArtistReview(
      id: json['id'] as String,
      artistId: json['artist_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      reviewerName: json['reviewer_name'] as String? ?? 'Anonymous',
      reviewerImage: json['reviewer_image'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      bookingId: json['booking_id'] as String?,
    );
  }
}

/// Artist API Service
class ArtistApiService {
  final GearshApiClient _apiClient;

  ArtistApiService(this._apiClient);

  /// Search artists with filters
  Future<ApiResult<ArtistSearchResult>> searchArtists({
    String? query,
    ArtistFilters filters = const ArtistFilters(),
  }) async {
    final queryParams = filters.toQueryParams();
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }

    // Use local data with filtering
    return _searchLocalArtists(query, filters);
  }

  /// Search local artists (fallback when API is not available)
  Future<ApiResult<ArtistSearchResult>> _searchLocalArtists(
    String? query,
    ArtistFilters filters,
  ) async {
    try {
      var artists = List<GearshArtist>.from(gearshArtists);

      // Apply search query
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        artists = artists.where((artist) {
          return artist.name.toLowerCase().contains(lowerQuery) ||
              artist.category.toLowerCase().contains(lowerQuery) ||
              artist.subcategories.any((s) => s.toLowerCase().contains(lowerQuery)) ||
              artist.location.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      // Apply category filter
      if (filters.category != null) {
        artists = artists.where((a) =>
          a.category.toLowerCase() == filters.category!.toLowerCase() ||
          a.subcategories.any((s) => s.toLowerCase() == filters.category!.toLowerCase())
        ).toList();
      }

      // Apply location filter
      if (filters.location != null) {
        artists = artists.where((a) =>
          a.location.toLowerCase().contains(filters.location!.toLowerCase())
        ).toList();
      }

      // Apply rating filter
      if (filters.minRating != null) {
        artists = artists.where((a) => a.rating >= filters.minRating!).toList();
      }

      // Apply price filters
      if (filters.minPrice != null || filters.maxPrice != null) {
        artists = artists.where((artist) {
          if (artist.services.isEmpty) return false;
          final minServicePrice = artist.services
              .map((s) => (s['price'] as num).toDouble())
              .reduce((a, b) => a < b ? a : b);

          if (filters.minPrice != null && minServicePrice < filters.minPrice!) return false;
          if (filters.maxPrice != null && minServicePrice > filters.maxPrice!) return false;
          return true;
        }).toList();
      }

      // Apply verified filter
      if (filters.isVerified == true) {
        artists = artists.where((a) => a.isVerified).toList();
      }

      // Apply availability filter
      if (filters.isAvailable == true) {
        artists = artists.where((a) => a.isAvailable).toList();
      }

      // Apply sorting
      switch (filters.sortBy) {
        case 'rating':
          artists.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'price_low':
          artists.sort((a, b) {
            final aPrice = a.services.isNotEmpty
                ? (a.services.first['price'] as num).toDouble()
                : double.infinity;
            final bPrice = b.services.isNotEmpty
                ? (b.services.first['price'] as num).toDouble()
                : double.infinity;
            return aPrice.compareTo(bPrice);
          });
          break;
        case 'price_high':
          artists.sort((a, b) {
            final aPrice = a.services.isNotEmpty
                ? (a.services.first['price'] as num).toDouble()
                : 0;
            final bPrice = b.services.isNotEmpty
                ? (b.services.first['price'] as num).toDouble()
                : 0;
            return bPrice.compareTo(aPrice);
          });
          break;
        case 'bookings':
          artists.sort((a, b) => b.hoursBooked.compareTo(a.hoursBooked));
          break;
        default:
          // Default: sort by rating
          artists.sort((a, b) => b.rating.compareTo(a.rating));
      }

      // Apply pagination
      final totalCount = artists.length;
      final startIndex = (filters.page - 1) * filters.limit;
      final endIndex = startIndex + filters.limit;

      if (startIndex >= artists.length) {
        artists = [];
      } else {
        artists = artists.sublist(
          startIndex,
          endIndex > artists.length ? artists.length : endIndex,
        );
      }

      final totalPages = (totalCount / filters.limit).ceil();

      return ApiResult.success(ArtistSearchResult(
        artists: artists,
        totalCount: totalCount,
        page: filters.page,
        totalPages: totalPages,
        hasMore: filters.page < totalPages,
      ));
    } catch (e) {
      return ApiResult.failure(
        GearshException(message: 'Failed to search artists: $e'),
      );
    }
  }

  /// Get artist by ID
  Future<ApiResult<GearshArtist>> getArtist(String artistId) async {
    // Try local data first
    final artist = getArtistById(artistId);
    if (artist != null) {
      return ApiResult.success(artist);
    }

    // Try API
    return _apiClient.get<GearshArtist>(
      '/artists/$artistId',
      parser: (data) => _parseArtistFromApi(data as Map<String, dynamic>),
    );
  }

  /// Get featured artists
  Future<ApiResult<List<GearshArtist>>> getFeaturedArtists({int limit = 10}) async {
    // Use local data
    final featured = gearshArtists
        .where((a) => a.isVerified && a.rating >= 4.5)
        .take(limit)
        .toList();

    return ApiResult.success(featured);
  }

  /// Get artists by category
  Future<ApiResult<List<GearshArtist>>> fetchArtistsByCategory(
    String category, {
    int limit = 20,
  }) async {
    final artists = gearshArtists
        .where((a) => a.category.toLowerCase() == category.toLowerCase() ||
            a.subcategories.any((s) => s.toLowerCase() == category.toLowerCase()))
        .take(limit)
        .toList();
    return ApiResult.success(artists);
  }

  /// Get artist reviews
  Future<ApiResult<List<ArtistReview>>> getArtistReviews(
    String artistId, {
    int page = 1,
    int limit = 10,
  }) async {
    return _apiClient.get<List<ArtistReview>>(
      '/artists/$artistId/reviews',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      parser: (data) {
        if (data is List) {
          return data.map((item) => ArtistReview.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  /// Submit artist review
  Future<ApiResult<ArtistReview>> submitReview({
    required String artistId,
    required int rating,
    String? comment,
    String? bookingId,
  }) async {
    return _apiClient.post<ArtistReview>(
      '/artists/$artistId/reviews',
      body: {
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (bookingId != null) 'booking_id': bookingId,
      },
      parser: (data) => ArtistReview.fromJson(data as Map<String, dynamic>),
      config: RequestConfig.authenticated,
    );
  }

  /// Save artist to favourites
  Future<ApiResult<void>> saveArtist(String artistId) async {
    return _apiClient.post<void>(
      '/users/saved-artists',
      body: {'artist_id': artistId},
      parser: (_) {},
      config: RequestConfig.authenticated,
    );
  }

  /// Remove artist from favourites
  Future<ApiResult<void>> unsaveArtist(String artistId) async {
    return _apiClient.delete<void>(
      '/users/saved-artists/$artistId',
      config: RequestConfig.authenticated,
    );
  }

  /// Get saved artists
  Future<ApiResult<List<GearshArtist>>> getSavedArtists() async {
    return _apiClient.get<List<GearshArtist>>(
      '/users/saved-artists',
      parser: (data) {
        if (data is List) {
          return data.map((item) => _parseArtistFromApi(item as Map<String, dynamic>)).toList();
        }
        return [];
      },
      config: RequestConfig.authenticated,
    );
  }

  /// Parse artist from API response
  GearshArtist _parseArtistFromApi(Map<String, dynamic> json) {
    return GearshArtist(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String? ?? '@${(json['name'] as String).toLowerCase().replaceAll(' ', '')}',
      category: json['category'] as String,
      subcategories: List<String>.from(json['subcategories'] ?? []),
      location: json['location'] as String? ?? 'Unknown',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: json['review_count'] as int? ?? 0,
      hoursBooked: json['hours_booked'] as int? ?? json['completed_gigs'] as int? ?? 0,
      responseTime: json['response_time'] as String? ?? '< 1 hour',
      image: json['image'] as String? ?? 'assets/images/placeholder.png',
      isVerified: json['is_verified'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      bio: json['bio'] as String? ?? '',
      bookingFee: json['booking_fee'] as int? ?? 500,
      highlights: List<String>.from(json['highlights'] ?? []),
      services: List<Map<String, dynamic>>.from(json['services'] ?? []),
      discography: List<Map<String, dynamic>>.from(json['discography'] ?? []),
      upcomingGigs: List<Map<String, dynamic>>.from(json['upcoming_gigs'] ?? []),
      merch: List<Map<String, dynamic>>.from(json['merch'] ?? []),
    );
  }
}


