// Gearsh Booking Status Tracking Model
// Time-stamped, verifiable booking lifecycle states

import 'package:flutter/foundation.dart';

/// Extended booking with full lifecycle tracking
@immutable
class BookingLifecycle {
  final String id;
  final String bookingId;
  final BookingLifecycleStatus currentStatus;
  final List<StatusEvent> statusHistory;
  final DateTime createdAt;
  final DateTime? completedAt;

  const BookingLifecycle({
    required this.id,
    required this.bookingId,
    this.currentStatus = BookingLifecycleStatus.scheduled,
    this.statusHistory = const [],
    required this.createdAt,
    this.completedAt,
  });

  /// Get the most recent status event
  StatusEvent? get lastEvent => statusHistory.isNotEmpty ? statusHistory.last : null;

  /// Check if artist has checked in
  bool get hasCheckedIn => statusHistory.any((e) => e.status == BookingLifecycleStatus.checkedIn);

  /// Check if performance was completed
  bool get wasCompleted => currentStatus == BookingLifecycleStatus.completed;

  /// Check if there was a no-show
  bool get wasNoShow => currentStatus == BookingLifecycleStatus.didNotPerform;

  /// Get time since last status change
  Duration? get timeSinceLastChange {
    if (lastEvent == null) return null;
    return DateTime.now().difference(lastEvent!.timestamp);
  }

  BookingLifecycle copyWith({
    String? id,
    String? bookingId,
    BookingLifecycleStatus? currentStatus,
    List<StatusEvent>? statusHistory,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return BookingLifecycle(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      currentStatus: currentStatus ?? this.currentStatus,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Add a new status event
  BookingLifecycle addStatus(StatusEvent event) {
    return copyWith(
      currentStatus: event.status,
      statusHistory: [...statusHistory, event],
      completedAt: event.status == BookingLifecycleStatus.completed ? event.timestamp : completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'currentStatus': currentStatus.name,
    'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory BookingLifecycle.fromJson(Map<String, dynamic> json) {
    return BookingLifecycle(
      id: json['id'],
      bookingId: json['bookingId'],
      currentStatus: BookingLifecycleStatus.values.firstWhere((e) => e.name == json['currentStatus']),
      statusHistory: (json['statusHistory'] as List?)?.map((e) => StatusEvent.fromJson(e)).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}

/// Individual status change event
@immutable
class StatusEvent {
  final String id;
  final BookingLifecycleStatus status;
  final DateTime timestamp;
  final String? updatedBy; // User ID
  final String? updatedByRole; // 'artist', 'client', 'system', 'admin'
  final StatusVerification? verification;
  final String? notes;
  final GeoLocation? location;

  const StatusEvent({
    required this.id,
    required this.status,
    required this.timestamp,
    this.updatedBy,
    this.updatedByRole,
    this.verification,
    this.notes,
    this.location,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'updatedBy': updatedBy,
    'updatedByRole': updatedByRole,
    'verification': verification?.toJson(),
    'notes': notes,
    'location': location?.toJson(),
  };

  factory StatusEvent.fromJson(Map<String, dynamic> json) {
    return StatusEvent(
      id: json['id'],
      status: BookingLifecycleStatus.values.firstWhere((e) => e.name == json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      updatedBy: json['updatedBy'],
      updatedByRole: json['updatedByRole'],
      verification: json['verification'] != null ? StatusVerification.fromJson(json['verification']) : null,
      notes: json['notes'],
      location: json['location'] != null ? GeoLocation.fromJson(json['location']) : null,
    );
  }
}

/// Verification data for status changes
@immutable
class StatusVerification {
  final VerificationType type;
  final String? photoUrl;
  final String? documentUrl;
  final String? confirmedBy; // Other party confirmation
  final DateTime? confirmedAt;
  final String? deviceId;
  final String? ipAddress;
  final bool isAutoVerified; // System auto-verification

  const StatusVerification({
    required this.type,
    this.photoUrl,
    this.documentUrl,
    this.confirmedBy,
    this.confirmedAt,
    this.deviceId,
    this.ipAddress,
    this.isAutoVerified = false,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'photoUrl': photoUrl,
    'documentUrl': documentUrl,
    'confirmedBy': confirmedBy,
    'confirmedAt': confirmedAt?.toIso8601String(),
    'deviceId': deviceId,
    'ipAddress': ipAddress,
    'isAutoVerified': isAutoVerified,
  };

  factory StatusVerification.fromJson(Map<String, dynamic> json) {
    return StatusVerification(
      type: VerificationType.values.firstWhere((e) => e.name == json['type']),
      photoUrl: json['photoUrl'],
      documentUrl: json['documentUrl'],
      confirmedBy: json['confirmedBy'],
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      deviceId: json['deviceId'],
      ipAddress: json['ipAddress'],
      isAutoVerified: json['isAutoVerified'] ?? false,
    );
  }
}

/// Geo location for check-in verification
@immutable
class GeoLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'address': address,
  };

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      address: json['address'],
    );
  }

  /// Calculate distance to another location in kilometers
  double distanceTo(GeoLocation other) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(latitude)) * _cos(_toRadians(other.latitude)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120; // Approximation
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24; // Approximation
  double _sqrt(double x) => x > 0 ? _newtonSqrt(x, x / 2, 10) : 0;
  double _newtonSqrt(double x, double guess, int iterations) {
    if (iterations == 0) return guess;
    return _newtonSqrt(x, (guess + x / guess) / 2, iterations - 1);
  }
  double _atan2(double y, double x) => y / (x + 0.001); // Simplified approximation
}

/// Booking lifecycle status
enum BookingLifecycleStatus {
  /// Booking confirmed, awaiting event date
  scheduled,

  /// Artist has indicated they are en route to venue
  enRoute,

  /// Artist has arrived at venue area
  arrived,

  /// Artist has checked in at venue (verified)
  checkedIn,

  /// Sound check or preparation in progress
  preparing,

  /// Performance has started
  performing,

  /// Short break during performance
  onBreak,

  /// Performance completed successfully
  completed,

  /// Artist did not perform (no-show or refusal)
  didNotPerform,

  /// Event cancelled before performance
  cancelled,

  /// Under dispute resolution
  disputed,

  /// Rescheduled to new date
  rescheduled,
}

/// Verification types
enum VerificationType {
  selfReported,
  locationBased,
  photoVerified,
  qrCodeScan,
  otherPartyConfirmed,
  systemAutomatic,
  adminOverride,
}

/// Artist arrival tracking
@immutable
class ArrivalTracking {
  final String bookingId;
  final DateTime expectedArrival;
  final DateTime? actualArrival;
  final int gracePeriodMinutes;
  final bool isWithinGracePeriod;
  final int? minutesLate;
  final String? delayReason;
  final bool wasNotified;

  const ArrivalTracking({
    required this.bookingId,
    required this.expectedArrival,
    this.actualArrival,
    this.gracePeriodMinutes = 30,
    this.isWithinGracePeriod = true,
    this.minutesLate,
    this.delayReason,
    this.wasNotified = false,
  });

  /// Check arrival status
  ArrivalStatus get status {
    if (actualArrival == null) {
      if (DateTime.now().isAfter(expectedArrival.add(Duration(minutes: gracePeriodMinutes)))) {
        return ArrivalStatus.overdue;
      } else if (DateTime.now().isAfter(expectedArrival)) {
        return ArrivalStatus.late;
      }
      return ArrivalStatus.pending;
    }

    if (actualArrival!.isBefore(expectedArrival)) {
      return ArrivalStatus.early;
    } else if (actualArrival!.isBefore(expectedArrival.add(Duration(minutes: gracePeriodMinutes)))) {
      return ArrivalStatus.onTime;
    }
    return ArrivalStatus.late;
  }

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'expectedArrival': expectedArrival.toIso8601String(),
    'actualArrival': actualArrival?.toIso8601String(),
    'gracePeriodMinutes': gracePeriodMinutes,
    'isWithinGracePeriod': isWithinGracePeriod,
    'minutesLate': minutesLate,
    'delayReason': delayReason,
    'wasNotified': wasNotified,
  };
}

/// Arrival status
enum ArrivalStatus {
  pending,
  early,
  onTime,
  late,
  overdue,
}

