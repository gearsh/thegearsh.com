// Gearsh Escrow Service
// Manages conditional payment holds and releases

import 'package:flutter/foundation.dart';
import '../models/escrow_payment.dart';

/// Service for managing escrow payments
class EscrowService {
  static final EscrowService _instance = EscrowService._internal();
  factory EscrowService() => _instance;
  EscrowService._internal();

  // In-memory storage (replace with API calls in production)
  final Map<String, EscrowPayment> _escrows = {};

  /// Create an escrow for a booking
  Future<EscrowPayment> createEscrow({
    required String bookingId,
    required String agreementId,
    required String payerId,
    required String payeeId,
    required double amount,
    required String currencyCode,
    List<ReleaseCondition>? conditions,
  }) async {
    final defaultConditions = conditions ?? [
      ReleaseCondition(
        id: '${bookingId}_checkin',
        type: ReleaseConditionType.artistCheckedIn,
        description: 'Artist checked in at venue',
        releasePercentage: 0, // Check-in doesn't release funds, just records
      ),
      ReleaseCondition(
        id: '${bookingId}_started',
        type: ReleaseConditionType.performanceStarted,
        description: 'Performance started',
        releasePercentage: 50, // 50% released when performance starts
      ),
      ReleaseCondition(
        id: '${bookingId}_completed',
        type: ReleaseConditionType.performanceCompleted,
        description: 'Performance completed successfully',
        releasePercentage: 50, // Remaining 50% released on completion
      ),
    ];

    final escrow = EscrowPayment(
      id: _generateId(),
      bookingId: bookingId,
      agreementId: agreementId,
      payerId: payerId,
      payeeId: payeeId,
      totalAmount: amount,
      heldAmount: amount,
      currencyCode: currencyCode,
      status: EscrowStatus.pending,
      createdAt: DateTime.now(),
      conditions: defaultConditions,
      transactions: [],
    );

    _escrows[escrow.id] = escrow;
    debugPrint('[EscrowService] Created escrow ${escrow.id} for booking $bookingId');
    return escrow;
  }

  /// Mark escrow as funded
  Future<EscrowPayment?> fundEscrow(String escrowId) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;

    final transaction = EscrowTransaction(
      id: _generateId(),
      escrowId: escrowId,
      type: EscrowTransactionType.funded,
      amount: escrow.totalAmount,
      currencyCode: escrow.currencyCode,
      timestamp: DateTime.now(),
      triggeredBy: escrow.payerId,
      reason: 'Initial escrow funding',
    );

    final updated = escrow.copyWith(
      status: EscrowStatus.funded,
      transactions: [...escrow.transactions, transaction],
    );

    _escrows[escrowId] = updated;
    debugPrint('[EscrowService] Escrow $escrowId funded with ${escrow.totalAmount}');
    return updated;
  }

  /// Mark a condition as met
  Future<EscrowPayment?> markConditionMet({
    required String escrowId,
    required String conditionId,
    String? verifiedBy,
  }) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;

    final now = DateTime.now();
    final updatedConditions = escrow.conditions.map((c) {
      if (c.id == conditionId && !c.isMet) {
        return c.copyWith(
          isMet: true,
          metAt: now,
          verifiedBy: verifiedBy,
        );
      }
      return c;
    }).toList();

    // Check if any funds should be released
    final metCondition = updatedConditions.firstWhere((c) => c.id == conditionId);
    double amountToRelease = 0;

    if (metCondition.isMet && metCondition.releasePercentage > 0) {
      amountToRelease = (escrow.totalAmount * metCondition.releasePercentage) / 100;
    }

    EscrowPayment updated = escrow.copyWith(conditions: updatedConditions);

    if (amountToRelease > 0) {
      final transaction = EscrowTransaction(
        id: _generateId(),
        escrowId: escrowId,
        type: EscrowTransactionType.conditionMet,
        amount: amountToRelease,
        currencyCode: escrow.currencyCode,
        timestamp: now,
        triggeredBy: 'system',
        reason: 'Condition met: ${metCondition.description}',
        conditionId: conditionId,
      );

      updated = updated.copyWith(
        releasedAmount: escrow.releasedAmount + amountToRelease,
        status: updated.allConditionsMet ? EscrowStatus.released : EscrowStatus.partialRelease,
        transactions: [...updated.transactions, transaction],
        releasedAt: updated.allConditionsMet ? now : null,
      );
    }

    _escrows[escrowId] = updated;
    debugPrint('[EscrowService] Condition $conditionId met for escrow $escrowId');
    return updated;
  }

  /// Release all remaining funds to payee
  Future<EscrowPayment?> releaseAllFunds({
    required String escrowId,
    required String releasedBy,
    String? reason,
  }) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;

    final remainingAmount = escrow.remainingAmount;
    if (remainingAmount <= 0) return escrow;

    final transaction = EscrowTransaction(
      id: _generateId(),
      escrowId: escrowId,
      type: EscrowTransactionType.fullRelease,
      amount: remainingAmount,
      currencyCode: escrow.currencyCode,
      timestamp: DateTime.now(),
      triggeredBy: releasedBy,
      reason: reason ?? 'Full release of escrow funds',
    );

    final updated = escrow.copyWith(
      releasedAmount: escrow.totalAmount,
      status: EscrowStatus.released,
      releasedAt: DateTime.now(),
      transactions: [...escrow.transactions, transaction],
    );

    _escrows[escrowId] = updated;
    debugPrint('[EscrowService] Full release of escrow $escrowId');
    return updated;
  }

  /// Refund funds to payer
  Future<EscrowPayment?> refundFunds({
    required String escrowId,
    required double amount,
    required String refundedBy,
    String? reason,
  }) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;

    final refundAmount = amount > escrow.remainingAmount ? escrow.remainingAmount : amount;
    if (refundAmount <= 0) return escrow;

    final isFullRefund = refundAmount >= escrow.remainingAmount;

    final transaction = EscrowTransaction(
      id: _generateId(),
      escrowId: escrowId,
      type: isFullRefund ? EscrowTransactionType.fullRefund : EscrowTransactionType.partialRefund,
      amount: refundAmount,
      currencyCode: escrow.currencyCode,
      timestamp: DateTime.now(),
      triggeredBy: refundedBy,
      reason: reason ?? 'Refund to client',
    );

    final updated = escrow.copyWith(
      refundedAmount: escrow.refundedAmount + refundAmount,
      status: isFullRefund ? EscrowStatus.refunded : EscrowStatus.partialRefund,
      refundedAt: DateTime.now(),
      transactions: [...escrow.transactions, transaction],
    );

    _escrows[escrowId] = updated;
    debugPrint('[EscrowService] Refund of $refundAmount from escrow $escrowId');
    return updated;
  }

  /// Place escrow under dispute
  Future<EscrowPayment?> disputeEscrow({
    required String escrowId,
    required String disputeId,
  }) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;

    final transaction = EscrowTransaction(
      id: _generateId(),
      escrowId: escrowId,
      type: EscrowTransactionType.disputeHold,
      amount: escrow.remainingAmount,
      currencyCode: escrow.currencyCode,
      timestamp: DateTime.now(),
      triggeredBy: 'system',
      reason: 'Funds held pending dispute resolution',
    );

    final updated = escrow.copyWith(
      status: EscrowStatus.disputed,
      disputeId: disputeId,
      transactions: [...escrow.transactions, transaction],
    );

    _escrows[escrowId] = updated;
    debugPrint('[EscrowService] Escrow $escrowId under dispute');
    return updated;
  }

  /// Resolve escrow after dispute
  Future<EscrowPayment?> resolveDispute({
    required String escrowId,
    required EscrowResolution resolution,
  }) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;

    final transactions = <EscrowTransaction>[...escrow.transactions];

    if (resolution.artistAmount > 0) {
      transactions.add(EscrowTransaction(
        id: _generateId(),
        escrowId: escrowId,
        type: EscrowTransactionType.disputeResolved,
        amount: resolution.artistAmount,
        currencyCode: escrow.currencyCode,
        timestamp: resolution.resolvedAt,
        triggeredBy: resolution.resolvedBy,
        reason: 'Dispute resolution: released to artist',
      ));
    }

    if (resolution.clientRefundAmount > 0) {
      transactions.add(EscrowTransaction(
        id: _generateId(),
        escrowId: escrowId,
        type: EscrowTransactionType.disputeResolved,
        amount: resolution.clientRefundAmount,
        currencyCode: escrow.currencyCode,
        timestamp: resolution.resolvedAt,
        triggeredBy: resolution.resolvedBy,
        reason: 'Dispute resolution: refunded to client',
      ));
    }

    final updated = escrow.copyWith(
      releasedAmount: escrow.releasedAmount + resolution.artistAmount,
      refundedAmount: escrow.refundedAmount + resolution.clientRefundAmount,
      status: EscrowStatus.released,
      transactions: transactions,
    );

    _escrows[escrowId] = updated;
    debugPrint('[EscrowService] Dispute resolved for escrow $escrowId');
    return updated;
  }

  /// Get escrow by ID
  Future<EscrowPayment?> getEscrow(String escrowId) async {
    return _escrows[escrowId];
  }

  /// Get escrow for a booking
  Future<EscrowPayment?> getEscrowForBooking(String bookingId) async {
    try {
      return _escrows.values.firstWhere((e) => e.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  /// Get all transactions for an escrow
  List<EscrowTransaction> getTransactions(String escrowId) {
    return _escrows[escrowId]?.transactions ?? [];
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Singleton instance
final escrowService = EscrowService();

