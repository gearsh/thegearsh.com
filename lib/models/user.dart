class User {
  final String id;
  final String name;
  final String profilePictureUrl;
  final String genre;
  final String location;
  final List<String> availability;
  final String bio;
  final DateTime? joinedAt;
  final DateTime? lastActive;

  User({
    required this.id,
    required this.name,
    required this.profilePictureUrl,
    required this.genre,
    required this.location,
    required this.availability,
    required this.bio,
    this.joinedAt,
    this.lastActive,
  });
}
