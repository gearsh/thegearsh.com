// Gearsh Booking Infrastructure Service
// Central orchestration of all booking-related services

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'booking_agreement_service.dart';
import 'escrow_service.dart';
import 'booking_lifecycle_service.dart';
import 'incident_report_service.dart';
import 'communication_log_service.dart';
import 'reliability_index_service.dart';

/// Central service for orchestrating booking infrastructure
/// This is the main entry point for booking-related operations
class BookingInfrastructureService {
  static final BookingInfrastructureService _instance =
      BookingInfrastructureService._internal();
  factory BookingInfrastructureService() => _instance;
  BookingInfrastructureService._internal();

  /// Initialize all infrastructure for a new booking
  Future<BookingInfrastructure> initializeBooking({
    required String bookingId,
    required String artistId,
    required String clientId,
    required PerformanceDetails performance,
    required FinancialTerms financialTerms,
    HospitalityRider? rider,
  }) async {
    debugPrint('[Infrastructure] Initializing booking $bookingId');

    // 1. Create booking agreement
    final agreement = await bookingAgreementService.createAgreement(
      bookingId: bookingId,
      artistId: artistId,
      clientId: clientId,
      performance: performance,
      financialTerms: financialTerms,
      rider: rider,
    );

    // 2. Create escrow
    final escrow = await escrowService.createEscrow(
      bookingId: bookingId,
      agreementId: agreement.id,
      payerId: clientId,
      payeeId: artistId,
      amount: financialTerms.grandTotal,
      currencyCode: financialTerms.currencyCode,
    );

    // 3. Create lifecycle tracker
    final lifecycle = await bookingLifecycleService.createLifecycle(bookingId);

    // 4. Set up arrival tracking
    await bookingLifecycleService.setupArrivalTracking(
      bookingId: bookingId,
      expectedArrival: performance.arrivalDeadline,
      gracePeriodMinutes: performance.gracePeriodMinutes,
    );

    // 5. Create communication thread
    final thread = await communicationLogService.createThread(
      bookingId: bookingId,
      participantIds: [artistId, clientId],
    );

    // 6. Ensure reliability indices exist
    await reliabilityIndexService.getOrCreateIndex(
      userId: artistId,
      userRole: 'artist',
    );
    await reliabilityIndexService.getOrCreateIndex(
      userId: clientId,
      userRole: 'client',
    );

    debugPrint('[Infrastructure] Booking $bookingId fully initialized');

    return BookingInfrastructure(
      bookingId: bookingId,
      agreementId: agreement.id,
      escrowId: escrow.id,
      lifecycleId: lifecycle.id,
      threadId: thread.id,
    );
  }

  /// Process artist check-in with all related updates
  Future<void> processArtistCheckIn({
    required String bookingId,
    required String artistId,
    required GeoLocation location,
    String? verifiedBy,
  }) async {
    debugPrint('[Infrastructure] Processing check-in for booking $bookingId');

    // Update lifecycle
    await bookingLifecycleService.markCheckedIn(
      bookingId: bookingId,
      artistId: artistId,
      location: location,
      verifiedBy: verifiedBy,
    );

    // Record arrival event for reliability
    final tracking = bookingLifecycleService.getArrivalTracking(bookingId);
    if (tracking != null) {
      final eventType = tracking.status == ArrivalStatus.onTime ||
                        tracking.status == ArrivalStatus.early
          ? ReliabilityEventType.arrivedOnTime
          : ReliabilityEventType.arrivedLate;

      await reliabilityIndexService.recordEvent(
        userId: artistId,
        type: eventType,
        bookingId: bookingId,
      );
    }

    // Send system message to thread
    final thread = await communicationLogService.getThreadForBooking(bookingId);
    if (thread != null) {
      await communicationLogService.sendSystemMessage(
        threadId: thread.id,
        content: 'Artist has checked in at the venue.',
        type: MessageType.statusUpdate,
      );
    }
  }

  /// Process performance start
  Future<void> processPerformanceStart({
    required String bookingId,
    required String confirmedBy,
    required String confirmedByRole,
  }) async {
    debugPrint('[Infrastructure] Processing performance start for $bookingId');

    await bookingLifecycleService.markPerformanceStarted(
      bookingId: bookingId,
      confirmedBy: confirmedBy,
      confirmedByRole: confirmedByRole,
    );

    // Send system message
    final thread = await communicationLogService.getThreadForBooking(bookingId);
    if (thread != null) {
      await communicationLogService.sendSystemMessage(
        threadId: thread.id,
        content: 'Performance has started.',
        type: MessageType.statusUpdate,
      );
    }
  }

  /// Process performance completion
  Future<void> processPerformanceComplete({
    required String bookingId,
    required String confirmedBy,
    required String confirmedByRole,
  }) async {
    debugPrint('[Infrastructure] Processing completion for $bookingId');

    // Update lifecycle
    await bookingLifecycleService.markCompleted(
      bookingId: bookingId,
      confirmedBy: confirmedBy,
      confirmedByRole: confirmedByRole,
    );

    // Get artist and client IDs from agreement
    final agreement = await bookingAgreementService.getAgreementForBooking(bookingId);
    if (agreement != null) {
      // Update reliability indices
      await reliabilityIndexService.recordEvent(
        userId: agreement.artistId,
        type: ReliabilityEventType.bookingCompleted,
        bookingId: bookingId,
      );
      await reliabilityIndexService.recordEvent(
        userId: agreement.clientId,
        type: ReliabilityEventType.bookingCompleted,
        bookingId: bookingId,
      );
    }

    // Send system message
    final thread = await communicationLogService.getThreadForBooking(bookingId);
    if (thread != null) {
      await communicationLogService.sendSystemMessage(
        threadId: thread.id,
        content: 'Performance completed successfully. Thank you for using Gearsh.',
        type: MessageType.statusUpdate,
      );
    }
  }

  /// Process incident report
  Future<IncidentReport?> processIncidentReport({
    required String bookingId,
    required String reporterId,
    required String reporterRole,
    required IncidentType type,
    required String description,
    IncidentSeverity severity = IncidentSeverity.medium,
  }) async {
    debugPrint('[Infrastructure] Processing incident for $bookingId');

    // Submit incident
    final report = await incidentReportService.submitReport(
      bookingId: bookingId,
      reporterId: reporterId,
      reporterRole: reporterRole,
      type: type,
      description: description,
      severity: severity,
    );

    // Record incident event for reliability
    await reliabilityIndexService.recordEvent(
      userId: reporterId,
      type: ReliabilityEventType.incidentReported,
      bookingId: bookingId,
    );

    // If high severity, place escrow under dispute
    if (severity == IncidentSeverity.high || severity == IncidentSeverity.critical) {
      final escrow = await escrowService.getEscrowForBooking(bookingId);
      if (escrow != null) {
        await escrowService.disputeEscrow(
          escrowId: escrow.id,
          disputeId: report.id,
        );
      }
    }

    return report;
  }

  /// Process cancellation
  Future<void> processCancellation({
    required String bookingId,
    required String cancelledBy,
    required String cancelledByRole,
    required String reason,
    bool fullRefund = false,
  }) async {
    debugPrint('[Infrastructure] Processing cancellation for $bookingId');

    // Update lifecycle
    await bookingLifecycleService.updateStatus(
      bookingId: bookingId,
      newStatus: BookingLifecycleStatus.cancelled,
      updatedBy: cancelledBy,
      updatedByRole: cancelledByRole,
      notes: 'Cancelled: $reason',
    );

    // Handle escrow
    final escrow = await escrowService.getEscrowForBooking(bookingId);
    if (escrow != null && fullRefund) {
      await escrowService.refundFunds(
        escrowId: escrow.id,
        amount: escrow.remainingAmount,
        refundedBy: 'system',
        reason: 'Booking cancelled: $reason',
      );
    }

    // Update reliability indices
    final agreement = await bookingAgreementService.getAgreementForBooking(bookingId);
    if (agreement != null) {
      await reliabilityIndexService.recordEvent(
        userId: cancelledBy,
        type: ReliabilityEventType.bookingCancelled,
        bookingId: bookingId,
      );
    }

    // Send system message
    final thread = await communicationLogService.getThreadForBooking(bookingId);
    if (thread != null) {
      await communicationLogService.sendSystemMessage(
        threadId: thread.id,
        content: 'This booking has been cancelled.',
        type: MessageType.statusUpdate,
      );
    }
  }

  /// Get full booking audit trail
  Future<BookingAuditTrail> getAuditTrail(String bookingId) async {
    final agreement = await bookingAgreementService.getAgreementForBooking(bookingId);
    final escrow = await escrowService.getEscrowForBooking(bookingId);
    final lifecycle = await bookingLifecycleService.getLifecycleForBooking(bookingId);
    final thread = await communicationLogService.getThreadForBooking(bookingId);
    final incidents = await incidentReportService.getIncidentsForBooking(bookingId);

    return BookingAuditTrail(
      bookingId: bookingId,
      agreement: agreement,
      escrow: escrow,
      lifecycle: lifecycle,
      thread: thread,
      incidents: incidents,
      statusHistory: bookingLifecycleService.getStatusHistory(bookingId),
      escrowTransactions: escrow != null ? escrowService.getTransactions(escrow.id) : [],
      amendments: agreement != null ? bookingAgreementService.getAmendments(agreement.id) : [],
      silencePeriods: thread != null ? communicationLogService.getSilencePeriods(thread.id) : [],
    );
  }
}

/// Singleton instance
final bookingInfrastructureService = BookingInfrastructureService();

/// Infrastructure IDs for a booking
class BookingInfrastructure {
  final String bookingId;
  final String agreementId;
  final String escrowId;
  final String lifecycleId;
  final String threadId;

  const BookingInfrastructure({
    required this.bookingId,
    required this.agreementId,
    required this.escrowId,
    required this.lifecycleId,
    required this.threadId,
  });
}

/// Complete audit trail for a booking
class BookingAuditTrail {
  final String bookingId;
  final BookingAgreement? agreement;
  final EscrowPayment? escrow;
  final BookingLifecycle? lifecycle;
  final BookingCommunicationThread? thread;
  final List<IncidentReport> incidents;
  final List<StatusEvent> statusHistory;
  final List<EscrowTransaction> escrowTransactions;
  final List<AgreementAmendment> amendments;
  final List<SilencePeriod> silencePeriods;

  const BookingAuditTrail({
    required this.bookingId,
    this.agreement,
    this.escrow,
    this.lifecycle,
    this.thread,
    this.incidents = const [],
    this.statusHistory = const [],
    this.escrowTransactions = const [],
    this.amendments = const [],
    this.silencePeriods = const [],
  });
}

