import 'review.dart';

// The Gearsh App - lib/models/artist.dart
class Artist {
  final String id;
  final String name;
  final String genre;
  final String bio;
  final String image;
  final String? category;
  final double? hoursWorked;
  final String? location;
  final bool? availability;
  final List<String>? skills;
  final bool? isTrending;
  final bool? isVerified;
  final double? baseRate;
  final List<String>? portfolioImageUrls;
  final List<Review> reviews;

  Artist({
    required this.id,
    required this.name,
    required this.genre,
    required this.bio,
    required this.image,
    this.category,
    this.hoursWorked,
    this.location,
    this.availability,
    this.skills,
    this.isTrending,
    this.isVerified,
    this.baseRate,
    this.portfolioImageUrls,
    List<Review>? reviews,
  }) : reviews = reviews ?? [];

  double get averageRating {
    if (reviews.isEmpty) {
      return 0.0;
    }
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }

  int get reviewCount => reviews.length;

  double get rating => averageRating;

  double? get basePrice => baseRate;

  /// Factory for API response (Cloudflare Workers)
  factory Artist.fromApiJson(Map<String, dynamic> json) {
    return Artist(
      id: json['artist_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['display_name'] ?? '',
      genre: json['genre'] ?? '',
      bio: json['bio'] ?? '',
      image: json['image'] ?? json['profile_picture_url'] ?? '',
      category: json['category'],
      hoursWorked: json['hours_worked']?.toDouble(),
      location: json['location'],
      availability: json['availability_status'] == 'available',
      skills: json['skills'] is List ? List<String>.from(json['skills']) : null,
      isTrending: json['is_trending'] == true || json['is_trending'] == 1,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      baseRate: json['base_rate']?.toDouble(),
      portfolioImageUrls: json['portfolio_urls'] is List
          ? List<String>.from(json['portfolio_urls'])
          : null,
      reviews: json['reviews'] is List
          ? (json['reviews'] as List).map((r) => Review(
              reviewerName: r['reviewer_name'] ?? '',
              reviewerImageUrl: r['reviewer_image'] ?? '',
              rating: (r['rating'] ?? 0).toDouble(),
              comment: r['comment'] ?? '',
            )).toList()
          : [],
    );
  }

  /// Factory for Airtable response (legacy)
  factory Artist.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] ?? {};
    return Artist(
      id: json['id'] ?? '',
      name: fields['name'] ?? '',
      genre: fields['genre'] ?? '',
      bio: fields['bio'] ?? '',
      image: fields['image'] is List && fields['image'].isNotEmpty
          ? fields['image'][0]['url']
          : '',
      category: fields['category'],
      hoursWorked: fields['hoursWorked'] != null
          ? (fields['hoursWorked'] as num).toDouble()
          : null,
      location: fields['location'],
      availability: fields['availability'],
      skills: fields['skills'] != null ? List<String>.from(fields['skills']) : null,
      isTrending: fields['isTrending'],
      isVerified: fields['isVerified'],
      baseRate: fields['baseRate'] != null ? (fields['baseRate'] as num).toDouble() : null,
      portfolioImageUrls: fields['portfolioImageUrls'] != null ? List<String>.from(fields['portfolioImageUrls']) : null,
      reviews: fields['reviews'] != null
          ? List<Map<String, dynamic>>.from(fields['reviews']).map((r) => Review(
              reviewerName: r['reviewerName'] ?? '',
              reviewerImageUrl: r['reviewerImageUrl'] ?? '',
              rating: (r['rating'] ?? 0).toDouble(),
              comment: r['comment'] ?? '',
            )).toList()
          : [],
    );
  }

  String get profilePictureUrl => image;

  Artist copyWith({
    String? id,
    String? name,
    String? genre,
    String? bio,
    String? image,
    String? category,
    double? hoursWorked,
    String? location,
    bool? availability,
    List<String>? skills,
    bool? isTrending,
    bool? isVerified,
    double? baseRate,
    List<String>? portfolioImageUrls,
    List<Review>? reviews,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      bio: bio ?? this.bio,
      image: image ?? this.image,
      category: category ?? this.category,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      location: location ?? this.location,
      availability: availability ?? this.availability,
      skills: skills ?? this.skills,
      isTrending: isTrending ?? this.isTrending,
      isVerified: isVerified ?? this.isVerified,
      baseRate: baseRate ?? this.baseRate,
      portfolioImageUrls: portfolioImageUrls ?? this.portfolioImageUrls,
      reviews: reviews ?? this.reviews,
    );
  }
}
