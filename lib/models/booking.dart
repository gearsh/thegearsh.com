// lib/models/booking.dart

import 'package:flutter/material.dart';

class Booking {
  final String id;            // Unique booking ID
  final String artistId;      // Artist being booked
  final String userId;        // User who made the booking
  final DateTime date;        // Booking date
  final TimeOfDay time;       // Booking time
  final String location;      // Event location
  final double totalPrice;    // Price of the booking

  Booking({
    required this.id,
    required this.artistId,
    required this.userId,
    required this.date,
    required this.time,
    required this.location,
    required this.totalPrice,
  });

  // Factory constructor from JSON (for API)
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      artistId: json['artistId'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      time: TimeOfDay(
        hour: int.parse(json['time'].split(':')[0]),
        minute: int.parse(json['time'].split(':')[1]),
      ),
      location: json['location'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  // Convert to JSON (for API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artistId': artistId,
      'userId': userId,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'location': location,
      'totalPrice': totalPrice,
    };
  }

  // CopyWith for immutability
  Booking copyWith({
    String? id,
    String? artistId,
    String? userId,
    DateTime? date,
    TimeOfDay? time,
    String? location,
    double? totalPrice,
  }) {
    return Booking(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
