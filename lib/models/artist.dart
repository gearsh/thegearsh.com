// The Gearsh App - lib/models/artist.dart
class Artist {
  final String id;
  final String name;
  final String genre;
  final String bio;
  final String image;
  final String? category;
  final double? hoursWorked;

  Artist({
    required this.id,
    required this.name,
    required this.genre,
    required this.bio,
    required this.image,
    this.category,
    this.hoursWorked,
  });

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
    );
  }

  String get profilePictureUrl => image;
}
