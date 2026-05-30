import 'package:gearsh_app/core/contracts/i_escrow_repository.dart';
import 'package:gearsh_app/services/escrow_api_repository.dart';
import 'package:gearsh_app/services/api_service.dart';
import '../models/escrow_payment.dart';

/// Escrow service — reads ledger from API; local helpers for booking lifecycle UI.
class EscrowService implements IEscrowRepository {
  static final EscrowService _instance = EscrowService._internal();
  factory EscrowService() => _instance;
  EscrowService._internal();

  EscrowApiRepository? _apiRepo;

  void bindApi(ApiService api) {
    _apiRepo = EscrowApiRepository(api);
  }

  final Map<String, EscrowPayment> _escrows = {};

  @override
  Future<EscrowSummary?> getForBooking(String bookingId) async {
    if (_apiRepo != null) {
      final summary = await _apiRepo!.getForBooking(bookingId);
      if (summary != null) return summary;
    }
    final local = await getEscrowForBooking(bookingId);
    if (local == null) return null;
    return EscrowSummary(
      bookingId: bookingId,
      bookingStatus: '',
      currency: local.currencyCode,
      totalHeld: local.totalAmount,
      totalReleased: local.releasedAmount,
      totalRefunded: local.refundedAmount,
      remaining: local.remainingAmount,
      status: local.status.name,
    );
  }

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
        releasePercentage: 0,
      ),
      ReleaseCondition(
        id: '${bookingId}_started',
        type: ReleaseConditionType.performanceStarted,
        description: 'Performance started',
        releasePercentage: 50,
      ),
      ReleaseCondition(
        id: '${bookingId}_completed',
        type: ReleaseConditionType.performanceCompleted,
        description: 'Performance completed successfully',
        releasePercentage: 50,
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
    return escrow;
  }

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
    return updated;
  }

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
        return c.copyWith(isMet: true, metAt: now, verifiedBy: verifiedBy);
      }
      return c;
    }).toList();

    final metCondition = updatedConditions.firstWhere((c) => c.id == conditionId);
    double amountToRelease = 0;
    if (metCondition.isMet && metCondition.releasePercentage > 0) {
      amountToRelease = (escrow.totalAmount * metCondition.releasePercentage) / 100;
    }

    EscrowPayment updated = escrow.copyWith(conditions: updatedConditions);
    if (amountToRelease > 0) {
      updated = updated.copyWith(
        releasedAmount: escrow.releasedAmount + amountToRelease,
        status: updated.allConditionsMet ? EscrowStatus.released : EscrowStatus.partialRelease,
        transactions: [
          ...updated.transactions,
          EscrowTransaction(
            id: _generateId(),
            escrowId: escrowId,
            type: EscrowTransactionType.conditionMet,
            amount: amountToRelease,
            currencyCode: escrow.currencyCode,
            timestamp: now,
            triggeredBy: 'system',
            reason: 'Condition met: ${metCondition.description}',
            conditionId: conditionId,
          ),
        ],
        releasedAt: updated.allConditionsMet ? now : null,
      );
    }

    _escrows[escrowId] = updated;
    return updated;
  }

  Future<EscrowPayment?> releaseAllFunds({
    required String escrowId,
    required String releasedBy,
    String? reason,
  }) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;
    final remainingAmount = escrow.remainingAmount;
    if (remainingAmount <= 0) return escrow;

    final updated = escrow.copyWith(
      releasedAmount: escrow.totalAmount,
      status: EscrowStatus.released,
      releasedAt: DateTime.now(),
      transactions: [
        ...escrow.transactions,
        EscrowTransaction(
          id: _generateId(),
          escrowId: escrowId,
          type: EscrowTransactionType.fullRelease,
          amount: remainingAmount,
          currencyCode: escrow.currencyCode,
          timestamp: DateTime.now(),
          triggeredBy: releasedBy,
          reason: reason ?? 'Full release of escrow funds',
        ),
      ],
    );
    _escrows[escrowId] = updated;
    return updated;
  }

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
    final updated = escrow.copyWith(
      refundedAmount: escrow.refundedAmount + refundAmount,
      status: isFullRefund ? EscrowStatus.refunded : EscrowStatus.partialRefund,
      refundedAt: DateTime.now(),
      transactions: [
        ...escrow.transactions,
        EscrowTransaction(
          id: _generateId(),
          escrowId: escrowId,
          type: isFullRefund ? EscrowTransactionType.fullRefund : EscrowTransactionType.partialRefund,
          amount: refundAmount,
          currencyCode: escrow.currencyCode,
          timestamp: DateTime.now(),
          triggeredBy: refundedBy,
          reason: reason ?? 'Refund to client',
        ),
      ],
    );
    _escrows[escrowId] = updated;
    return updated;
  }

  Future<EscrowPayment?> disputeEscrow({
    required String escrowId,
    required String disputeId,
  }) async {
    final escrow = _escrows[escrowId];
    if (escrow == null) return null;
    final updated = escrow.copyWith(
      status: EscrowStatus.disputed,
      disputeId: disputeId,
    );
    _escrows[escrowId] = updated;
    return updated;
  }

  List<EscrowTransaction> getTransactions(String escrowId) {
    return _escrows[escrowId]?.transactions ?? [];
  }

  Future<EscrowPayment?> getEscrow(String escrowId) async => _escrows[escrowId];

  Future<EscrowPayment?> getEscrowForBooking(String bookingId) async {
    try {
      return _escrows.values.firstWhere((e) => e.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}

final escrowService = EscrowService();
