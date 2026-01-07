// Gearsh Booking Lifecycle Service
// Manages booking status tracking with time-stamped audit trail

import 'package:flutter/foundation.dart';
import '../models/booking_lifecycle.dart';
import 'escrow_service.dart';

/// Service for managing booking lifecycle and status tracking
class BookingLifecycleService {
  static final BookingLifecycleService _instance = BookingLifecycleService._internal();
  factory BookingLifecycleService() => _instance;
  BookingLifecycleService._internal();

  // In-memory storage (replace with API calls in production)
  final Map<String, BookingLifecycle> _lifecycles = {};
  final Map<String, ArrivalTracking> _arrivalTracking = {};

  /// Create a new lifecycle for a booking
  Future<BookingLifecycle> createLifecycle(String bookingId) async {
    final initialEvent = StatusEvent(
      id: _generateId(),
      status: BookingLifecycleStatus.scheduled,
      timestamp: DateTime.now(),
      updatedByRole: 'system',
      notes: 'Booking confirmed and scheduled',
    );

    final lifecycle = BookingLifecycle(
      id: _generateId(),
      bookingId: bookingId,
      currentStatus: BookingLifecycleStatus.scheduled,
      statusHistory: [initialEvent],
      createdAt: DateTime.now(),
    );

    _lifecycles[lifecycle.id] = lifecycle;
    debugPrint('[LifecycleService] Created lifecycle for booking $bookingId');
    return lifecycle;
  }

  /// Update booking status with verification
  Future<BookingLifecycle?> updateStatus({
    required String bookingId,
    required BookingLifecycleStatus newStatus,
    required String updatedBy,
    required String updatedByRole,
    StatusVerification? verification,
    String? notes,
    GeoLocation? location,
  }) async {
    final lifecycle = await getLifecycleForBooking(bookingId);
    if (lifecycle == null) return null;

    // Validate status transition
    if (!_isValidTransition(lifecycle.currentStatus, newStatus)) {
      debugPrint('[LifecycleService] Invalid transition from ${lifecycle.currentStatus} to $newStatus');
      return null;
    }

    final event = StatusEvent(
      id: _generateId(),
      status: newStatus,
      timestamp: DateTime.now(),
      updatedBy: updatedBy,
      updatedByRole: updatedByRole,
      verification: verification,
      notes: notes,
      location: location,
    );

    final updated = lifecycle.addStatus(event);
    _lifecycles[lifecycle.id] = updated;

    // Trigger escrow conditions based on status
    await _triggerEscrowConditions(bookingId, newStatus);

    debugPrint('[LifecycleService] Status updated to $newStatus for booking $bookingId');
    return updated;
  }

  /// Record artist as en route
  Future<BookingLifecycle?> markEnRoute({
    required String bookingId,
    required String artistId,
    GeoLocation? currentLocation,
    String? notes,
  }) async {
    return updateStatus(
      bookingId: bookingId,
      newStatus: BookingLifecycleStatus.enRoute,
      updatedBy: artistId,
      updatedByRole: 'artist',
      location: currentLocation,
      notes: notes ?? 'Artist en route to venue',
    );
  }

  /// Record artist arrival
  Future<BookingLifecycle?> markArrived({
    required String bookingId,
    required String artistId,
    required GeoLocation location,
    String? notes,
  }) async {
    // Update arrival tracking
    final tracking = _arrivalTracking[bookingId];
    if (tracking != null) {
      _arrivalTracking[bookingId] = ArrivalTracking(
        bookingId: bookingId,
        expectedArrival: tracking.expectedArrival,
        actualArrival: DateTime.now(),
        gracePeriodMinutes: tracking.gracePeriodMinutes,
        isWithinGracePeriod: DateTime.now().isBefore(
          tracking.expectedArrival.add(Duration(minutes: tracking.gracePeriodMinutes)),
        ),
        minutesLate: DateTime.now().isAfter(tracking.expectedArrival)
            ? DateTime.now().difference(tracking.expectedArrival).inMinutes
            : null,
      );
    }

    return updateStatus(
      bookingId: bookingId,
      newStatus: BookingLifecycleStatus.arrived,
      updatedBy: artistId,
      updatedByRole: 'artist',
      location: location,
      verification: StatusVerification(
        type: VerificationType.locationBased,
        isAutoVerified: true,
      ),
      notes: notes ?? 'Artist arrived at venue area',
    );
  }

  /// Record artist check-in (verified)
  Future<BookingLifecycle?> markCheckedIn({
    required String bookingId,
    required String artistId,
    required GeoLocation location,
    String? verifiedBy,
    String? photoUrl,
  }) async {
    return updateStatus(
      bookingId: bookingId,
      newStatus: BookingLifecycleStatus.checkedIn,
      updatedBy: artistId,
      updatedByRole: 'artist',
      location: location,
      verification: StatusVerification(
        type: verifiedBy != null
            ? VerificationType.otherPartyConfirmed
            : VerificationType.locationBased,
        photoUrl: photoUrl,
        confirmedBy: verifiedBy,
        confirmedAt: verifiedBy != null ? DateTime.now() : null,
      ),
      notes: 'Artist checked in at venue',
    );
  }

  /// Record performance started
  Future<BookingLifecycle?> markPerformanceStarted({
    required String bookingId,
    required String confirmedBy,
    required String confirmedByRole,
  }) async {
    return updateStatus(
      bookingId: bookingId,
      newStatus: BookingLifecycleStatus.performing,
      updatedBy: confirmedBy,
      updatedByRole: confirmedByRole,
      verification: StatusVerification(
        type: VerificationType.otherPartyConfirmed,
        confirmedBy: confirmedBy,
        confirmedAt: DateTime.now(),
      ),
      notes: 'Performance started',
    );
  }

  /// Record performance completed
  Future<BookingLifecycle?> markCompleted({
    required String bookingId,
    required String confirmedBy,
    required String confirmedByRole,
    String? notes,
  }) async {
    return updateStatus(
      bookingId: bookingId,
      newStatus: BookingLifecycleStatus.completed,
      updatedBy: confirmedBy,
      updatedByRole: confirmedByRole,
      verification: StatusVerification(
        type: VerificationType.otherPartyConfirmed,
        confirmedBy: confirmedBy,
        confirmedAt: DateTime.now(),
      ),
      notes: notes ?? 'Performance completed successfully',
    );
  }

  /// Record no-show or did not perform
  Future<BookingLifecycle?> markDidNotPerform({
    required String bookingId,
    required String reportedBy,
    required String reportedByRole,
    required String reason,
  }) async {
    return updateStatus(
      bookingId: bookingId,
      newStatus: BookingLifecycleStatus.didNotPerform,
      updatedBy: reportedBy,
      updatedByRole: reportedByRole,
      notes: 'Did not perform: $reason',
    );
  }

  /// Set up arrival tracking for a booking
  Future<void> setupArrivalTracking({
    required String bookingId,
    required DateTime expectedArrival,
    int gracePeriodMinutes = 30,
  }) async {
    _arrivalTracking[bookingId] = ArrivalTracking(
      bookingId: bookingId,
      expectedArrival: expectedArrival,
      gracePeriodMinutes: gracePeriodMinutes,
    );
    debugPrint('[LifecycleService] Arrival tracking set for booking $bookingId');
  }

  /// Get arrival tracking for a booking
  ArrivalTracking? getArrivalTracking(String bookingId) {
    return _arrivalTracking[bookingId];
  }

  /// Get lifecycle by ID
  Future<BookingLifecycle?> getLifecycle(String lifecycleId) async {
    return _lifecycles[lifecycleId];
  }

  /// Get lifecycle for a booking
  Future<BookingLifecycle?> getLifecycleForBooking(String bookingId) async {
    try {
      return _lifecycles.values.firstWhere((l) => l.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  /// Get full status history for a booking
  List<StatusEvent> getStatusHistory(String bookingId) {
    final lifecycle = _lifecycles.values
        .where((l) => l.bookingId == bookingId)
        .firstOrNull;
    return lifecycle?.statusHistory ?? [];
  }

  /// Validate status transitions
  bool _isValidTransition(BookingLifecycleStatus from, BookingLifecycleStatus to) {
    final validTransitions = {
      BookingLifecycleStatus.scheduled: [
        BookingLifecycleStatus.enRoute,
        BookingLifecycleStatus.cancelled,
        BookingLifecycleStatus.rescheduled,
        BookingLifecycleStatus.didNotPerform,
      ],
      BookingLifecycleStatus.enRoute: [
        BookingLifecycleStatus.arrived,
        BookingLifecycleStatus.cancelled,
        BookingLifecycleStatus.didNotPerform,
      ],
      BookingLifecycleStatus.arrived: [
        BookingLifecycleStatus.checkedIn,
        BookingLifecycleStatus.didNotPerform,
      ],
      BookingLifecycleStatus.checkedIn: [
        BookingLifecycleStatus.preparing,
        BookingLifecycleStatus.performing,
        BookingLifecycleStatus.didNotPerform,
      ],
      BookingLifecycleStatus.preparing: [
        BookingLifecycleStatus.performing,
        BookingLifecycleStatus.didNotPerform,
      ],
      BookingLifecycleStatus.performing: [
        BookingLifecycleStatus.onBreak,
        BookingLifecycleStatus.completed,
        BookingLifecycleStatus.didNotPerform,
      ],
      BookingLifecycleStatus.onBreak: [
        BookingLifecycleStatus.performing,
        BookingLifecycleStatus.completed,
      ],
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  /// Trigger escrow conditions based on status changes
  Future<void> _triggerEscrowConditions(String bookingId, BookingLifecycleStatus status) async {
    final escrow = await escrowService.getEscrowForBooking(bookingId);
    if (escrow == null) return;

    String? conditionId;
    switch (status) {
      case BookingLifecycleStatus.checkedIn:
        conditionId = '${bookingId}_checkin';
        break;
      case BookingLifecycleStatus.performing:
        conditionId = '${bookingId}_started';
        break;
      case BookingLifecycleStatus.completed:
        conditionId = '${bookingId}_completed';
        break;
      default:
        return;
    }

    await escrowService.markConditionMet(
      escrowId: escrow.id,
      conditionId: conditionId,
      verifiedBy: 'system',
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Singleton instance
final bookingLifecycleService = BookingLifecycleService();

