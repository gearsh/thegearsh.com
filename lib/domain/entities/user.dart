// Gearsh App - Domain Layer: User Entity
// Represents a user on the platform (Artist, Client, or Fan)

/// User roles in the Gearsh platform
enum UserRole {
  artist,
  client,
  fan,
  guest,
}

/// User entity representing a registered user
class User {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final UserRole role;
  final String? location;
  final String? country;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<String> skills;
  final bool isVerified;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.coverImageUrl,
    this.role = UserRole.guest,
    this.location,
    this.country,
    this.dateOfBirth,
    this.gender,
    this.skills = const [],
    this.isVerified = false,
    this.isEmailVerified = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Full name computed from first and last name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName ?? username ?? email.split('@').first;
  }

  /// Whether the user is an artist
  bool get isArtist => role == UserRole.artist;

  /// Whether the user is a client
  bool get isClient => role == UserRole.client;

  /// Whether the user is a fan
  bool get isFan => role == UserRole.fan;

  /// Whether the user is a guest (not logged in)
  bool get isGuest => role == UserRole.guest;

  /// Whether the user is logged in
  bool get isLoggedIn => role != UserRole.guest;

  /// Create a guest user
  factory User.guest() {
    return User(
      id: 'guest',
      email: '',
      role: UserRole.guest,
      createdAt: DateTime.now(),
    );
  }

  /// Copy with modifications
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? coverImageUrl,
    UserRole? role,
    String? location,
    String? country,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? skills,
    bool? isVerified,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      role: role ?? this.role,
      location: location ?? this.location,
      country: country ?? this.country,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      skills: skills ?? this.skills,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, email: $email, role: $role)';
}
