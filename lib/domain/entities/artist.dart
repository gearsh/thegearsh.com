// Gearsh App - Domain Layer: Artist Entity
// Pure business entity with no external dependencies

import 'package:gearsh_app/domain/entities/mastery.dart';
import 'package:gearsh_app/domain/entities/service.dart';

/// Artist entity representing a bookable artist on the platform.
/// This is the core business entity used throughout the app.
///
/// Follows:
/// - Immutability: All fields are final
/// - Single Responsibility: Only represents artist data
/// - Encapsulation: Business logic as computed properties
class Artist {
  final String id;
  final String name;
  final String username;
  final String category;
  final List<String> subcategories;
  final String location;
  final String countryCode;
  final String currencyCode;
  final double rating;
  final int reviewCount;
  final int hoursBooked;
  final String responseTime;
  final String profileImage;
  final String? coverImage;
  final bool isVerified;
  final bool isAvailable;
  final String bio;
  final int bookingFee;
  final int? originalBookingFee;
  final int? discountPercent;
  final double? bookingFeeUSD;
  final List<String> highlights;
  final List<Service> services;
  final List<PortfolioItem> portfolio;
  final List<UpcomingGig> upcomingGigs;
  final bool availableWorldwide;

  const Artist({
    required this.id,
    required this.name,
    required this.username,
    required this.category,
    required this.subcategories,
    required this.location,
    this.countryCode = 'ZA',
    this.currencyCode = 'ZAR',
    required this.rating,
    required this.reviewCount,
    required this.hoursBooked,
    required this.responseTime,
    required this.profileImage,
    this.coverImage,
    required this.isVerified,
    required this.isAvailable,
    required this.bio,
    required this.bookingFee,
    this.originalBookingFee,
    this.discountPercent,
    this.bookingFeeUSD,
    required this.highlights,
    required this.services,
    this.portfolio = const [],
    this.upcomingGigs = const [],
    this.availableWorldwide = true,
  });

  // ============================================================================
  // COMPUTED PROPERTIES (Business Logic)
  // ============================================================================

  /// Get mastery information based on hours booked
  MasteryInfo get masteryInfo => MasteryInfo.fromHours(hoursBooked);

  /// Hours remaining to reach Legend status (10,000 hours)
  int get hoursToMastery => (10000 - hoursBooked).clamp(0, 10000);

  /// Progress towards 10,000 hours mastery (0.0 to 1.0)
  double get masteryProgress => (hoursBooked / 10000).clamp(0.0, 1.0);

  /// Whether artist has achieved Legend status
  bool get isLegend => hoursBooked >= 10000;

  /// Whether artist has an active discount
  bool get hasDiscount =>
      discountPercent != null &&
      discountPercent! > 0 &&
      originalBookingFee != null;

  /// Whether artist is new/emerging (less than 100 hours)
  bool get isNewArtist =>
      category == 'Emerging Artist' || hoursBooked < 100;

  /// Display price (after discount)
  int get displayPrice => bookingFee;

  /// Original price before discount
  int get displayOriginalPrice =>
      originalBookingFee ??
      (isNewArtist && bookingFee > 0 ? (bookingFee * 5) : bookingFee);

  /// Discount percentage to display
  int get displayDiscountPercent =>
      discountPercent ??
      (isNewArtist && bookingFee > 0 ? 80 : 0);

  /// Whether to show discount badge
  bool get showDiscount => hasDiscount || (isNewArtist && bookingFee > 0);

  /// Cover image with fallback
  String? get displayCoverImage => coverImage;

  // ============================================================================
  // COPY WITH (Immutable Updates)
  // ============================================================================

  Artist copyWith({
    String? id,
    String? name,
    String? username,
    String? category,
    List<String>? subcategories,
    String? location,
    String? countryCode,
    String? currencyCode,
    double? rating,
    int? reviewCount,
    int? hoursBooked,
    String? responseTime,
    String? profileImage,
    String? coverImage,
    bool? isVerified,
    bool? isAvailable,
    String? bio,
    int? bookingFee,
    int? originalBookingFee,
    int? discountPercent,
    double? bookingFeeUSD,
    List<String>? highlights,
    List<Service>? services,
    List<PortfolioItem>? portfolio,
    List<UpcomingGig>? upcomingGigs,
    bool? availableWorldwide,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      category: category ?? this.category,
      subcategories: subcategories ?? this.subcategories,
      location: location ?? this.location,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      hoursBooked: hoursBooked ?? this.hoursBooked,
      responseTime: responseTime ?? this.responseTime,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      bio: bio ?? this.bio,
      bookingFee: bookingFee ?? this.bookingFee,
      originalBookingFee: originalBookingFee ?? this.originalBookingFee,
      discountPercent: discountPercent ?? this.discountPercent,
      bookingFeeUSD: bookingFeeUSD ?? this.bookingFeeUSD,
      highlights: highlights ?? this.highlights,
      services: services ?? this.services,
      portfolio: portfolio ?? this.portfolio,
      upcomingGigs: upcomingGigs ?? this.upcomingGigs,
      availableWorldwide: availableWorldwide ?? this.availableWorldwide,
    );
  }

  // ============================================================================
  // EQUALITY
  // ============================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Artist(id: $id, name: $name, username: $username)';
}

/// Portfolio item (discography, designs, murals, etc.)
class PortfolioItem {
  final String title;
  final String type;
  final String year;
  final String? image;
  final String? description;

  const PortfolioItem({
    required this.title,
    required this.type,
    required this.year,
    this.image,
    this.description,
  });
}

/// Upcoming gig/event
class UpcomingGig {
  final String title;
  final DateTime date;
  final String venue;
  final String type;

  const UpcomingGig({
    required this.title,
    required this.date,
    required this.venue,
    required this.type,
  });
}
