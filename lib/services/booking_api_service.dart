import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/config/api_config.dart';
import 'package:gearsh_app/services/api_service.dart';

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
  final String? artistCategory;
  final String? serviceName;
  final String? clientName;
  final String? createdAt;

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
    this.artistCategory,
    this.serviceName,
    this.clientName,
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      clientId: json['client_id'],
      artistId: json['artist_id'],
      serviceId: json['service_id'],
      eventDate: json['event_date'],
      eventTime: json['event_time'],
      eventLocation: json['event_location'],
      eventType: json['event_type'],
      durationHours: json['duration_hours']?.toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
      artistCategory: json['artist_category'],
      serviceName: json['service_name'],
      clientName: json['client_name'],
      createdAt: json['created_at'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
}

/// Booking API service provider
final bookingApiServiceProvider = Provider((ref) {
  final apiService = ref.read(apiServiceProvider);
  return BookingApiService(apiService);
});

/// User bookings provider
final userBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, userId) async {
  final bookingService = ref.read(bookingApiServiceProvider);
  return bookingService.getUserBookings(userId: userId);
});

/// Booking API service
class BookingApiService {
  final ApiService _apiService;

  BookingApiService(this._apiService);

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
    final response = await _apiService.post(
      ApiConfig.bookings,
      body: {
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
      },
    );

    if (response.success && response.data != null) {
      return BookingResult.success(response.data['data']['booking_id']);
    }

    return BookingResult.failure(response.error ?? 'Failed to create booking');
  }

  /// Get user's bookings
  Future<List<Booking>> getUserBookings({
    required String userId,
    String userType = 'client',
    String? status,
  }) async {
    final queryParams = <String, String>{
      'user_id': userId,
      'user_type': userType,
    };

    if (status != null) queryParams['status'] = status;

    final response = await _apiService.get(
      ApiConfig.bookings,
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Booking.fromJson(json)).toList();
    }

    return [];
  }

  /// Update booking status
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final response = await _apiService.put(
      '${ApiConfig.bookings}/$bookingId',
      body: {'status': status},
    );

    return response.success;
  }
}

/// Booking result wrapper
class BookingResult {
  final bool success;
  final String? bookingId;
  final String? error;

  BookingResult._({required this.success, this.bookingId, this.error});

  factory BookingResult.success(String bookingId) {
    return BookingResult._(success: true, bookingId: bookingId);
  }

  factory BookingResult.failure(String error) {
    return BookingResult._(success: false, error: error);
  }
}

