// Gearsh App - Domain Layer: Booking Entity
// Represents a booking between a client and an artist

import 'package:gearsh_app/domain/entities/service.dart';

/// Booking status throughout its lifecycle
enum BookingStatus {
  pending,      // Initial request
  accepted,     // Artist accepted
  declined,     // Artist declined
  confirmed,    // Payment confirmed
  inProgress,   // Event is happening
  completed,    // Successfully completed
  cancelled,    // Cancelled by either party
  disputed,     // Under dispute
}

/// Payment status for a booking
enum PaymentStatus {
  pending,
  escrowHeld,
  released,
  refunded,
  failed,
}

/// A booking between a client and an artist
class Booking {
  final String id;
  final String clientId;
  final String artistId;
  final String artistName;
  final String? artistImage;
  final Service service;
  final DateTime eventDate;
  final String? eventTime;
  final String? eventVenue;
  final String? eventDescription;
  final double totalAmount;
  final double? serviceFee;
  final String currency;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? notes;

  const Booking({
    required this.id,
    required this.clientId,
    required this.artistId,
    required this.artistName,
    this.artistImage,
    required this.service,
    required this.eventDate,
    this.eventTime,
    this.eventVenue,
    this.eventDescription,
    required this.totalAmount,
    this.serviceFee,
    this.currency = 'ZAR',
    this.status = BookingStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
  });

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Whether the booking is active (not cancelled/completed)
  bool get isActive =>
      status != BookingStatus.cancelled &&
      status != BookingStatus.completed &&
      status != BookingStatus.declined;

  /// Whether the booking can be cancelled
  bool get canCancel =>
      status == BookingStatus.pending ||
      status == BookingStatus.accepted ||
      status == BookingStatus.confirmed;

  /// Whether the booking is upcoming
  bool get isUpcoming => eventDate.isAfter(DateTime.now()) && isActive;

  /// Whether the booking is past
  bool get isPast => eventDate.isBefore(DateTime.now());

  /// Days until the event
  int get daysUntil => eventDate.difference(DateTime.now()).inDays;

  /// Formatted event date
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}';
  }

  /// Status display text
  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  Booking copyWith({
    String? id,
    String? clientId,
    String? artistId,
    String? artistName,
    String? artistImage,
    Service? service,
    DateTime? eventDate,
    String? eventTime,
    String? eventVenue,
    String? eventDescription,
    double? totalAmount,
    double? serviceFee,
    String? currency,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? notes,
  }) {
    return Booking(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      artistImage: artistImage ?? this.artistImage,
      service: service ?? this.service,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      eventVenue: eventVenue ?? this.eventVenue,
      eventDescription: eventDescription ?? this.eventDescription,
      totalAmount: totalAmount ?? this.totalAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Booking(id: $id, artist: $artistName, status: $status)';
}
