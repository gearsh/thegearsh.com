import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzy;
import 'package:gearsh_app/providers/artist_provider.dart';
import 'package:gearsh_app/models/search_models.dart';
import 'package:gearsh_app/models/artist.dart';

final searchServiceProvider = Provider((ref) => SearchService(ref));

class SearchService {
  final Ref _ref;

  SearchService(this._ref);

  Future<List<SearchResult>> searchArtists({
    required String query,
    required SearchFilters filters,
  }) async {
    if (query.isEmpty && filters.isDefault) {
      return [];
    }

    final lowerCaseQuery = query.toLowerCase();
    final artists = await _ref.read(artistListProvider.future);

    List<SearchResult> results = [];

    for (final artist in artists) {
      final scoreResult = _calculateScore(artist, lowerCaseQuery);
      if (scoreResult.score > 0) {
        results.add(SearchResult(
          artist: artist,
          score: scoreResult.score,
          matchedFields: scoreResult.matchedFields,
        ));
      }
    }

    final filteredResults = _applyFilters(results, filters);
    final sortedResults = _sortResults(filteredResults, filters.sortOption);

    return sortedResults;
  }

  ({double score, Set<String> matchedFields}) _calculateScore(
      Artist artist, String query) {
    if (query.isEmpty) return (score: 0, matchedFields: {});

    double score = 0;
    final matchedFields = <String>{};

    // Exact Match
    if (artist.name.toLowerCase() == query) {
      score += 100;
      matchedFields.add('name');
    }

    // Contains
    if (artist.name.toLowerCase().contains(query)) {
      score += 80;
      matchedFields.add('name');
    }

    // Starts With
    if (artist.name.toLowerCase().startsWith(query)) {
      score += 70;
      matchedFields.add('name');
    }

    // Fuzzy Match
    final nameRatio = fuzzy.ratio(artist.name.toLowerCase(), query);
    if (nameRatio > 70) {
      score += nameRatio * 0.5; // 50% of the ratio
      matchedFields.add('name');
    }

    // Category Match
    if (artist.category != null && artist.category!.toLowerCase() == query) {
      score += 60;
      matchedFields.add('category');
    } else if (artist.category != null &&
        fuzzy.partialRatio(artist.category!.toLowerCase(), query) > 80) {
      score += 30;
      matchedFields.add('category');
    }

    // Bio Match
    if (artist.bio.toLowerCase().contains(query)) {
      score += 20;
      matchedFields.add('bio');
    }

    // Location Match
    if (artist.location != null &&
        artist.location!.toLowerCase().contains(query)) {
      score += 25;
      matchedFields.add('location');
    }

    // Boosts
    score += artist.rating * 5; // Simplified null check
    score += artist.reviewCount * 0.1; // Simplified null check

    return (score: score, matchedFields: matchedFields);
  }

  List<SearchResult> _applyFilters(
      List<SearchResult> results, SearchFilters filters) {
    return results.where((result) {
      final artist = result.artist;

      if (filters.categories.isNotEmpty &&
          !filters.categories.contains(artist.category)) {
        return false;
      }

      if (filters.showVerifiedOnly && artist.isVerified != true) {
        return false;
      }

      final price = artist.basePrice ?? 0;
      if (price < filters.priceRange.start || price > filters.priceRange.end) {
        return false;
      }

      return true;
    }).toList();
  }

  List<SearchResult> _sortResults(
      List<SearchResult> results, SortOption sortOption) {
    switch (sortOption) {
      case SortOption.highestRated:
        results.sort((a, b) => b.artist.rating.compareTo(a.artist.rating));
        break;
      case SortOption.priceLowToHigh:
        results.sort((a, b) => a.artist.basePrice!.compareTo(b.artist.basePrice!));
        break;
      case SortOption.priceHighToLow:
        results.sort((a, b) => b.artist.basePrice!.compareTo(a.artist.basePrice!));
        break;
      case SortOption.mostPopular:
        results.sort((a, b) => b.artist.reviewCount.compareTo(a.artist.reviewCount));
        break;
      case SortOption.relevance:
        // No specific sorting needed for relevance
        break;
    }
    return results;
  }
}
