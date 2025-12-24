import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/features/search/data/models/search_filters.dart';
import 'package:gearsh_app/features/search/data/models/search_result.dart';
import 'package:gearsh_app/models/artist.dart';

final searchServiceProvider = Provider((ref) => SearchService());

class SearchService {
  List<SearchResult> searchArtists({
    required List<Artist> artists,
    required String query,
    required SearchFilters filters,
  }) {
    final lowerCaseQuery = query.toLowerCase();
    List<SearchResult> searchResults = [];

    for (final artist in artists) {
      double score = 0;
      final matchedFields = <String>{};

      // 1. Scoring
      if (artist.name.toLowerCase() == lowerCaseQuery) {
        score += 100;
        matchedFields.add('name');
      } else if (artist.name.toLowerCase().contains(lowerCaseQuery)) {
        score += 80;
        matchedFields.add('name');
      } else if (artist.name.toLowerCase().startsWith(lowerCaseQuery)) {
        score += 70;
        matchedFields.add('name');
      }

      if (artist.category?.toLowerCase() == lowerCaseQuery) {
        score += 60;
        matchedFields.add('category');
      }

      if (artist.bio.toLowerCase().contains(lowerCaseQuery)) {
        score += 20;
        matchedFields.add('bio');
      }

      // Add more scoring logic here based on your document...

      // Rating Boost
      score += artist.averageRating * 5;

      // Verification Boost
      if (artist.isVerified == true) {
        score += 15;
      }

      // Popularity Boost (example)
      score += artist.reviewCount * 0.1;

      if (score > 0) {
        searchResults.add(SearchResult(artist: artist, score: score, matchedFields: matchedFields));
      }
    }

    // 2. Filtering
    searchResults = searchResults.where((result) {
      final artist = result.artist;
      if (filters.categories.isNotEmpty && !filters.categories.contains(artist.category)) {
        return false;
      }
      if (artist.averageRating < filters.minRating) {
        return false;
      }
      if (filters.isVerified && artist.isVerified != true) {
        return false;
      }
      // Add price filtering here...
      return true;
    }).toList();

    // 3. Sorting
    searchResults.sort((a, b) {
      // Implement sorting based on filters.sortOption
      // For now, just sort by score
      return b.score.compareTo(a.score);
    });

    return searchResults;
  }
}

