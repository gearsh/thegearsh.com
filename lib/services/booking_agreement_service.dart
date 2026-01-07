// Gearsh Booking Agreement Service
// Manages booking agreements, amendments, and signatures

import 'package:flutter/foundation.dart';
import '../models/booking_agreement.dart';

/// Service for managing booking agreements
class BookingAgreementService {
  static final BookingAgreementService _instance = BookingAgreementService._internal();
  factory BookingAgreementService() => _instance;
  BookingAgreementService._internal();

  // In-memory storage (replace with API calls in production)
  final Map<String, BookingAgreement> _agreements = {};

  /// Create a new booking agreement
  Future<BookingAgreement> createAgreement({
    required String bookingId,
    required String artistId,
    required String clientId,
    required PerformanceDetails performance,
    required FinancialTerms financialTerms,
    HospitalityRider? rider,
  }) async {
    final agreement = BookingAgreement(
      id: _generateId(),
      bookingId: bookingId,
      artistId: artistId,
      clientId: clientId,
      createdAt: DateTime.now(),
      performance: performance,
      financialTerms: financialTerms,
      rider: rider,
      status: AgreementStatus.draft,
    );

    _agreements[agreement.id] = agreement;
    debugPrint('[AgreementService] Created agreement ${agreement.id} for booking $bookingId');
    return agreement;
  }

  /// Get agreement by ID
  Future<BookingAgreement?> getAgreement(String agreementId) async {
    return _agreements[agreementId];
  }

  /// Get agreement for a booking
  Future<BookingAgreement?> getAgreementForBooking(String bookingId) async {
    try {
      return _agreements.values.firstWhere((a) => a.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  /// Sign agreement (artist or client)
  Future<BookingAgreement?> signAgreement({
    required String agreementId,
    required String userId,
    required bool isArtist,
    required String signature,
  }) async {
    final agreement = _agreements[agreementId];
    if (agreement == null) return null;

    final now = DateTime.now();
    BookingAgreement updated;

    if (isArtist) {
      updated = agreement.copyWith(
        artistSignature: signature,
        artistSignedAt: now,
        status: agreement.clientSignature != null
            ? AgreementStatus.confirmed
            : AgreementStatus.pendingClientSignature,
      );
    } else {
      updated = agreement.copyWith(
        clientSignature: signature,
        clientSignedAt: now,
        status: agreement.artistSignature != null
            ? AgreementStatus.confirmed
            : AgreementStatus.pendingArtistSignature,
      );
    }

    // Lock agreement once both parties sign
    if (updated.isFullySigned) {
      updated = updated.copyWith(
        isLocked: true,
        confirmedAt: now,
        status: AgreementStatus.confirmed,
      );
    }

    _agreements[agreementId] = updated;
    debugPrint('[AgreementService] Agreement $agreementId signed by ${isArtist ? 'artist' : 'client'}');
    return updated;
  }

  /// Request an amendment to a locked agreement
  Future<AgreementAmendment?> requestAmendment({
    required String agreementId,
    required String requestedBy,
    required String fieldChanged,
    String? previousValue,
    required String newValue,
    required String reason,
  }) async {
    final agreement = _agreements[agreementId];
    if (agreement == null) return null;

    if (!agreement.isLocked) {
      debugPrint('[AgreementService] Cannot amend unlocked agreement');
      return null;
    }

    final amendment = AgreementAmendment(
      id: _generateId(),
      agreementId: agreementId,
      requestedBy: requestedBy,
      requestedAt: DateTime.now(),
      fieldChanged: fieldChanged,
      previousValue: previousValue,
      newValue: newValue,
      reason: reason,
      status: AmendmentStatus.pending,
    );

    final updated = agreement.copyWith(
      amendments: [...agreement.amendments, amendment],
      status: AgreementStatus.amended,
    );

    _agreements[agreementId] = updated;
    debugPrint('[AgreementService] Amendment requested for agreement $agreementId');
    return amendment;
  }

  /// Approve or reject an amendment
  Future<BookingAgreement?> resolveAmendment({
    required String agreementId,
    required String amendmentId,
    required bool approve,
    required String resolvedBy,
    String? rejectionReason,
  }) async {
    final agreement = _agreements[agreementId];
    if (agreement == null) return null;

    final updatedAmendments = agreement.amendments.map((a) {
      if (a.id == amendmentId) {
        return AgreementAmendment(
          id: a.id,
          agreementId: a.agreementId,
          requestedBy: a.requestedBy,
          requestedAt: a.requestedAt,
          fieldChanged: a.fieldChanged,
          previousValue: a.previousValue,
          newValue: a.newValue,
          reason: a.reason,
          status: approve ? AmendmentStatus.approved : AmendmentStatus.rejected,
          approvedBy: resolvedBy,
          approvedAt: DateTime.now(),
          rejectionReason: rejectionReason,
        );
      }
      return a;
    }).toList();

    final updated = agreement.copyWith(
      amendments: updatedAmendments,
      status: AgreementStatus.confirmed,
    );

    _agreements[agreementId] = updated;
    debugPrint('[AgreementService] Amendment $amendmentId ${approve ? 'approved' : 'rejected'}');
    return updated;
  }

  /// Lock the hospitality rider
  Future<BookingAgreement?> lockRider(String agreementId) async {
    final agreement = _agreements[agreementId];
    if (agreement == null || agreement.rider == null) return null;

    final lockedRider = HospitalityRider(
      items: agreement.rider!.items,
      inclusions: agreement.rider!.inclusions,
      exclusions: agreement.rider!.exclusions,
      dressingRoomRequirements: agreement.rider!.dressingRoomRequirements,
      guestListSpots: agreement.rider!.guestListSpots,
      cateringRequirements: agreement.rider!.cateringRequirements,
      transportRequirements: agreement.rider!.transportRequirements,
      accommodationRequirements: agreement.rider!.accommodationRequirements,
      additionalNotes: agreement.rider!.additionalNotes,
      isLocked: true,
      lockedAt: DateTime.now(),
    );

    final updated = agreement.copyWith(rider: lockedRider);
    _agreements[agreementId] = updated;
    debugPrint('[AgreementService] Rider locked for agreement $agreementId');
    return updated;
  }

  /// Get all amendments for an agreement
  List<AgreementAmendment> getAmendments(String agreementId) {
    return _agreements[agreementId]?.amendments ?? [];
  }

  /// Get pending amendments requiring approval
  List<AgreementAmendment> getPendingAmendments(String agreementId) {
    return getAmendments(agreementId)
        .where((a) => a.status == AmendmentStatus.pending)
        .toList();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Singleton instance
final bookingAgreementService = BookingAgreementService();

