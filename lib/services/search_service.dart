import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzy;
import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:gearsh_app/models/search_models.dart';
import 'package:gearsh_app/models/artist.dart';

final searchServiceProvider = Provider((ref) => SearchService());

class SearchService {
  SearchService();

  // Popular search suggestions - Emerging Artists FIRST (Free to Book!)
  static const List<String> popularSearches = [
    'Emerging Artist', 'DJ', 'Amapiano', 'Hip Hop', 'Wedding DJ',
    'Photographer', 'Gospel', 'Jazz', 'R&B', 'Afrobeats',
    'House Music', 'Fashion Designer', 'MC', 'Live Band',
  ];

  // Category suggestions for autocomplete - Emerging Artists FIRST
  static const List<String> categoryKeywords = [
    'Emerging Artist', 'DJ', 'Amapiano', 'Hip Hop', 'Rap', 'Gospel', 'R&B', 'Pop',
    'Afro-Soul', 'House', 'Deep House', 'Jazz', 'Rock', 'Alternative',
    'Electronic', 'Afro-Pop', 'Kwaito', 'Gqom', 'Maskandi',
    'Fashion Designer', 'Photographer', 'Videographer', 'MC/Host',
    'Live Band', 'Saxophonist', 'Pianist', 'Guitarist', 'Vocalist',
    'Producer', 'Songwriter', 'Comedy', 'Poet', 'Visual Artist',
    'Event Planner', 'Makeup Artist', 'Stylist',
  ];

  // Location suggestions
  static const List<String> locationKeywords = [
    'Johannesburg', 'Cape Town', 'Durban', 'Pretoria', 'Port Elizabeth',
    'Bloemfontein', 'East London', 'Polokwane', 'Nelspruit', 'Kimberley',
    'South Africa', 'SA', 'Lagos', 'Nigeria', 'Ghana', 'Kenya',
    'USA', 'UK', 'London', 'New York', 'Los Angeles',
  ];

  /// Get autocomplete suggestions based on query
  List<SearchSuggestion> getAutocompleteSuggestions(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final suggestions = <SearchSuggestion>[];

    // Artist name suggestions
    for (final artist in gearshArtists) {
      if (artist.name.toLowerCase().startsWith(lowerQuery) ||
          artist.name.toLowerCase().contains(lowerQuery)) {
        suggestions.add(SearchSuggestion(
          text: artist.name,
          type: SuggestionType.artist,
          icon: 'person',
          subtitle: artist.category,
        ));
      }
      // Also check username
      if (artist.username.toLowerCase().contains(lowerQuery)) {
        suggestions.add(SearchSuggestion(
          text: artist.name,
          type: SuggestionType.artist,
          icon: 'person',
          subtitle: artist.username,
        ));
      }
    }

    // Category suggestions
    for (final category in categoryKeywords) {
      if (category.toLowerCase().startsWith(lowerQuery) ||
          category.toLowerCase().contains(lowerQuery)) {
        suggestions.add(SearchSuggestion(
          text: category,
          type: SuggestionType.category,
          icon: 'category',
          subtitle: 'Category',
        ));
      }
    }

    // Location suggestions
    for (final location in locationKeywords) {
      if (location.toLowerCase().startsWith(lowerQuery) ||
          location.toLowerCase().contains(lowerQuery)) {
        suggestions.add(SearchSuggestion(
          text: location,
          type: SuggestionType.location,
          icon: 'location',
          subtitle: 'Location',
        ));
      }
    }

    // Remove duplicates and limit results
    final seen = <String>{};
    final uniqueSuggestions = suggestions.where((s) {
      final key = '${s.text}_${s.type}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).take(10).toList();

    // Sort: exact matches first, then starts with, then contains
    uniqueSuggestions.sort((a, b) {
      final aExact = a.text.toLowerCase() == lowerQuery;
      final bExact = b.text.toLowerCase() == lowerQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aStarts = a.text.toLowerCase().startsWith(lowerQuery);
      final bStarts = b.text.toLowerCase().startsWith(lowerQuery);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      // Prioritize artists over categories over locations
      final typeOrder = {SuggestionType.artist: 0, SuggestionType.category: 1, SuggestionType.location: 2};
      return typeOrder[a.type]!.compareTo(typeOrder[b.type]!);
    });

    return uniqueSuggestions;
  }

  /// Main search function - Google-like search
  Future<List<GearshSearchResult>> searchArtists({
    required String query,
    required SearchFilters filters,
  }) async {
    // Return empty for no query and default filters
    if (query.isEmpty && filters.isDefault) {
      return [];
    }

    final lowerCaseQuery = query.toLowerCase().trim();
    final queryWords = lowerCaseQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    List<GearshSearchResult> results = [];

    for (final artist in gearshArtists) {
      final scoreResult = _calculateAdvancedScore(artist, lowerCaseQuery, queryWords);

      // Only include results with meaningful scores
      if (scoreResult.score > 20 || (query.isEmpty && !filters.isDefault)) {
        results.add(GearshSearchResult(
          artist: artist,
          score: scoreResult.score,
          matchedFields: scoreResult.matchedFields,
          highlights: scoreResult.highlights,
          matchType: scoreResult.matchType,
        ));
      }
    }

    // Apply filters
    results = _applyFilters(results, filters);

    // Sort results
    results = _sortResults(results, filters.sortOption, query.isNotEmpty);

    return results;
  }

  /// Advanced scoring algorithm with multiple match types
  _ScoreResult _calculateAdvancedScore(
    GearshArtist artist,
    String query,
    List<String> queryWords,
  ) {
    if (query.isEmpty) {
      return _ScoreResult(
        score: artist.rating * 10 + (artist.isVerified ? 20 : 0),
        matchedFields: {},
        highlights: {},
        matchType: MatchType.none,
      );
    }

    double score = 0;
    final matchedFields = <String>{};
    final highlights = <String, String>{};
    MatchType matchType = MatchType.partial;

    // ===== NAME MATCHING (Highest Priority) =====
    final nameLower = artist.name.toLowerCase();

    // Exact match - highest score
    if (nameLower == query) {
      score += 1000;
      matchedFields.add('name');
      highlights['name'] = artist.name;
      matchType = MatchType.exact;
    }
    // Name starts with query
    else if (nameLower.startsWith(query)) {
      score += 500;
      matchedFields.add('name');
      highlights['name'] = artist.name;
      matchType = MatchType.startsWith;
    }
    // Name contains query
    else if (nameLower.contains(query)) {
      score += 300;
      matchedFields.add('name');
      highlights['name'] = artist.name;
      matchType = matchType == MatchType.exact ? matchType : MatchType.contains;
    }
    // Fuzzy match on name
    else {
      final nameRatio = fuzzy.ratio(nameLower, query);
      final partialRatio = fuzzy.partialRatio(nameLower, query);
      if (nameRatio > 75 || partialRatio > 85) {
        score += (nameRatio + partialRatio) * 1.5;
        matchedFields.add('name');
        highlights['name'] = artist.name;
        matchType = MatchType.fuzzy;
      }
    }

    // Check individual words in name
    final nameWords = nameLower.split(RegExp(r'\s+'));
    for (final queryWord in queryWords) {
      for (final nameWord in nameWords) {
        if (nameWord == queryWord) {
          score += 200;
          matchedFields.add('name');
        } else if (nameWord.startsWith(queryWord)) {
          score += 100;
          matchedFields.add('name');
        }
      }
    }

    // ===== USERNAME MATCHING =====
    final usernameLower = artist.username.toLowerCase();
    if (usernameLower.contains(query)) {
      score += 150;
      matchedFields.add('username');
      highlights['username'] = artist.username;
    }

    // ===== CATEGORY MATCHING (High Priority) =====
    final categoryLower = artist.category.toLowerCase();

    if (categoryLower == query) {
      score += 400;
      matchedFields.add('category');
      highlights['category'] = artist.category;
    } else if (categoryLower.contains(query) || query.contains(categoryLower)) {
      score += 200;
      matchedFields.add('category');
      highlights['category'] = artist.category;
    } else {
      final catRatio = fuzzy.ratio(categoryLower, query);
      if (catRatio > 70) {
        score += catRatio * 2;
        matchedFields.add('category');
        highlights['category'] = artist.category;
      }
    }

    // ===== SUBCATEGORIES MATCHING =====
    for (final subcategory in artist.subcategories) {
      final subLower = subcategory.toLowerCase();
      if (subLower == query) {
        score += 250;
        matchedFields.add('subcategory');
        highlights['subcategory'] = subcategory;
      } else if (subLower.contains(query) || query.contains(subLower)) {
        score += 120;
        matchedFields.add('subcategory');
        highlights['subcategory'] = subcategory;
      }
    }

    // ===== LOCATION MATCHING =====
    final locationLower = artist.location.toLowerCase();

    if (locationLower.contains(query)) {
      score += 100;
      matchedFields.add('location');
      highlights['location'] = artist.location;
    }
    // Check individual location parts (city, country)
    final locationParts = locationLower.split(RegExp(r'[,\s]+'));
    for (final part in locationParts) {
      if (part == query || part.startsWith(query)) {
        score += 80;
        matchedFields.add('location');
        highlights['location'] = artist.location;
        break;
      }
    }

    // ===== BIO MATCHING =====
    final bioLower = artist.bio.toLowerCase();

    // Check if all query words appear in bio
    int bioWordMatches = 0;
    for (final word in queryWords) {
      if (word.length > 2 && bioLower.contains(word)) {
        bioWordMatches++;
      }
    }
    if (bioWordMatches > 0) {
      score += bioWordMatches * 30;
      matchedFields.add('bio');
    }

    // ===== HIGHLIGHTS MATCHING =====
    for (final highlight in artist.highlights) {
      final highlightLower = highlight.toLowerCase();
      if (highlightLower.contains(query)) {
        score += 50;
        matchedFields.add('highlights');
        break;
      }
      for (final word in queryWords) {
        if (word.length > 2 && highlightLower.contains(word)) {
          score += 25;
          matchedFields.add('highlights');
          break;
        }
      }
    }

    // ===== SERVICES MATCHING =====
    for (final service in artist.services) {
      final serviceName = (service['name'] as String? ?? '').toLowerCase();
      final serviceDesc = (service['description'] as String? ?? '').toLowerCase();
      if (serviceName.contains(query) || serviceDesc.contains(query)) {
        score += 40;
        matchedFields.add('services');
        break;
      }
    }

    // ===== QUALITY BOOSTS =====
    // Verified artist boost
    if (artist.isVerified) {
      score += 50;
    }

    // Rating boost (higher rated = more relevant)
    score += artist.rating * 15;

    // Review count boost (more reviews = more established)
    score += (artist.reviewCount * 0.5).clamp(0, 50);

    // Completed gigs boost
    score += (artist.hoursBooked * 0.05).clamp(0, 50);

    // Availability boost
    if (artist.isAvailable) {
      score += 25;
    }

    return _ScoreResult(
      score: score,
      matchedFields: matchedFields,
      highlights: highlights,
      matchType: matchType,
    );
  }

  /// Apply filters to search results
  List<GearshSearchResult> _applyFilters(
    List<GearshSearchResult> results,
    SearchFilters filters,
  ) {
    return results.where((result) {
      final artist = result.artist;

      // Category filter
      if (filters.categories.isNotEmpty) {
        final matchesCategory = filters.categories.any((cat) =>
          artist.category.toLowerCase() == cat.toLowerCase() ||
          artist.subcategories.any((sub) => sub.toLowerCase() == cat.toLowerCase())
        );
        if (!matchesCategory) return false;
      }

      // Verified only filter
      if (filters.showVerifiedOnly && !artist.isVerified) {
        return false;
      }

      // Rating filter
      if (artist.rating < filters.minRating) {
        return false;
      }

      // Price range filter
      final price = artist.bookingFee.toDouble();
      if (price < filters.priceRange.start || price > filters.priceRange.end) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Sort results based on selected option
  List<GearshSearchResult> _sortResults(
    List<GearshSearchResult> results,
    SortOption sortOption,
    bool hasQuery,
  ) {
    switch (sortOption) {
      case SortOption.relevance:
        // For relevance, use the calculated score
        results.sort((a, b) => b.score.compareTo(a.score));
        break;
      case SortOption.highestRated:
        results.sort((a, b) {
          final ratingCompare = b.artist.rating.compareTo(a.artist.rating);
          if (ratingCompare != 0) return ratingCompare;
          return b.score.compareTo(a.score);
        });
        break;
      case SortOption.priceLowToHigh:
        results.sort((a, b) {
          final priceCompare = a.artist.bookingFee.compareTo(b.artist.bookingFee);
          if (priceCompare != 0) return priceCompare;
          return b.score.compareTo(a.score);
        });
        break;
      case SortOption.priceHighToLow:
        results.sort((a, b) {
          final priceCompare = b.artist.bookingFee.compareTo(a.artist.bookingFee);
          if (priceCompare != 0) return priceCompare;
          return b.score.compareTo(a.score);
        });
        break;
      case SortOption.mostPopular:
        results.sort((a, b) {
          final popularScore = (b.artist.reviewCount + b.artist.hoursBooked)
              .compareTo(a.artist.reviewCount + a.artist.hoursBooked);
          if (popularScore != 0) return popularScore;
          return b.score.compareTo(a.score);
        });
        break;
    }
    return results;
  }

  // Legacy method for backward compatibility
  Future<List<SearchResult>> searchArtistsLegacy({
    required String query,
    required SearchFilters filters,
  }) async {
    final gearshResults = await searchArtists(query: query, filters: filters);
    return gearshResults.map((r) => SearchResult(
      artist: Artist(
        id: r.artist.id,
        name: r.artist.name,
        genre: r.artist.category,
        bio: r.artist.bio,
        image: r.artist.image,
        category: r.artist.category,
        location: r.artist.location,
        isVerified: r.artist.isVerified,
        baseRate: r.artist.bookingFee.toDouble(),
      ),
      score: r.score,
      matchedFields: r.matchedFields,
    )).toList();
  }
}

// ===== New Models for Enhanced Search =====

enum SuggestionType { artist, category, location, recent }

class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final String icon;
  final String? subtitle;

  const SearchSuggestion({
    required this.text,
    required this.type,
    required this.icon,
    this.subtitle,
  });
}

enum MatchType { exact, startsWith, contains, fuzzy, partial, none }

class GearshSearchResult {
  final GearshArtist artist;
  final double score;
  final Set<String> matchedFields;
  final Map<String, String> highlights;
  final MatchType matchType;

  const GearshSearchResult({
    required this.artist,
    required this.score,
    this.matchedFields = const {},
    this.highlights = const {},
    this.matchType = MatchType.partial,
  });
}

class _ScoreResult {
  final double score;
  final Set<String> matchedFields;
  final Map<String, String> highlights;
  final MatchType matchType;

  const _ScoreResult({
    required this.score,
    required this.matchedFields,
    required this.highlights,
    required this.matchType,
  });
}
