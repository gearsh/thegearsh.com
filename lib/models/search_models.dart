import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gearsh_app/models/artist.dart';

enum SortOption {
  relevance,
  highestRated,
  priceLowToHigh,
  priceHighToLow,
  mostPopular,
}

@immutable
class SearchFilters {
  final Set<String> categories;
  final double minRating;
  final bool showVerifiedOnly;
  final RangeValues priceRange;
  final SortOption sortOption;

  const SearchFilters({
    this.categories = const {},
    this.minRating = 0.0,
    this.showVerifiedOnly = false,
    this.priceRange = const RangeValues(0, 10000),
    this.sortOption = SortOption.relevance,
  });

  factory SearchFilters.defaults() => const SearchFilters();

  bool get isDefault =>
      categories.isEmpty &&
      minRating == 0.0 &&
      !showVerifiedOnly &&
      priceRange.start == 0 &&
      priceRange.end == 10000 &&
      sortOption == SortOption.relevance;

  SearchFilters copyWith({
    Set<String>? categories,
    double? minRating,
    bool? showVerifiedOnly,
    RangeValues? priceRange,
    SortOption? sortOption,
  }) {
    return SearchFilters(
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      showVerifiedOnly: showVerifiedOnly ?? this.showVerifiedOnly,
      priceRange: priceRange ?? this.priceRange,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilters &&
          runtimeType == other.runtimeType &&
          setEquals(categories, other.categories) &&
          minRating == other.minRating &&
          showVerifiedOnly == other.showVerifiedOnly &&
          priceRange == other.priceRange &&
          sortOption == other.sortOption;

  @override
  int get hashCode =>
      Object.hash(categories, minRating, showVerifiedOnly, priceRange, sortOption);
}

@immutable
class SearchResult {
  final Artist artist;
  final double score;
  final Set<String> matchedFields;

  const SearchResult({
    required this.artist,
    required this.score,
    this.matchedFields = const {},
  });
}

