enum SortOption {
  relevance,
  highestRated,
  priceLowToHigh,
  priceHighToLow,
  mostPopular,
}

class SearchFilters {
  final Set<String> categories;
  final double minRating;
  final bool isVerified;
  final double? minPrice;
  final double? maxPrice;
  final SortOption sortOption;

  SearchFilters({
    this.categories = const {},
    this.minRating = 0.0,
    this.isVerified = false,
    this.minPrice,
    this.maxPrice,
    this.sortOption = SortOption.relevance,
  });

  factory SearchFilters.defaults() {
    return SearchFilters();
  }

  bool get isDefault {
    return categories.isEmpty &&
        minRating == 0.0 &&
        !isVerified &&
        minPrice == null &&
        maxPrice == null &&
        sortOption == SortOption.relevance;
  }

  SearchFilters copyWith({
    Set<String>? categories,
    double? minRating,
    bool? isVerified,
    double? minPrice,
    double? maxPrice,
    SortOption? sortOption,
  }) {
    return SearchFilters(
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      isVerified: isVerified ?? this.isVerified,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

