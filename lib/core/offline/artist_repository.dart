// Gearsh Artist Repository - Offline First
// Reads from local cache first, syncs with backend in background

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gearsh_app/core/offline/local_database.dart';
import 'package:gearsh_app/core/offline/connectivity_service.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:gearsh_app/services/artist_api.dart';
import 'package:gearsh_app/services/api_client.dart';
import 'package:gearsh_app/services/error_handling.dart';

/// Provider for offline-first artist repository
final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return ArtistRepository(ref);
});

/// Provider for featured artists (offline-first)
final featuredArtistsProvider = FutureProvider<List<GearshArtist>>((ref) async {
  final repository = ref.watch(artistRepositoryProvider);
  final result = await repository.getFeaturedArtists();
  return result.getOrElse([]);
});

/// Provider for artist by ID (offline-first)
final artistByIdProvider = FutureProvider.family<GearshArtist?, String>((ref, id) async {
  final repository = ref.watch(artistRepositoryProvider);
  final result = await repository.getArtistById(id);
  return result.data;
});

/// Provider for artist search (offline-first)
final artistSearchProvider = FutureProvider.family<ArtistSearchResult, ArtistSearchParams>((ref, params) async {
  final repository = ref.watch(artistRepositoryProvider);
  final result = await repository.searchArtists(
    query: params.query,
    filters: params.filters,
  );
  return result.getOrElse(ArtistSearchResult.empty());
});

/// Search parameters for provider
class ArtistSearchParams {
  final String? query;
  final ArtistFilters filters;

  ArtistSearchParams({this.query, this.filters = const ArtistFilters()});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtistSearchParams &&
        other.query == query &&
        other.filters.category == filters.category &&
        other.filters.location == filters.location;
  }

  @override
  int get hashCode => query.hashCode ^ filters.category.hashCode;
}

/// Offline-first artist repository
class ArtistRepository {
  final Ref _ref;
  final LocalDatabase _db = LocalDatabase.instance;

  // Cache duration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration searchCacheExpiry = Duration(minutes: 30);

  ArtistRepository(this._ref);

  bool get isOnline => _ref.read(isOnlineProvider);

  /// Get all featured artists - cache first, then background sync
  Future<ApiResult<List<GearshArtist>>> getFeaturedArtists() async {
    try {
      // 1. Try to get from local cache first
      final cachedArtists = await _getCachedArtists();

      if (cachedArtists.isNotEmpty) {
        debugPrint('📦 Loaded ${cachedArtists.length} artists from cache');

        // 2. Trigger background sync if online
        if (isOnline) {
          _syncArtistsInBackground();
        }

        return ApiResult.success(cachedArtists);
      }

      // 3. Cache empty - load from embedded data and cache it
      final embeddedArtists = gearshArtists;
      await _cacheArtists(embeddedArtists);

      // 4. If online, also try to fetch fresh data
      if (isOnline) {
        _syncArtistsInBackground();
      }

      return ApiResult.success(embeddedArtists);

    } catch (e) {
      debugPrint('Error getting featured artists: $e');
      // Fallback to embedded data
      return ApiResult.success(gearshArtists);
    }
  }

  /// Get artist by ID - cache first
  Future<ApiResult<GearshArtist?>> getArtistById(String id) async {
    try {
      // 1. Check local cache
      final cachedArtist = await _getCachedArtistById(id);
      if (cachedArtist != null) {
        debugPrint('📦 Loaded artist $id from cache');

        // Background refresh if online
        if (isOnline) {
          _refreshArtistInBackground(id);
        }

        return ApiResult.success(cachedArtist);
      }

      // 2. Check embedded data
      final embeddedArtist = gearshArtists.where((a) => a.id == id).firstOrNull;
      if (embeddedArtist != null) {
        await _cacheArtist(embeddedArtist);
        return ApiResult.success(embeddedArtist);
      }

      // 3. If online, fetch from API
      if (isOnline) {
        return await _fetchArtistFromApi(id);
      }

      return ApiResult.failure(
        const GearshException(
          message: 'Artist not found in offline cache',
          type: ErrorType.notFound,
        ),
      );

    } catch (e) {
      return ApiResult.failure(GearshException(message: e.toString()));
    }
  }

  /// Search artists - cache first with smart caching
  Future<ApiResult<ArtistSearchResult>> searchArtists({
    String? query,
    ArtistFilters filters = const ArtistFilters(),
  }) async {
    final cacheKey = _generateSearchCacheKey(query, filters);

    try {
      // 1. Check search cache
      final cachedResult = await _getCachedSearchResult(cacheKey);
      if (cachedResult != null) {
        debugPrint('📦 Loaded search results from cache: $cacheKey');

        // Background refresh if online and cache is stale
        if (isOnline) {
          _refreshSearchInBackground(query, filters, cacheKey);
        }

        return ApiResult.success(cachedResult);
      }

      // 2. Perform local search on cached/embedded data
      final localResult = await _performLocalSearch(query, filters);

      // 3. Cache the search result
      await _cacheSearchResult(cacheKey, localResult);

      // 4. If online, trigger background refresh
      if (isOnline) {
        _refreshSearchInBackground(query, filters, cacheKey);
      }

      return ApiResult.success(localResult);

    } catch (e) {
      debugPrint('Search error: $e');
      // Fallback to basic local search
      final fallbackResult = await _performLocalSearch(query, filters);
      return ApiResult.success(fallbackResult);
    }
  }

  /// Get artists by category
  Future<ApiResult<List<GearshArtist>>> getArtistsByCategory(String category) async {
    final result = await searchArtists(
      filters: ArtistFilters(category: category),
    );
    return result.map((r) => r.artists);
  }

  /// Get recently viewed artists (from local storage)
  Future<List<GearshArtist>> getRecentlyViewed() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'artists',
        orderBy: 'updated_at DESC',
        limit: 10,
      );

      return results.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return _artistFromJson(data);
      }).toList();

    } catch (e) {
      debugPrint('Error getting recently viewed: $e');
      return [];
    }
  }

  /// Mark artist as viewed (updates cache timestamp)
  Future<void> markAsViewed(String artistId) async {
    try {
      final artist = await getArtistById(artistId);
      if (artist.data != null) {
        await _cacheArtist(artist.data!);
      }
    } catch (e) {
      debugPrint('Error marking artist as viewed: $e');
    }
  }

  // ==================== PRIVATE CACHE METHODS ====================

  /// Get all cached artists
  Future<List<GearshArtist>> _getCachedArtists() async {
    try {
      final db = await _db.database;
      final results = await db.query('artists');

      return results.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return _artistFromJson(data);
      }).toList();

    } catch (e) {
      debugPrint('Error reading artist cache: $e');
      return [];
    }
  }

  /// Get cached artist by ID
  Future<GearshArtist?> _getCachedArtistById(String id) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'artists',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final data = jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
      return _artistFromJson(data);

    } catch (e) {
      debugPrint('Error reading artist from cache: $e');
      return null;
    }
  }

  /// Cache a single artist
  Future<void> _cacheArtist(GearshArtist artist) async {
    try {
      final db = await _db.database;
      await db.insert(
        'artists',
        {
          'id': artist.id,
          'data': jsonEncode(_artistToJson(artist)),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error caching artist: $e');
    }
  }

  /// Cache multiple artists
  Future<void> _cacheArtists(List<GearshArtist> artists) async {
    try {
      final db = await _db.database;
      final batch = db.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final artist in artists) {
        batch.insert(
          'artists',
          {
            'id': artist.id,
            'data': jsonEncode(_artistToJson(artist)),
            'updated_at': now,
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      debugPrint('📥 Cached ${artists.length} artists');

    } catch (e) {
      debugPrint('Error caching artists: $e');
    }
  }

  /// Get cached search result
  Future<ArtistSearchResult?> _getCachedSearchResult(String cacheKey) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final results = await db.query(
        'artist_search_cache',
        where: 'cache_key = ? AND expires_at > ?',
        whereArgs: [cacheKey, now],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final data = jsonDecode(results.first['data'] as String) as List;
      final artists = data.map((a) => _artistFromJson(a as Map<String, dynamic>)).toList();

      return ArtistSearchResult(
        artists: artists,
        totalCount: results.first['total_count'] as int,
        page: 1,
        totalPages: 1,
        hasMore: false,
      );

    } catch (e) {
      debugPrint('Error reading search cache: $e');
      return null;
    }
  }

  /// Cache search result
  Future<void> _cacheSearchResult(String cacheKey, ArtistSearchResult result) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();

      await db.insert(
        'artist_search_cache',
        {
          'cache_key': cacheKey,
          'data': jsonEncode(result.artists.map(_artistToJson).toList()),
          'total_count': result.totalCount,
          'updated_at': now.millisecondsSinceEpoch,
          'expires_at': now.add(searchCacheExpiry).millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

    } catch (e) {
      debugPrint('Error caching search result: $e');
    }
  }

  /// Generate cache key for search
  String _generateSearchCacheKey(String? query, ArtistFilters filters) {
    final parts = <String>[];
    if (query != null && query.isNotEmpty) parts.add('q=$query');
    if (filters.category != null) parts.add('cat=${filters.category}');
    if (filters.location != null) parts.add('loc=${filters.location}');
    if (filters.minRating != null) parts.add('rating=${filters.minRating}');
    if (filters.sortBy != null) parts.add('sort=${filters.sortBy}');
    parts.add('page=${filters.page}');
    return parts.join('&');
  }

  // ==================== BACKGROUND SYNC METHODS ====================

  /// Sync artists in background
  void _syncArtistsInBackground() {
    // Don't await - run in background
    Future(() async {
      try {
        // In a real app, this would fetch from the API
        // For now, we use embedded data as the source of truth
        final artists = gearshArtists;
        await _cacheArtists(artists);
        debugPrint('🔄 Background artist sync complete');
      } catch (e) {
        debugPrint('Background sync error: $e');
      }
    });
  }

  /// Refresh single artist in background
  void _refreshArtistInBackground(String id) {
    Future(() async {
      try {
        // Fetch from API when available
        // For now, update from embedded data
        final artist = gearshArtists.where((a) => a.id == id).firstOrNull;
        if (artist != null) {
          await _cacheArtist(artist);
        }
      } catch (e) {
        debugPrint('Background refresh error: $e');
      }
    });
  }

  /// Refresh search in background
  void _refreshSearchInBackground(String? query, ArtistFilters filters, String cacheKey) {
    Future(() async {
      try {
        // Perform fresh search
        final result = await _performLocalSearch(query, filters);
        await _cacheSearchResult(cacheKey, result);
        debugPrint('🔄 Background search refresh complete: $cacheKey');
      } catch (e) {
        debugPrint('Background search refresh error: $e');
      }
    });
  }

  /// Fetch artist from API
  Future<ApiResult<GearshArtist?>> _fetchArtistFromApi(String id) async {
    // TODO: Implement actual API call when backend is ready
    // final apiClient = _ref.read(apiClientProvider);
    // final response = await apiClient.get('/artists/$id');

    // For now, return from embedded data
    final artist = gearshArtists.where((a) => a.id == id).firstOrNull;
    if (artist != null) {
      await _cacheArtist(artist);
      return ApiResult.success(artist);
    }
    return ApiResult.failure(
      const GearshException(message: 'Artist not found', type: ErrorType.notFound),
    );
  }

  /// Perform local search
  Future<ArtistSearchResult> _performLocalSearch(
    String? query,
    ArtistFilters filters,
  ) async {
    // First try cached artists, fallback to embedded
    var artists = await _getCachedArtists();
    if (artists.isEmpty) {
      artists = gearshArtists;
    }

    // Apply search query
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      artists = artists.where((artist) {
        return artist.name.toLowerCase().contains(lowerQuery) ||
            artist.category.toLowerCase().contains(lowerQuery) ||
            artist.subcategories.any((s) => s.toLowerCase().contains(lowerQuery)) ||
            artist.location.toLowerCase().contains(lowerQuery) ||
            artist.username.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply filters
    if (filters.category != null) {
      artists = artists.where((a) =>
        a.category.toLowerCase() == filters.category!.toLowerCase() ||
        a.subcategories.any((s) => s.toLowerCase() == filters.category!.toLowerCase())
      ).toList();
    }

    if (filters.location != null) {
      artists = artists.where((a) =>
        a.location.toLowerCase().contains(filters.location!.toLowerCase())
      ).toList();
    }

    if (filters.minRating != null) {
      artists = artists.where((a) => a.rating >= filters.minRating!).toList();
    }

    if (filters.isVerified == true) {
      artists = artists.where((a) => a.isVerified).toList();
    }

    if (filters.isAvailable == true) {
      artists = artists.where((a) => a.isAvailable).toList();
    }

    // Apply sorting
    switch (filters.sortBy) {
      case 'rating':
        artists.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price_low':
        artists.sort((a, b) => a.bookingFee.compareTo(b.bookingFee));
        break;
      case 'price_high':
        artists.sort((a, b) => b.bookingFee.compareTo(a.bookingFee));
        break;
      case 'bookings':
      case 'hours':
        artists.sort((a, b) => b.hoursBooked.compareTo(a.hoursBooked));
        break;
      default:
        artists.sort((a, b) => b.rating.compareTo(a.rating));
    }

    // Pagination
    final totalCount = artists.length;
    final startIndex = (filters.page - 1) * filters.limit;
    final endIndex = (startIndex + filters.limit).clamp(0, artists.length);

    if (startIndex >= artists.length) {
      artists = [];
    } else {
      artists = artists.sublist(startIndex, endIndex);
    }

    return ArtistSearchResult(
      artists: artists,
      totalCount: totalCount,
      page: filters.page,
      totalPages: (totalCount / filters.limit).ceil(),
      hasMore: endIndex < totalCount,
    );
  }

  // ==================== JSON SERIALIZATION ====================

  Map<String, dynamic> _artistToJson(GearshArtist artist) {
    return {
      'id': artist.id,
      'name': artist.name,
      'username': artist.username,
      'category': artist.category,
      'subcategories': artist.subcategories,
      'location': artist.location,
      'countryCode': artist.countryCode,
      'currencyCode': artist.currencyCode,
      'rating': artist.rating,
      'reviewCount': artist.reviewCount,
      'hoursBooked': artist.hoursBooked,
      'responseTime': artist.responseTime,
      'image': artist.image,
      'isVerified': artist.isVerified,
      'isAvailable': artist.isAvailable,
      'bio': artist.bio,
      'bookingFee': artist.bookingFee,
      'originalBookingFee': artist.originalBookingFee,
      'discountPercent': artist.discountPercent,
      'bookingFeeUSD': artist.bookingFeeUSD,
      'highlights': artist.highlights,
      'services': artist.services,
      'discography': artist.discography,
      'upcomingGigs': artist.upcomingGigs,
      'merch': artist.merch,
      'availableWorldwide': artist.availableWorldwide,
    };
  }

  GearshArtist _artistFromJson(Map<String, dynamic> json) {
    return GearshArtist(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String? ?? '',
      category: json['category'] as String,
      subcategories: List<String>.from(json['subcategories'] ?? []),
      location: json['location'] as String,
      countryCode: json['countryCode'] as String? ?? 'ZA',
      currencyCode: json['currencyCode'] as String? ?? 'ZAR',
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      hoursBooked: json['hoursBooked'] as int? ?? 0,
      responseTime: json['responseTime'] as String? ?? 'Within 24 hours',
      image: json['image'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      bio: json['bio'] as String? ?? '',
      bookingFee: json['bookingFee'] as int? ?? 0,
      originalBookingFee: json['originalBookingFee'] as int?,
      discountPercent: json['discountPercent'] as int?,
      bookingFeeUSD: (json['bookingFeeUSD'] as num?)?.toDouble(),
      highlights: List<String>.from(json['highlights'] ?? []),
      services: List<Map<String, dynamic>>.from(json['services'] ?? []),
      discography: List<Map<String, dynamic>>.from(json['discography'] ?? []),
      upcomingGigs: List<Map<String, dynamic>>.from(json['upcomingGigs'] ?? []),
      merch: List<Map<String, dynamic>>.from(json['merch'] ?? []),
      availableWorldwide: json['availableWorldwide'] as bool? ?? false,
    );
  }

  /// Clear all artist cache
  Future<void> clearCache() async {
    final db = await _db.database;
    await db.delete('artists');
    await db.delete('artist_search_cache');
    debugPrint('🗑️ Artist cache cleared');
  }
}

