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
    this.baseRate,
    this.portfolioImageUrls,
    List<Review>? reviews,
  }) : reviews = reviews ?? [];

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
      baseRate: baseRate ?? this.baseRate,
      portfolioImageUrls: portfolioImageUrls ?? this.portfolioImageUrls,
      reviews: reviews ?? this.reviews,
    );
  }
}
