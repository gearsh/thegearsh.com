// Gearsh Booking Agreement Model
// Immutable structured agreement for bookings with full audit trail

import 'package:flutter/foundation.dart';

/// Represents a locked, immutable booking agreement
@immutable
class BookingAgreement {
  final String id;
  final String bookingId;
  final String artistId;
  final String clientId;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  // Performance Details
  final PerformanceDetails performance;

  // Financial Terms
  final FinancialTerms financialTerms;

  // Hospitality Rider
  final HospitalityRider? rider;

  // Agreement Status
  final AgreementStatus status;

  // Immutability flag - once true, changes require amendment requests
  final bool isLocked;

  // Amendment history
  final List<AgreementAmendment> amendments;

  // Digital signatures
  final String? artistSignature;
  final String? clientSignature;
  final DateTime? artistSignedAt;
  final DateTime? clientSignedAt;

  const BookingAgreement({
    required this.id,
    required this.bookingId,
    required this.artistId,
    required this.clientId,
    required this.createdAt,
    this.confirmedAt,
    required this.performance,
    required this.financialTerms,
    this.rider,
    this.status = AgreementStatus.draft,
    this.isLocked = false,
    this.amendments = const [],
    this.artistSignature,
    this.clientSignature,
    this.artistSignedAt,
    this.clientSignedAt,
  });

  bool get isFullySigned => artistSignature != null && clientSignature != null;

  BookingAgreement copyWith({
    String? id,
    String? bookingId,
    String? artistId,
    String? clientId,
    DateTime? createdAt,
    DateTime? confirmedAt,
    PerformanceDetails? performance,
    FinancialTerms? financialTerms,
    HospitalityRider? rider,
    AgreementStatus? status,
    bool? isLocked,
    List<AgreementAmendment>? amendments,
    String? artistSignature,
    String? clientSignature,
    DateTime? artistSignedAt,
    DateTime? clientSignedAt,
  }) {
    return BookingAgreement(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      artistId: artistId ?? this.artistId,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      performance: performance ?? this.performance,
      financialTerms: financialTerms ?? this.financialTerms,
      rider: rider ?? this.rider,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
      amendments: amendments ?? this.amendments,
      artistSignature: artistSignature ?? this.artistSignature,
      clientSignature: clientSignature ?? this.clientSignature,
      artistSignedAt: artistSignedAt ?? this.artistSignedAt,
      clientSignedAt: clientSignedAt ?? this.clientSignedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'artistId': artistId,
    'clientId': clientId,
    'createdAt': createdAt.toIso8601String(),
    'confirmedAt': confirmedAt?.toIso8601String(),
    'performance': performance.toJson(),
    'financialTerms': financialTerms.toJson(),
    'rider': rider?.toJson(),
    'status': status.name,
    'isLocked': isLocked,
    'amendments': amendments.map((a) => a.toJson()).toList(),
    'artistSignature': artistSignature,
    'clientSignature': clientSignature,
    'artistSignedAt': artistSignedAt?.toIso8601String(),
    'clientSignedAt': clientSignedAt?.toIso8601String(),
  };

  factory BookingAgreement.fromJson(Map<String, dynamic> json) {
    return BookingAgreement(
      id: json['id'],
      bookingId: json['bookingId'],
      artistId: json['artistId'],
      clientId: json['clientId'],
      createdAt: DateTime.parse(json['createdAt']),
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      performance: PerformanceDetails.fromJson(json['performance']),
      financialTerms: FinancialTerms.fromJson(json['financialTerms']),
      rider: json['rider'] != null ? HospitalityRider.fromJson(json['rider']) : null,
      status: AgreementStatus.values.firstWhere((e) => e.name == json['status']),
      isLocked: json['isLocked'] ?? false,
      amendments: (json['amendments'] as List?)?.map((a) => AgreementAmendment.fromJson(a)).toList() ?? [],
      artistSignature: json['artistSignature'],
      clientSignature: json['clientSignature'],
      artistSignedAt: json['artistSignedAt'] != null ? DateTime.parse(json['artistSignedAt']) : null,
      clientSignedAt: json['clientSignedAt'] != null ? DateTime.parse(json['clientSignedAt']) : null,
    );
  }
}

/// Performance timing and requirements
@immutable
class PerformanceDetails {
  final DateTime eventDate;
  final DateTime performanceStartTime;
  final DateTime performanceEndTime;
  final int setDurationMinutes;
  final DateTime arrivalDeadline;
  final int gracePeriodMinutes;
  final String venueName;
  final String venueAddress;
  final double? venueLatitude;
  final double? venueLongitude;
  final String? stageRequirements;
  final String? soundRequirements;
  final String? lightingRequirements;
  final String? additionalNotes;

  const PerformanceDetails({
    required this.eventDate,
    required this.performanceStartTime,
    required this.performanceEndTime,
    required this.setDurationMinutes,
    required this.arrivalDeadline,
    this.gracePeriodMinutes = 30,
    required this.venueName,
    required this.venueAddress,
    this.venueLatitude,
    this.venueLongitude,
    this.stageRequirements,
    this.soundRequirements,
    this.lightingRequirements,
    this.additionalNotes,
  });

  Map<String, dynamic> toJson() => {
    'eventDate': eventDate.toIso8601String(),
    'performanceStartTime': performanceStartTime.toIso8601String(),
    'performanceEndTime': performanceEndTime.toIso8601String(),
    'setDurationMinutes': setDurationMinutes,
    'arrivalDeadline': arrivalDeadline.toIso8601String(),
    'gracePeriodMinutes': gracePeriodMinutes,
    'venueName': venueName,
    'venueAddress': venueAddress,
    'venueLatitude': venueLatitude,
    'venueLongitude': venueLongitude,
    'stageRequirements': stageRequirements,
    'soundRequirements': soundRequirements,
    'lightingRequirements': lightingRequirements,
    'additionalNotes': additionalNotes,
  };

  factory PerformanceDetails.fromJson(Map<String, dynamic> json) {
    return PerformanceDetails(
      eventDate: DateTime.parse(json['eventDate']),
      performanceStartTime: DateTime.parse(json['performanceStartTime']),
      performanceEndTime: DateTime.parse(json['performanceEndTime']),
      setDurationMinutes: json['setDurationMinutes'],
      arrivalDeadline: DateTime.parse(json['arrivalDeadline']),
      gracePeriodMinutes: json['gracePeriodMinutes'] ?? 30,
      venueName: json['venueName'],
      venueAddress: json['venueAddress'],
      venueLatitude: json['venueLatitude']?.toDouble(),
      venueLongitude: json['venueLongitude']?.toDouble(),
      stageRequirements: json['stageRequirements'],
      soundRequirements: json['soundRequirements'],
      lightingRequirements: json['lightingRequirements'],
      additionalNotes: json['additionalNotes'],
    );
  }
}

/// Financial terms and payment structure
@immutable
class FinancialTerms {
  final double totalFee;
  final String currencyCode;
  final double depositAmount;
  final double depositPercentage;
  final double balanceAmount;
  final DateTime? depositDueDate;
  final DateTime? balanceDueDate;
  final double serviceFeePercent;
  final double serviceFeeAmount;
  final double? travelAllowance;
  final double? accommodationAllowance;
  final double? perDiemAllowance;
  final List<AdditionalCost> additionalCosts;
  final PaymentSchedule paymentSchedule;

  const FinancialTerms({
    required this.totalFee,
    required this.currencyCode,
    required this.depositAmount,
    required this.depositPercentage,
    required this.balanceAmount,
    this.depositDueDate,
    this.balanceDueDate,
    this.serviceFeePercent = 12.6,
    required this.serviceFeeAmount,
    this.travelAllowance,
    this.accommodationAllowance,
    this.perDiemAllowance,
    this.additionalCosts = const [],
    this.paymentSchedule = PaymentSchedule.fullUpfront,
  });

  double get grandTotal => totalFee + serviceFeeAmount +
    (travelAllowance ?? 0) +
    (accommodationAllowance ?? 0) +
    (perDiemAllowance ?? 0) +
    additionalCosts.fold(0.0, (sum, cost) => sum + cost.amount);

  Map<String, dynamic> toJson() => {
    'totalFee': totalFee,
    'currencyCode': currencyCode,
    'depositAmount': depositAmount,
    'depositPercentage': depositPercentage,
    'balanceAmount': balanceAmount,
    'depositDueDate': depositDueDate?.toIso8601String(),
    'balanceDueDate': balanceDueDate?.toIso8601String(),
    'serviceFeePercent': serviceFeePercent,
    'serviceFeeAmount': serviceFeeAmount,
    'travelAllowance': travelAllowance,
    'accommodationAllowance': accommodationAllowance,
    'perDiemAllowance': perDiemAllowance,
    'additionalCosts': additionalCosts.map((c) => c.toJson()).toList(),
    'paymentSchedule': paymentSchedule.name,
  };

  factory FinancialTerms.fromJson(Map<String, dynamic> json) {
    return FinancialTerms(
      totalFee: (json['totalFee'] as num).toDouble(),
      currencyCode: json['currencyCode'],
      depositAmount: (json['depositAmount'] as num).toDouble(),
      depositPercentage: (json['depositPercentage'] as num).toDouble(),
      balanceAmount: (json['balanceAmount'] as num).toDouble(),
      depositDueDate: json['depositDueDate'] != null ? DateTime.parse(json['depositDueDate']) : null,
      balanceDueDate: json['balanceDueDate'] != null ? DateTime.parse(json['balanceDueDate']) : null,
      serviceFeePercent: (json['serviceFeePercent'] as num?)?.toDouble() ?? 12.6,
      serviceFeeAmount: (json['serviceFeeAmount'] as num).toDouble(),
      travelAllowance: (json['travelAllowance'] as num?)?.toDouble(),
      accommodationAllowance: (json['accommodationAllowance'] as num?)?.toDouble(),
      perDiemAllowance: (json['perDiemAllowance'] as num?)?.toDouble(),
      additionalCosts: (json['additionalCosts'] as List?)?.map((c) => AdditionalCost.fromJson(c)).toList() ?? [],
      paymentSchedule: PaymentSchedule.values.firstWhere(
        (e) => e.name == json['paymentSchedule'],
        orElse: () => PaymentSchedule.fullUpfront,
      ),
    );
  }
}

/// Additional costs beyond base fee
@immutable
class AdditionalCost {
  final String description;
  final double amount;
  final String category;
  final bool isApproved;

  const AdditionalCost({
    required this.description,
    required this.amount,
    required this.category,
    this.isApproved = false,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount': amount,
    'category': category,
    'isApproved': isApproved,
  };

  factory AdditionalCost.fromJson(Map<String, dynamic> json) {
    return AdditionalCost(
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      isApproved: json['isApproved'] ?? false,
    );
  }
}

/// Hospitality rider requirements
@immutable
class HospitalityRider {
  final List<RiderItem> items;
  final List<String> inclusions;
  final List<String> exclusions;
  final String? dressingRoomRequirements;
  final int? guestListSpots;
  final String? cateringRequirements;
  final String? transportRequirements;
  final String? accommodationRequirements;
  final String? additionalNotes;
  final bool isLocked;
  final DateTime? lockedAt;

  const HospitalityRider({
    this.items = const [],
    this.inclusions = const [],
    this.exclusions = const [],
    this.dressingRoomRequirements,
    this.guestListSpots,
    this.cateringRequirements,
    this.transportRequirements,
    this.accommodationRequirements,
    this.additionalNotes,
    this.isLocked = false,
    this.lockedAt,
  });

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'inclusions': inclusions,
    'exclusions': exclusions,
    'dressingRoomRequirements': dressingRoomRequirements,
    'guestListSpots': guestListSpots,
    'cateringRequirements': cateringRequirements,
    'transportRequirements': transportRequirements,
    'accommodationRequirements': accommodationRequirements,
    'additionalNotes': additionalNotes,
    'isLocked': isLocked,
    'lockedAt': lockedAt?.toIso8601String(),
  };

  factory HospitalityRider.fromJson(Map<String, dynamic> json) {
    return HospitalityRider(
      items: (json['items'] as List?)?.map((i) => RiderItem.fromJson(i)).toList() ?? [],
      inclusions: List<String>.from(json['inclusions'] ?? []),
      exclusions: List<String>.from(json['exclusions'] ?? []),
      dressingRoomRequirements: json['dressingRoomRequirements'],
      guestListSpots: json['guestListSpots'],
      cateringRequirements: json['cateringRequirements'],
      transportRequirements: json['transportRequirements'],
      accommodationRequirements: json['accommodationRequirements'],
      additionalNotes: json['additionalNotes'],
      isLocked: json['isLocked'] ?? false,
      lockedAt: json['lockedAt'] != null ? DateTime.parse(json['lockedAt']) : null,
    );
  }
}

/// Individual rider item
@immutable
class RiderItem {
  final String name;
  final int quantity;
  final String? brand;
  final String? notes;
  final bool isRequired;
  final bool isProvided;

  const RiderItem({
    required this.name,
    required this.quantity,
    this.brand,
    this.notes,
    this.isRequired = true,
    this.isProvided = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'brand': brand,
    'notes': notes,
    'isRequired': isRequired,
    'isProvided': isProvided,
  };

  factory RiderItem.fromJson(Map<String, dynamic> json) {
    return RiderItem(
      name: json['name'],
      quantity: json['quantity'],
      brand: json['brand'],
      notes: json['notes'],
      isRequired: json['isRequired'] ?? true,
      isProvided: json['isProvided'] ?? false,
    );
  }
}

/// Amendment request for locked agreements
@immutable
class AgreementAmendment {
  final String id;
  final String agreementId;
  final String requestedBy;
  final DateTime requestedAt;
  final String fieldChanged;
  final String? previousValue;
  final String newValue;
  final String reason;
  final AmendmentStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  const AgreementAmendment({
    required this.id,
    required this.agreementId,
    required this.requestedBy,
    required this.requestedAt,
    required this.fieldChanged,
    this.previousValue,
    required this.newValue,
    required this.reason,
    this.status = AmendmentStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'agreementId': agreementId,
    'requestedBy': requestedBy,
    'requestedAt': requestedAt.toIso8601String(),
    'fieldChanged': fieldChanged,
    'previousValue': previousValue,
    'newValue': newValue,
    'reason': reason,
    'status': status.name,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
  };

  factory AgreementAmendment.fromJson(Map<String, dynamic> json) {
    return AgreementAmendment(
      id: json['id'],
      agreementId: json['agreementId'],
      requestedBy: json['requestedBy'],
      requestedAt: DateTime.parse(json['requestedAt']),
      fieldChanged: json['fieldChanged'],
      previousValue: json['previousValue'],
      newValue: json['newValue'],
      reason: json['reason'],
      status: AmendmentStatus.values.firstWhere((e) => e.name == json['status']),
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectionReason: json['rejectionReason'],
    );
  }
}

/// Agreement lifecycle status
enum AgreementStatus {
  draft,
  pendingArtistSignature,
  pendingClientSignature,
  confirmed,
  amended,
  cancelled,
  completed,
  disputed,
}

/// Amendment status
enum AmendmentStatus {
  pending,
  approved,
  rejected,
  withdrawn,
}

/// Payment schedule options
enum PaymentSchedule {
  fullUpfront,
  depositThenBalance,
  milestones,
  postPerformance,
}

