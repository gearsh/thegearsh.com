// Gearsh App - Data Layer: Artist Local Data Source
// Provides access to locally stored artist data

import 'package:gearsh_app/domain/entities/artist.dart';
import 'package:gearsh_app/domain/entities/service.dart';
import 'package:gearsh_app/domain/repositories/artist_repository.dart';
import 'package:gearsh_app/data/gearsh_artists.dart' as legacy;

/// Local data source for artists
/// Wraps the legacy gearsh_artists.dart data
///
/// Follows:
/// - Adapter Pattern: Converts legacy data to domain entities
/// - Single Responsibility: Only handles local data access
class ArtistLocalDataSource {
  /// Convert legacy GearshArtist to domain Artist entity
  Artist _convertToArtist(legacy.GearshArtist legacyArtist) {
    return Artist(
      id: legacyArtist.id,
      name: legacyArtist.name,
      username: legacyArtist.username,
      category: legacyArtist.category,
      subcategories: legacyArtist.subcategories,
      location: legacyArtist.location,
      countryCode: legacyArtist.countryCode,
      currencyCode: legacyArtist.currencyCode,
      rating: legacyArtist.rating,
      reviewCount: legacyArtist.reviewCount,
      hoursBooked: legacyArtist.hoursBooked,
      responseTime: legacyArtist.responseTime,
      profileImage: legacyArtist.image,
      coverImage: legacyArtist.coverImage,
      isVerified: legacyArtist.isVerified,
      isAvailable: legacyArtist.isAvailable,
      bio: legacyArtist.bio,
      bookingFee: legacyArtist.bookingFee,
      originalBookingFee: legacyArtist.originalBookingFee,
      discountPercent: legacyArtist.discountPercent,
      bookingFeeUSD: legacyArtist.bookingFeeUSD,
      highlights: legacyArtist.highlights,
      services: _convertServices(legacyArtist.services),
      portfolio: _convertPortfolio(legacyArtist.discography),
      upcomingGigs: _convertGigs(legacyArtist.upcomingGigs),
      availableWorldwide: legacyArtist.availableWorldwide,
    );
  }

  List<Service> _convertServices(List<Map<String, dynamic>> legacyServices) {
    return legacyServices.map((s) => Service.fromJson(s)).toList();
  }

  List<PortfolioItem> _convertPortfolio(List<Map<String, dynamic>> legacyItems) {
    return legacyItems.map((item) => PortfolioItem(
      title: item['title'] as String? ?? '',
      type: item['type'] as String? ?? '',
      year: item['year'] as String? ?? '',
      image: item['image'] as String?,
      description: item['description'] as String?,
    )).toList();
  }

  List<UpcomingGig> _convertGigs(List<Map<String, dynamic>> legacyGigs) {
    return legacyGigs.map((gig) {
      DateTime date;
      try {
        date = DateTime.parse(gig['date'] as String? ?? '');
      } catch (_) {
        date = DateTime.now();
      }
      return UpcomingGig(
        title: gig['title'] as String? ?? '',
        date: date,
        venue: gig['venue'] as String? ?? '',
        type: gig['type'] as String? ?? '',
      );
    }).toList();
  }

  /// Get all artists
  List<Artist> getAllArtists() {
    return legacy.gearshArtists.map(_convertToArtist).toList();
  }

  /// Get artist by ID
  Artist? getArtistById(String id) {
    final legacyArtist = legacy.getArtistById(id);
    if (legacyArtist != null) {
      return _convertToArtist(legacyArtist);
    }
    return null;
  }

  /// Get artist by username
  Artist? getArtistByUsername(String username) {
    final normalizedUsername = username.startsWith('@')
        ? username.toLowerCase()
        : '@${username.toLowerCase()}';

    try {
      final legacyArtist = legacy.gearshArtists.firstWhere(
        (a) => a.username.toLowerCase() == normalizedUsername,
      );
      return _convertToArtist(legacyArtist);
    } catch (_) {
      return null;
    }
  }

  /// Search artists by query
  List<Artist> searchArtists(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return getAllArtists();

    return legacy.gearshArtists
        .where((a) =>
            a.name.toLowerCase().contains(normalizedQuery) ||
            a.username.toLowerCase().contains(normalizedQuery) ||
            a.category.toLowerCase().contains(normalizedQuery) ||
            a.subcategories.any((s) => s.toLowerCase().contains(normalizedQuery)) ||
            a.location.toLowerCase().contains(normalizedQuery) ||
            a.bio.toLowerCase().contains(normalizedQuery))
        .map(_convertToArtist)
        .toList();
  }

  /// Get artists by category
  List<Artist> getArtistsByCategory(String category) {
    if (category.toLowerCase() == 'all') return getAllArtists();

    return legacy.gearshArtists
        .where((a) =>
            a.category.toLowerCase() == category.toLowerCase() ||
            a.subcategories.any((s) => s.toLowerCase() == category.toLowerCase()))
        .map(_convertToArtist)
        .toList();
  }

  /// Get artists by location
  List<Artist> getArtistsByLocation(String location) {
    final normalizedLocation = location.toLowerCase();
    return legacy.gearshArtists
        .where((a) => a.location.toLowerCase().contains(normalizedLocation))
        .map(_convertToArtist)
        .toList();
  }

  /// Get featured artists (verified + high rating)
  List<Artist> getFeaturedArtists() {
    return legacy.gearshArtists
        .where((a) => a.isVerified && a.rating >= 4.5)
        .map(_convertToArtist)
        .toList();
  }

  /// Get available artists
  List<Artist> getAvailableArtists() {
    return legacy.gearshArtists
        .where((a) => a.isAvailable)
        .map(_convertToArtist)
        .toList();
  }

  /// Get artists sorted by criteria
  List<Artist> getArtistsSorted({
    required ArtistSortCriteria criteria,
    bool ascending = true,
  }) {
    final artists = List<legacy.GearshArtist>.from(legacy.gearshArtists);

    artists.sort((a, b) {
      int comparison;
      switch (criteria) {
        case ArtistSortCriteria.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case ArtistSortCriteria.rating:
          comparison = a.rating.compareTo(b.rating);
          break;
        case ArtistSortCriteria.price:
          comparison = a.bookingFee.compareTo(b.bookingFee);
          break;
        case ArtistSortCriteria.hoursBooked:
          comparison = a.hoursBooked.compareTo(b.hoursBooked);
          break;
        case ArtistSortCriteria.reviewCount:
          comparison = a.reviewCount.compareTo(b.reviewCount);
          break;
      }
      return ascending ? comparison : -comparison;
    });

    return artists.map(_convertToArtist).toList();
  }

  /// Get all unique categories
  List<String> getAllCategories() {
    final categories = <String>{};
    for (final artist in legacy.gearshArtists) {
      categories.add(artist.category);
      categories.addAll(artist.subcategories);
    }
    return categories.toList()..sort();
  }
}
