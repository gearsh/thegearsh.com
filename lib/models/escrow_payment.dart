// Gearsh Escrow Payment Model
// Conditional payment release based on booking lifecycle events

import 'package:flutter/foundation.dart';

/// Represents funds held in escrow for a booking
@immutable
class EscrowPayment {
  final String id;
  final String bookingId;
  final String agreementId;
  final String payerId; // Client
  final String payeeId; // Artist

  // Amounts
  final double totalAmount;
  final double heldAmount;
  final double releasedAmount;
  final double refundedAmount;
  final String currencyCode;

  // Status
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime? releasedAt;
  final DateTime? refundedAt;

  // Release conditions
  final List<ReleaseCondition> conditions;

  // Transaction history
  final List<EscrowTransaction> transactions;

  // Dispute reference (if any)
  final String? disputeId;

  const EscrowPayment({
    required this.id,
    required this.bookingId,
    required this.agreementId,
    required this.payerId,
    required this.payeeId,
    required this.totalAmount,
    required this.heldAmount,
    this.releasedAmount = 0,
    this.refundedAmount = 0,
    required this.currencyCode,
    this.status = EscrowStatus.pending,
    required this.createdAt,
    this.releasedAt,
    this.refundedAt,
    this.conditions = const [],
    this.transactions = const [],
    this.disputeId,
  });

  /// Check if all conditions for release are met
  bool get allConditionsMet => conditions.every((c) => c.isMet);

  /// Get percentage of conditions met
  double get conditionsMetPercentage {
    if (conditions.isEmpty) return 0;
    final metCount = conditions.where((c) => c.isMet).length;
    return (metCount / conditions.length) * 100;
  }

  /// Remaining amount in escrow
  double get remainingAmount => heldAmount - releasedAmount - refundedAmount;

  EscrowPayment copyWith({
    String? id,
    String? bookingId,
    String? agreementId,
    String? payerId,
    String? payeeId,
    double? totalAmount,
    double? heldAmount,
    double? releasedAmount,
    double? refundedAmount,
    String? currencyCode,
    EscrowStatus? status,
    DateTime? createdAt,
    DateTime? releasedAt,
    DateTime? refundedAt,
    List<ReleaseCondition>? conditions,
    List<EscrowTransaction>? transactions,
    String? disputeId,
  }) {
    return EscrowPayment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      agreementId: agreementId ?? this.agreementId,
      payerId: payerId ?? this.payerId,
      payeeId: payeeId ?? this.payeeId,
      totalAmount: totalAmount ?? this.totalAmount,
      heldAmount: heldAmount ?? this.heldAmount,
      releasedAmount: releasedAmount ?? this.releasedAmount,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      conditions: conditions ?? this.conditions,
      transactions: transactions ?? this.transactions,
      disputeId: disputeId ?? this.disputeId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'agreementId': agreementId,
    'payerId': payerId,
    'payeeId': payeeId,
    'totalAmount': totalAmount,
    'heldAmount': heldAmount,
    'releasedAmount': releasedAmount,
    'refundedAmount': refundedAmount,
    'currencyCode': currencyCode,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'releasedAt': releasedAt?.toIso8601String(),
    'refundedAt': refundedAt?.toIso8601String(),
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'disputeId': disputeId,
  };

  factory EscrowPayment.fromJson(Map<String, dynamic> json) {
    return EscrowPayment(
      id: json['id'],
      bookingId: json['bookingId'],
      agreementId: json['agreementId'],
      payerId: json['payerId'],
      payeeId: json['payeeId'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      heldAmount: (json['heldAmount'] as num).toDouble(),
      releasedAmount: (json['releasedAmount'] as num?)?.toDouble() ?? 0,
      refundedAmount: (json['refundedAmount'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currencyCode'],
      status: EscrowStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      releasedAt: json['releasedAt'] != null ? DateTime.parse(json['releasedAt']) : null,
      refundedAt: json['refundedAt'] != null ? DateTime.parse(json['refundedAt']) : null,
      conditions: (json['conditions'] as List?)?.map((c) => ReleaseCondition.fromJson(c)).toList() ?? [],
      transactions: (json['transactions'] as List?)?.map((t) => EscrowTransaction.fromJson(t)).toList() ?? [],
      disputeId: json['disputeId'],
    );
  }
}

/// Condition that must be met for escrow release
@immutable
class ReleaseCondition {
  final String id;
  final ReleaseConditionType type;
  final String description;
  final bool isMet;
  final DateTime? metAt;
  final String? verifiedBy;
  final double releasePercentage; // Percentage to release when this condition is met

  const ReleaseCondition({
    required this.id,
    required this.type,
    required this.description,
    this.isMet = false,
    this.metAt,
    this.verifiedBy,
    this.releasePercentage = 100,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'description': description,
    'isMet': isMet,
    'metAt': metAt?.toIso8601String(),
    'verifiedBy': verifiedBy,
    'releasePercentage': releasePercentage,
  };

  factory ReleaseCondition.fromJson(Map<String, dynamic> json) {
    return ReleaseCondition(
      id: json['id'],
      type: ReleaseConditionType.values.firstWhere((e) => e.name == json['type']),
      description: json['description'],
      isMet: json['isMet'] ?? false,
      metAt: json['metAt'] != null ? DateTime.parse(json['metAt']) : null,
      verifiedBy: json['verifiedBy'],
      releasePercentage: (json['releasePercentage'] as num?)?.toDouble() ?? 100,
    );
  }

  ReleaseCondition copyWith({
    String? id,
    ReleaseConditionType? type,
    String? description,
    bool? isMet,
    DateTime? metAt,
    String? verifiedBy,
    double? releasePercentage,
  }) {
    return ReleaseCondition(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      isMet: isMet ?? this.isMet,
      metAt: metAt ?? this.metAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      releasePercentage: releasePercentage ?? this.releasePercentage,
    );
  }
}

/// Types of release conditions
enum ReleaseConditionType {
  artistCheckedIn,
  performanceStarted,
  performanceCompleted,
  clientConfirmation,
  timeElapsed,
  riderProvided,
  noDispute,
  custom,
}

/// Record of escrow transactions
@immutable
class EscrowTransaction {
  final String id;
  final String escrowId;
  final EscrowTransactionType type;
  final double amount;
  final String currencyCode;
  final DateTime timestamp;
  final String? triggeredBy; // User ID or 'system'
  final String? reason;
  final String? conditionId; // If triggered by condition

  const EscrowTransaction({
    required this.id,
    required this.escrowId,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.timestamp,
    this.triggeredBy,
    this.reason,
    this.conditionId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'escrowId': escrowId,
    'type': type.name,
    'amount': amount,
    'currencyCode': currencyCode,
    'timestamp': timestamp.toIso8601String(),
    'triggeredBy': triggeredBy,
    'reason': reason,
    'conditionId': conditionId,
  };

  factory EscrowTransaction.fromJson(Map<String, dynamic> json) {
    return EscrowTransaction(
      id: json['id'],
      escrowId: json['escrowId'],
      type: EscrowTransactionType.values.firstWhere((e) => e.name == json['type']),
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'],
      timestamp: DateTime.parse(json['timestamp']),
      triggeredBy: json['triggeredBy'],
      reason: json['reason'],
      conditionId: json['conditionId'],
    );
  }
}

/// Escrow status
enum EscrowStatus {
  pending,        // Payment not yet received
  funded,         // Funds held in escrow
  partialRelease, // Some funds released
  released,       // All funds released to payee
  refunded,       // All funds returned to payer
  partialRefund,  // Some funds refunded
  disputed,       // Under dispute resolution
  cancelled,      // Booking cancelled before funding
}

/// Transaction types
enum EscrowTransactionType {
  funded,           // Initial funding
  conditionMet,     // Condition triggered partial release
  manualRelease,    // Manual release by admin
  fullRelease,      // Full release to artist
  partialRelease,   // Partial release
  fullRefund,       // Full refund to client
  partialRefund,    // Partial refund
  disputeHold,      // Funds held due to dispute
  disputeResolved,  // Dispute resolved, funds moved
  cancellation,     // Booking cancelled
  creditIssued,     // Credit for reschedule
}

/// Escrow resolution result
@immutable
class EscrowResolution {
  final String escrowId;
  final EscrowResolutionType type;
  final double artistAmount;
  final double clientRefundAmount;
  final double? creditAmount;
  final String? creditValidUntil;
  final String resolvedBy;
  final DateTime resolvedAt;
  final String reason;

  const EscrowResolution({
    required this.escrowId,
    required this.type,
    required this.artistAmount,
    required this.clientRefundAmount,
    this.creditAmount,
    this.creditValidUntil,
    required this.resolvedBy,
    required this.resolvedAt,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'escrowId': escrowId,
    'type': type.name,
    'artistAmount': artistAmount,
    'clientRefundAmount': clientRefundAmount,
    'creditAmount': creditAmount,
    'creditValidUntil': creditValidUntil,
    'resolvedBy': resolvedBy,
    'resolvedAt': resolvedAt.toIso8601String(),
    'reason': reason,
  };
}

/// Resolution types
enum EscrowResolutionType {
  fullReleaseToArtist,
  fullRefundToClient,
  partialSplit,
  creditForReschedule,
  disputeResolution,
}

