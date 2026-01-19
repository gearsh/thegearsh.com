// Gearsh App - Booking Service
// Handles booking creation, management, and API integration

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BookingService {
  static const String _baseUrl = 'https://thegearsh-com.pages.dev/api';

  /// Create a new booking
  Future<BookingResult> createBooking({
    required String clientId,
    required String artistId,
    String? serviceId,
    required String eventDate,
    String? eventTime,
    String? eventLocation,
    String? eventType,
    double? durationHours,
    required double totalPrice,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'artist_id': artistId,
          'service_id': serviceId,
          'event_date': eventDate,
          'event_time': eventTime,
          'event_location': eventLocation,
          'event_type': eventType,
          'duration_hours': durationHours,
          'total_price': totalPrice,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return BookingResult.success(
          bookingId: data['data']['booking_id'],
          status: data['data']['status'],
        );
      } else {
        final error = jsonDecode(response.body);
        return BookingResult.failure(error['error'] ?? 'Failed to create booking');
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return BookingResult.failure('Network error. Please try again.');
    }
  }

  /// Get bookings for a user
  Future<List<Booking>> getBookings({
    required String userId,
    String userType = 'client',
    String? status,
  }) async {
    try {
      final queryParams = {
        'user_id': userId,
        'user_type': userType,
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$_baseUrl/bookings').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = (data['data'] as List?)
            ?.map((b) => Booking.fromJson(b))
            .toList() ?? [];
        return bookings;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      return [];
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': 'cancelled'}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  /// Confirm a booking (for artists)
  Future<bool> confirmBooking(String bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': 'confirmed'}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error confirming booking: $e');
      return false;
    }
  }

  /// Complete a booking
  Future<bool> completeBooking(String bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': 'completed'}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error completing booking: $e');
      return false;
    }
  }
}

/// Booking result wrapper
class BookingResult {
  final bool success;
  final String? bookingId;
  final String? status;
  final String? error;

  BookingResult._({
    required this.success,
    this.bookingId,
    this.status,
    this.error,
  });

  factory BookingResult.success({required String bookingId, required String status}) {
    return BookingResult._(success: true, bookingId: bookingId, status: status);
  }

  factory BookingResult.failure(String error) {
    return BookingResult._(success: false, error: error);
  }
}

/// Booking model
class Booking {
  final String id;
  final String clientId;
  final String artistId;
  final String? serviceId;
  final String eventDate;
  final String? eventTime;
  final String? eventLocation;
  final String? eventType;
  final double? durationHours;
  final double totalPrice;
  final String status;
  final String? notes;
  final String? artistName;
  final String? artistImage;
  final String? serviceName;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.clientId,
    required this.artistId,
    this.serviceId,
    required this.eventDate,
    this.eventTime,
    this.eventLocation,
    this.eventType,
    this.durationHours,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.artistName,
    this.artistImage,
    this.serviceName,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      artistId: json['artist_id'] ?? '',
      serviceId: json['service_id'],
      eventDate: json['event_date'] ?? '',
      eventTime: json['event_time'],
      eventLocation: json['event_location'],
      eventType: json['event_type'],
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
      serviceName: json['service_name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
