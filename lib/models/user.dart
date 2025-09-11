class User {
  final String id; // Airtable record ID
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

  factory User.fromAirtable(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    final attachments = (fields['ProfilePicture'] as List?) ?? [];
    final profileUrl = attachments.isNotEmpty ? attachments.first['url'] : '';

    return User(
      id: json['id'],
      name: fields['Name'] ?? '',
      profilePictureUrl: profileUrl,
      genre: fields['Genre'] ?? '',
      location: fields['Location'] ?? '',
      availability: List<String>.from(fields['Availability'] ?? []),
      bio: fields['Bio'] ?? '',
      joinedAt: DateTime.tryParse(fields['Created Time'] ?? ''),
      lastActive: DateTime.tryParse(fields['Last Modified Time'] ?? ''),
    );
  }
}
