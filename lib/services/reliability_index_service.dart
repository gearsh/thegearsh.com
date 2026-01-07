// Gearsh Reliability Index Service
// Private, non-punitive reliability tracking

import 'package:flutter/foundation.dart';
import '../models/reliability_index.dart';

/// Service for managing private reliability indices
class ReliabilityIndexService {
  static final ReliabilityIndexService _instance = ReliabilityIndexService._internal();
  factory ReliabilityIndexService() => _instance;
  ReliabilityIndexService._internal();

  // In-memory storage (replace with API calls in production)
  final Map<String, ReliabilityIndex> _indices = {};
  final List<ReliabilityEvent> _events = [];

  /// Get or create reliability index for a user
  Future<ReliabilityIndex> getOrCreateIndex({
    required String userId,
    required String userRole,
  }) async {
    if (_indices.containsKey(userId)) {
      return _indices[userId]!;
    }

    final index = ReliabilityIndex.empty(userId: userId, userRole: userRole);
    _indices[userId] = index;
    debugPrint('[ReliabilityService] Created index for user $userId');
    return index;
  }

  /// Record a reliability event
  Future<ReliabilityIndex?> recordEvent({
    required String userId,
    required ReliabilityEventType type,
    String? bookingId,
    Map<String, dynamic>? metadata,
  }) async {
    final index = _indices[userId];
    if (index == null) return null;

    // Record the event
    final event = ReliabilityEvent(
      id: _generateId(),
      userId: userId,
      type: type,
      occurredAt: DateTime.now(),
      bookingId: bookingId,
      metadata: metadata,
    );
    _events.add(event);

    // Update index based on event type
    final updated = _updateIndexForEvent(index, type, metadata);
    _indices[userId] = updated;

    debugPrint('[ReliabilityService] Recorded ${type.name} for user $userId');
    return updated;
  }

  /// Update index based on event type
  ReliabilityIndex _updateIndexForEvent(
    ReliabilityIndex index,
    ReliabilityEventType type,
    Map<String, dynamic>? metadata,
  ) {
    switch (type) {
      case ReliabilityEventType.bookingCompleted:
        return _recalculateIndex(index.copyWith(
          totalBookings: index.totalBookings + 1,
          completedBookings: index.completedBookings + 1,
        ));

      case ReliabilityEventType.bookingCancelled:
        return _recalculateIndex(index.copyWith(
          totalBookings: index.totalBookings + 1,
          cancelledBookings: index.cancelledBookings + 1,
        ));

      case ReliabilityEventType.bookingDisputed:
        return _recalculateIndex(index.copyWith(
          disputedBookings: index.disputedBookings + 1,
        ));

      case ReliabilityEventType.bookingRescheduled:
        return _recalculateIndex(index.copyWith(
          rescheduledBookings: index.rescheduledBookings + 1,
        ));

      case ReliabilityEventType.arrivedOnTime:
        return index.copyWith(
          onTimeArrivals: index.onTimeArrivals + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.arrivedLate:
        return index.copyWith(
          lateArrivals: index.lateArrivals + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.noShow:
        return index.copyWith(
          noShows: index.noShows + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.messageReceived:
        return index.copyWith(
          totalMessagesReceived: index.totalMessagesReceived + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.messageResponded:
        return index.copyWith(
          totalMessagesResponded: index.totalMessagesResponded + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.paymentOnTime:
        return index.copyWith(
          onTimePayments: index.onTimePayments + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.paymentLate:
        return index.copyWith(
          latePayments: index.latePayments + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.incidentReported:
        return index.copyWith(
          incidentsReported: index.incidentsReported + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.incidentAgainst:
        return index.copyWith(
          incidentsAgainst: index.incidentsAgainst + 1,
          lastUpdated: DateTime.now(),
        );

      case ReliabilityEventType.incidentResolved:
        return index.copyWith(
          incidentsResolved: index.incidentsResolved + 1,
          lastUpdated: DateTime.now(),
        );
    }
  }

  /// Recalculate derived rates
  ReliabilityIndex _recalculateIndex(ReliabilityIndex index) {
    final completionRate = index.totalBookings > 0
        ? (index.completedBookings / index.totalBookings) * 100
        : 0.0;

    final cancellationRate = index.totalBookings > 0
        ? (index.cancelledBookings / index.totalBookings) * 100
        : 0.0;

    final disputeRate = index.totalBookings > 0
        ? (index.disputedBookings / index.totalBookings) * 100
        : 0.0;

    return index.copyWith(
      completionRate: completionRate,
      cancellationRate: cancellationRate,
      disputeRate: disputeRate,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get reliability index for a user (private, internal use only)
  Future<ReliabilityIndex?> getIndex(String userId) async {
    return _indices[userId];
  }

  /// Get reliability context (summary without raw numbers)
  /// This is what would be shown to internal staff, never public
  Future<ReliabilityContext?> getContext(String userId) async {
    final index = _indices[userId];
    return index?.context;
  }

  /// Check if user has any concerning patterns (for internal flagging only)
  Future<bool> hasConcerningPatterns(String userId) async {
    final index = _indices[userId];
    if (index == null) return false;

    // These thresholds are for internal monitoring only
    // Never shown to users or used punitively
    return index.noShows > 2 ||
           index.cancellationRate > 30 ||
           index.disputeRate > 20;
  }

  /// Get event history for a user (audit purposes)
  List<ReliabilityEvent> getEventHistory(String userId) {
    return _events.where((e) => e.userId == userId).toList();
  }

  /// Update response time average
  Future<void> updateResponseTime({
    required String userId,
    required Duration responseTime,
  }) async {
    final index = _indices[userId];
    if (index == null) return;

    final currentAvg = index.averageResponseTimeHours ?? responseTime.inHours.toDouble();
    final totalResponses = index.totalMessagesResponded;

    // Calculate new weighted average
    final newAvg = ((currentAvg * totalResponses) + responseTime.inHours) / (totalResponses + 1);

    _indices[userId] = index.copyWith(
      averageResponseTimeHours: newAvg,
      lastUpdated: DateTime.now(),
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Singleton instance
final reliabilityIndexService = ReliabilityIndexService();

