// Gearsh Reliability Index Model
// Private, non-punitive reliability context for users

import 'package:flutter/foundation.dart';

/// Private reliability context for a user (artist or organiser)
/// This data is NEVER public and carries no labels or judgements
@immutable
class ReliabilityIndex {
  final String userId;
  final String userRole; // 'artist' or 'client'
  final DateTime lastUpdated;

  // Booking statistics
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int disputedBookings;
  final int rescheduledBookings;

  // Arrival metrics (for artists)
  final int onTimeArrivals;
  final int lateArrivals;
  final int noShows;
  final double? averageArrivalMinutesEarly; // Positive = early, negative = late

  // Communication metrics
  final double? averageResponseTimeHours;
  final int totalMessagesReceived;
  final int totalMessagesResponded;

  // Completion metrics
  final double completionRate; // Percentage 0-100
  final double cancellationRate; // Percentage 0-100
  final double disputeRate; // Percentage 0-100

  // Incident history (counts only, no details)
  final int incidentsReported;
  final int incidentsAgainst;
  final int incidentsResolved;

  // Payment metrics (for clients)
  final int onTimePayments;
  final int latePayments;
  final int paymentDisputes;

  const ReliabilityIndex({
    required this.userId,
    required this.userRole,
    required this.lastUpdated,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.disputedBookings = 0,
    this.rescheduledBookings = 0,
    this.onTimeArrivals = 0,
    this.lateArrivals = 0,
    this.noShows = 0,
    this.averageArrivalMinutesEarly,
    this.averageResponseTimeHours,
    this.totalMessagesReceived = 0,
    this.totalMessagesResponded = 0,
    this.completionRate = 0,
    this.cancellationRate = 0,
    this.disputeRate = 0,
    this.incidentsReported = 0,
    this.incidentsAgainst = 0,
    this.incidentsResolved = 0,
    this.onTimePayments = 0,
    this.latePayments = 0,
    this.paymentDisputes = 0,
  });

  /// Calculate response rate
  double get responseRate {
    if (totalMessagesReceived == 0) return 100;
    return (totalMessagesResponded / totalMessagesReceived) * 100;
  }

  /// Calculate on-time rate for artists
  double get onTimeRate {
    final totalArrivals = onTimeArrivals + lateArrivals + noShows;
    if (totalArrivals == 0) return 100;
    return (onTimeArrivals / totalArrivals) * 100;
  }

  /// Calculate payment reliability for clients
  double get paymentReliabilityRate {
    final totalPayments = onTimePayments + latePayments;
    if (totalPayments == 0) return 100;
    return (onTimePayments / totalPayments) * 100;
  }

  /// Get contextual summary (private, never shown publicly)
  ReliabilityContext get context {
    // This provides context without judgement
    return ReliabilityContext(
      totalBookingsContext: _getBookingsContext(),
      completionContext: _getCompletionContext(),
      communicationContext: _getCommunicationContext(),
      arrivalContext: userRole == 'artist' ? _getArrivalContext() : null,
      paymentContext: userRole == 'client' ? _getPaymentContext() : null,
    );
  }

  String _getBookingsContext() {
    if (totalBookings == 0) return 'New user, no booking history';
    if (totalBookings < 5) return 'Limited booking history';
    if (totalBookings < 20) return 'Some booking history';
    return 'Established booking history';
  }

  String _getCompletionContext() {
    if (totalBookings == 0) return 'No completed bookings yet';
    if (completionRate >= 95) return 'Very high completion rate';
    if (completionRate >= 80) return 'Good completion rate';
    if (completionRate >= 60) return 'Moderate completion rate';
    return 'Lower completion rate';
  }

  String _getCommunicationContext() {
    if (totalMessagesReceived == 0) return 'No communication history';
    if (responseRate >= 90) return 'Very responsive communicator';
    if (responseRate >= 70) return 'Generally responsive';
    if (responseRate >= 50) return 'Sometimes responsive';
    return 'Limited responsiveness';
  }

  String _getArrivalContext() {
    final totalArrivals = onTimeArrivals + lateArrivals + noShows;
    if (totalArrivals == 0) return 'No arrival data';
    if (noShows > 0) return 'Has missed arrivals ($noShows)';
    if (onTimeRate >= 90) return 'Usually arrives on time';
    if (onTimeRate >= 70) return 'Generally punctual';
    return 'Sometimes late';
  }

  String _getPaymentContext() {
    final totalPayments = onTimePayments + latePayments;
    if (totalPayments == 0) return 'No payment history';
    if (paymentReliabilityRate >= 95) return 'Consistent payment record';
    if (paymentReliabilityRate >= 80) return 'Generally timely payments';
    return 'Some payment delays';
  }

  ReliabilityIndex copyWith({
    String? userId,
    String? userRole,
    DateTime? lastUpdated,
    int? totalBookings,
    int? completedBookings,
    int? cancelledBookings,
    int? disputedBookings,
    int? rescheduledBookings,
    int? onTimeArrivals,
    int? lateArrivals,
    int? noShows,
    double? averageArrivalMinutesEarly,
    double? averageResponseTimeHours,
    int? totalMessagesReceived,
    int? totalMessagesResponded,
    double? completionRate,
    double? cancellationRate,
    double? disputeRate,
    int? incidentsReported,
    int? incidentsAgainst,
    int? incidentsResolved,
    int? onTimePayments,
    int? latePayments,
    int? paymentDisputes,
  }) {
    return ReliabilityIndex(
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalBookings: totalBookings ?? this.totalBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      disputedBookings: disputedBookings ?? this.disputedBookings,
      rescheduledBookings: rescheduledBookings ?? this.rescheduledBookings,
      onTimeArrivals: onTimeArrivals ?? this.onTimeArrivals,
      lateArrivals: lateArrivals ?? this.lateArrivals,
      noShows: noShows ?? this.noShows,
      averageArrivalMinutesEarly: averageArrivalMinutesEarly ?? this.averageArrivalMinutesEarly,
      averageResponseTimeHours: averageResponseTimeHours ?? this.averageResponseTimeHours,
      totalMessagesReceived: totalMessagesReceived ?? this.totalMessagesReceived,
      totalMessagesResponded: totalMessagesResponded ?? this.totalMessagesResponded,
      completionRate: completionRate ?? this.completionRate,
      cancellationRate: cancellationRate ?? this.cancellationRate,
      disputeRate: disputeRate ?? this.disputeRate,
      incidentsReported: incidentsReported ?? this.incidentsReported,
      incidentsAgainst: incidentsAgainst ?? this.incidentsAgainst,
      incidentsResolved: incidentsResolved ?? this.incidentsResolved,
      onTimePayments: onTimePayments ?? this.onTimePayments,
      latePayments: latePayments ?? this.latePayments,
      paymentDisputes: paymentDisputes ?? this.paymentDisputes,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userRole': userRole,
    'lastUpdated': lastUpdated.toIso8601String(),
    'totalBookings': totalBookings,
    'completedBookings': completedBookings,
    'cancelledBookings': cancelledBookings,
    'disputedBookings': disputedBookings,
    'rescheduledBookings': rescheduledBookings,
    'onTimeArrivals': onTimeArrivals,
    'lateArrivals': lateArrivals,
    'noShows': noShows,
    'averageArrivalMinutesEarly': averageArrivalMinutesEarly,
    'averageResponseTimeHours': averageResponseTimeHours,
    'totalMessagesReceived': totalMessagesReceived,
    'totalMessagesResponded': totalMessagesResponded,
    'completionRate': completionRate,
    'cancellationRate': cancellationRate,
    'disputeRate': disputeRate,
    'incidentsReported': incidentsReported,
    'incidentsAgainst': incidentsAgainst,
    'incidentsResolved': incidentsResolved,
    'onTimePayments': onTimePayments,
    'latePayments': latePayments,
    'paymentDisputes': paymentDisputes,
  };

  factory ReliabilityIndex.fromJson(Map<String, dynamic> json) {
    return ReliabilityIndex(
      userId: json['userId'],
      userRole: json['userRole'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      disputedBookings: json['disputedBookings'] ?? 0,
      rescheduledBookings: json['rescheduledBookings'] ?? 0,
      onTimeArrivals: json['onTimeArrivals'] ?? 0,
      lateArrivals: json['lateArrivals'] ?? 0,
      noShows: json['noShows'] ?? 0,
      averageArrivalMinutesEarly: (json['averageArrivalMinutesEarly'] as num?)?.toDouble(),
      averageResponseTimeHours: (json['averageResponseTimeHours'] as num?)?.toDouble(),
      totalMessagesReceived: json['totalMessagesReceived'] ?? 0,
      totalMessagesResponded: json['totalMessagesResponded'] ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      cancellationRate: (json['cancellationRate'] as num?)?.toDouble() ?? 0,
      disputeRate: (json['disputeRate'] as num?)?.toDouble() ?? 0,
      incidentsReported: json['incidentsReported'] ?? 0,
      incidentsAgainst: json['incidentsAgainst'] ?? 0,
      incidentsResolved: json['incidentsResolved'] ?? 0,
      onTimePayments: json['onTimePayments'] ?? 0,
      latePayments: json['latePayments'] ?? 0,
      paymentDisputes: json['paymentDisputes'] ?? 0,
    );
  }

  /// Create a new empty reliability index for a user
  factory ReliabilityIndex.empty({required String userId, required String userRole}) {
    return ReliabilityIndex(
      userId: userId,
      userRole: userRole,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Contextual summary of reliability (never shown publicly)
@immutable
class ReliabilityContext {
  final String totalBookingsContext;
  final String completionContext;
  final String communicationContext;
  final String? arrivalContext; // For artists only
  final String? paymentContext; // For clients only

  const ReliabilityContext({
    required this.totalBookingsContext,
    required this.completionContext,
    required this.communicationContext,
    this.arrivalContext,
    this.paymentContext,
  });
}

/// Event that updates reliability metrics
@immutable
class ReliabilityEvent {
  final String id;
  final String userId;
  final ReliabilityEventType type;
  final DateTime occurredAt;
  final String? bookingId;
  final Map<String, dynamic>? metadata;

  const ReliabilityEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.occurredAt,
    this.bookingId,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'occurredAt': occurredAt.toIso8601String(),
    'bookingId': bookingId,
    'metadata': metadata,
  };
}

/// Types of events that affect reliability index
enum ReliabilityEventType {
  bookingCompleted,
  bookingCancelled,
  bookingDisputed,
  bookingRescheduled,
  arrivedOnTime,
  arrivedLate,
  noShow,
  messageReceived,
  messageResponded,
  paymentOnTime,
  paymentLate,
  incidentReported,
  incidentAgainst,
  incidentResolved,
}

