// Gearsh App - Domain Layer: Service Entity
// Represents a bookable service offered by an artist

/// A service that can be booked from an artist
class Service {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final String description;
  final String duration;
  final List<String> includes;

  const Service({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    required this.description,
    required this.duration,
    this.includes = const [],
  });

  /// Whether this service has a discount
  bool get hasDiscount =>
      discountPercent != null &&
      discountPercent! > 0 &&
      originalPrice != null;

  /// Display price (current price)
  double get displayPrice => price;

  /// Factory from JSON map
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountPercent: json['discountPercent'] as int?,
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      includes: json['includes'] is List
          ? List<String>.from(json['includes'])
          : const [],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (discountPercent != null) 'discountPercent': discountPercent,
      'description': description,
      'duration': duration,
      'includes': includes,
    };
  }

  /// Create a copy with modified fields
  Service copyWith({
    String? id,
    String? name,
    double? price,
    double? originalPrice,
    int? discountPercent,
    String? description,
    String? duration,
    List<String>? includes,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      includes: includes ?? this.includes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Service(id: $id, name: $name, price: $price)';
}
