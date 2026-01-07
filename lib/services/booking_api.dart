/// Gearsh Booking API Service
/// Complete booking management with proper error handling

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/services/api_client.dart';
import 'package:gearsh_app/services/error_handling.dart';

/// Provider for booking API service
final bookingApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingApiService(apiClient);
});

/// Booking status enum
enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  disputed('disputed');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

/// Booking model
class Booking {
  final String id;
  final String clientId;
  final String artistId;
  final String? serviceId;
  final String artistName;
  final String? artistImage;
  final String? serviceName;
  final DateTime eventDate;
  final String? eventTime;
  final String? eventLocation;
  final String? eventType;
  final double? durationHours;
  final double totalPrice;
  final double serviceFee;
  final String? notes;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? agreementDetails;
  final Map<String, dynamic>? riderDetails;

  const Booking({
    required this.id,
    required this.clientId,
    required this.artistId,
    this.serviceId,
    required this.artistName,
    this.artistImage,
    this.serviceName,
    required this.eventDate,
    this.eventTime,
    this.eventLocation,
    this.eventType,
    this.durationHours,
    required this.totalPrice,
    required this.serviceFee,
    this.notes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.agreementDetails,
    this.riderDetails,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      artistId: json['artist_id'] as String,
      serviceId: json['service_id'] as String?,
      artistName: json['artist_name'] as String? ?? 'Unknown Artist',
      artistImage: json['artist_image'] as String?,
      serviceName: json['service_name'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      eventTime: json['event_time'] as String?,
      eventLocation: json['event_location'] as String?,
      eventType: json['event_type'] as String?,
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      agreementDetails: json['agreement_details'] as Map<String, dynamic>?,
      riderDetails: json['rider_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'artist_id': artistId,
      'service_id': serviceId,
      'artist_name': artistName,
      'artist_image': artistImage,
      'service_name': serviceName,
      'event_date': eventDate.toIso8601String(),
      'event_time': eventTime,
      'event_location': eventLocation,
      'event_type': eventType,
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'service_fee': serviceFee,
      'notes': notes,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'agreement_details': agreementDetails,
      'rider_details': riderDetails,
    };
  }

  Booking copyWith({
    String? id,
    String? clientId,
    String? artistId,
    String? serviceId,
    String? artistName,
    String? artistImage,
    String? serviceName,
    DateTime? eventDate,
    String? eventTime,
    String? eventLocation,
    String? eventType,
    double? durationHours,
    double? totalPrice,
    double? serviceFee,
    String? notes,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? agreementDetails,
    Map<String, dynamic>? riderDetails,
  }) {
    return Booking(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      artistId: artistId ?? this.artistId,
      serviceId: serviceId ?? this.serviceId,
      artistName: artistName ?? this.artistName,
      artistImage: artistImage ?? this.artistImage,
      serviceName: serviceName ?? this.serviceName,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      eventLocation: eventLocation ?? this.eventLocation,
      eventType: eventType ?? this.eventType,
      durationHours: durationHours ?? this.durationHours,
      totalPrice: totalPrice ?? this.totalPrice,
      serviceFee: serviceFee ?? this.serviceFee,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      agreementDetails: agreementDetails ?? this.agreementDetails,
      riderDetails: riderDetails ?? this.riderDetails,
    );
  }
}

/// Create booking request
class CreateBookingRequest {
  final String clientId;
  final String artistId;
  final String? serviceId;
  final DateTime eventDate;
  final String? eventTime;
  final String? eventLocation;
  final String? eventType;
  final double? durationHours;
  final double totalPrice;
  final String? notes;
  final Map<String, dynamic>? agreementDetails;
  final Map<String, dynamic>? riderDetails;

  const CreateBookingRequest({
    required this.clientId,
    required this.artistId,
    this.serviceId,
    required this.eventDate,
    this.eventTime,
    this.eventLocation,
    this.eventType,
    this.durationHours,
    required this.totalPrice,
    this.notes,
    this.agreementDetails,
    this.riderDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'artist_id': artistId,
      'service_id': serviceId,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'event_time': eventTime,
      'event_location': eventLocation,
      'event_type': eventType,
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'notes': notes,
      'agreement_details': agreementDetails,
      'rider_details': riderDetails,
    };
  }
}

/// Booking API Service
class BookingApiService {
  final GearshApiClient _apiClient;

  BookingApiService(this._apiClient);

  /// Create a new booking
  Future<ApiResult<Booking>> createBooking(CreateBookingRequest request) async {
    return _apiClient.post<Booking>(
      '/bookings',
      body: request.toJson(),
      parser: (data) => Booking.fromJson(data as Map<String, dynamic>),
      config: RequestConfig.authenticated,
    );
  }

  /// Get user's bookings
  Future<ApiResult<List<Booking>>> getUserBookings({
    required String userId,
    String userType = 'client',
    BookingStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'user_id': userId,
      'user_type': userType,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) {
      queryParams['status'] = status.value;
    }

    return _apiClient.get<List<Booking>>(
      '/bookings',
      queryParams: queryParams,
      parser: (data) {
        if (data is List) {
          return data.map((item) => Booking.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [];
      },
      config: RequestConfig.authenticated,
    );
  }

  /// Get a specific booking
  Future<ApiResult<Booking>> getBooking(String bookingId) async {
    return _apiClient.get<Booking>(
      '/bookings/$bookingId',
      parser: (data) => Booking.fromJson(data as Map<String, dynamic>),
      config: RequestConfig.authenticated,
    );
  }

  /// Update booking status
  Future<ApiResult<Booking>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? reason,
  }) async {
    return _apiClient.patch<Booking>(
      '/bookings/$bookingId/status',
      body: {
        'status': status.value,
        if (reason != null) 'reason': reason,
      },
      parser: (data) => Booking.fromJson(data as Map<String, dynamic>),
      config: RequestConfig.authenticated,
    );
  }

  /// Confirm a booking (artist action)
  Future<ApiResult<Booking>> confirmBooking(String bookingId) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.confirmed,
    );
  }

  /// Cancel a booking
  Future<ApiResult<Booking>> cancelBooking(String bookingId, {String? reason}) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.cancelled,
      reason: reason,
    );
  }

  /// Complete a booking
  Future<ApiResult<Booking>> completeBooking(String bookingId) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.completed,
    );
  }

  /// Update booking details
  Future<ApiResult<Booking>> updateBooking({
    required String bookingId,
    DateTime? eventDate,
    String? eventTime,
    String? eventLocation,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (eventDate != null) body['event_date'] = eventDate.toIso8601String().split('T')[0];
    if (eventTime != null) body['event_time'] = eventTime;
    if (eventLocation != null) body['event_location'] = eventLocation;
    if (notes != null) body['notes'] = notes;

    return _apiClient.patch<Booking>(
      '/bookings/$bookingId',
      body: body,
      parser: (data) => Booking.fromJson(data as Map<String, dynamic>),
      config: RequestConfig.authenticated,
    );
  }

  /// Get booking statistics
  Future<ApiResult<BookingStats>> getBookingStats({
    required String userId,
    String userType = 'client',
  }) async {
    return _apiClient.get<BookingStats>(
      '/bookings/stats',
      queryParams: {
        'user_id': userId,
        'user_type': userType,
      },
      parser: (data) => BookingStats.fromJson(data as Map<String, dynamic>),
      config: RequestConfig.authenticated,
    );
  }

  /// Submit booking review
  Future<ApiResult<void>> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    return _apiClient.post<void>(
      '/bookings/$bookingId/review',
      body: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
      parser: (_) {},
      config: RequestConfig.authenticated,
    );
  }
}

/// Booking statistics model
class BookingStats {
  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalSpent;
  final double totalEarned;

  const BookingStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalSpent,
    required this.totalEarned,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      totalBookings: json['total_bookings'] as int? ?? 0,
      pendingBookings: json['pending_bookings'] as int? ?? 0,
      confirmedBookings: json['confirmed_bookings'] as int? ?? 0,
      completedBookings: json['completed_bookings'] as int? ?? 0,
      cancelledBookings: json['cancelled_bookings'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
    );
  }

  factory BookingStats.empty() => const BookingStats(
    totalBookings: 0,
    pendingBookings: 0,
    confirmedBookings: 0,
    completedBookings: 0,
    cancelledBookings: 0,
    totalSpent: 0,
    totalEarned: 0,
  );
}

