// lib/models/badge.dart

class Badge {
  final String name;
  final String description;
  final String colorHex;
  final String emoji;

  const Badge({
    required this.name,
    required this.description,
    required this.colorHex,
    required this.emoji,
  });
}
