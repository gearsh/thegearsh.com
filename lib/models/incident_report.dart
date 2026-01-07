// Gearsh Incident Report Model
// Private incident reporting tied to bookings - no public visibility

import 'package:flutter/foundation.dart';

/// Private incident report for a booking
@immutable
class IncidentReport {
  final String id;
  final String bookingId;
  final String reporterId;
  final String reporterRole; // 'artist', 'client'
  final DateTime reportedAt;
  final IncidentType type;
  final IncidentSeverity severity;
  final String description;
  final List<String> attachmentUrls;
  final IncidentStatus status;
  final String? assignedTo;
  final DateTime? resolvedAt;
  final String? resolution;
  final bool isConfidential;
  final List<IncidentNote> notes;

  const IncidentReport({
    required this.id,
    required this.bookingId,
    required this.reporterId,
    required this.reporterRole,
    required this.reportedAt,
    required this.type,
    this.severity = IncidentSeverity.medium,
    required this.description,
    this.attachmentUrls = const [],
    this.status = IncidentStatus.submitted,
    this.assignedTo,
    this.resolvedAt,
    this.resolution,
    this.isConfidential = true,
    this.notes = const [],
  });

  IncidentReport copyWith({
    String? id,
    String? bookingId,
    String? reporterId,
    String? reporterRole,
    DateTime? reportedAt,
    IncidentType? type,
    IncidentSeverity? severity,
    String? description,
    List<String>? attachmentUrls,
    IncidentStatus? status,
    String? assignedTo,
    DateTime? resolvedAt,
    String? resolution,
    bool? isConfidential,
    List<IncidentNote>? notes,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      reporterId: reporterId ?? this.reporterId,
      reporterRole: reporterRole ?? this.reporterRole,
      reportedAt: reportedAt ?? this.reportedAt,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      isConfidential: isConfidential ?? this.isConfidential,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'reporterId': reporterId,
    'reporterRole': reporterRole,
    'reportedAt': reportedAt.toIso8601String(),
    'type': type.name,
    'severity': severity.name,
    'description': description,
    'attachmentUrls': attachmentUrls,
    'status': status.name,
    'assignedTo': assignedTo,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolution': resolution,
    'isConfidential': isConfidential,
    'notes': notes.map((n) => n.toJson()).toList(),
  };

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'],
      bookingId: json['bookingId'],
      reporterId: json['reporterId'],
      reporterRole: json['reporterRole'],
      reportedAt: DateTime.parse(json['reportedAt']),
      type: IncidentType.values.firstWhere((e) => e.name == json['type']),
      severity: IncidentSeverity.values.firstWhere((e) => e.name == json['severity']),
      description: json['description'],
      attachmentUrls: List<String>.from(json['attachmentUrls'] ?? []),
      status: IncidentStatus.values.firstWhere((e) => e.name == json['status']),
      assignedTo: json['assignedTo'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolution: json['resolution'],
      isConfidential: json['isConfidential'] ?? true,
      notes: (json['notes'] as List?)?.map((n) => IncidentNote.fromJson(n)).toList() ?? [],
    );
  }
}

/// Internal note on an incident
@immutable
class IncidentNote {
  final String id;
  final String authorId;
  final String authorRole;
  final DateTime createdAt;
  final String content;
  final bool isInternal; // Only visible to support staff

  const IncidentNote({
    required this.id,
    required this.authorId,
    required this.authorRole,
    required this.createdAt,
    required this.content,
    this.isInternal = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorRole': authorRole,
    'createdAt': createdAt.toIso8601String(),
    'content': content,
    'isInternal': isInternal,
  };

  factory IncidentNote.fromJson(Map<String, dynamic> json) {
    return IncidentNote(
      id: json['id'],
      authorId: json['authorId'],
      authorRole: json['authorRole'],
      createdAt: DateTime.parse(json['createdAt']),
      content: json['content'],
      isInternal: json['isInternal'] ?? false,
    );
  }
}

/// Incident types - neutral language, no accusations
enum IncidentType {
  /// Environment or venue issues
  unsafeEnvironment,

  /// Communication or conduct issues
  verbalConflict,

  /// Hostility or intimidation reported
  hostileEnvironment,

  /// Agreement terms not followed
  agreementBreach,

  /// Unable to proceed with performance
  unableToProceed,

  /// Technical or equipment failure
  technicalIssue,

  /// Rider items not provided as agreed
  riderIssue,

  /// Payment or financial dispute
  paymentDispute,

  /// Scheduling or timing conflict
  schedulingConflict,

  /// Health or medical situation
  healthSituation,

  /// Force majeure / external circumstances
  externalCircumstances,

  /// Other incident type
  other,
}

/// Incident severity levels
enum IncidentSeverity {
  low,      // Minor issue, informational
  medium,   // Requires attention but not urgent
  high,     // Urgent, affects booking completion
  critical, // Safety concern or major breach
}

/// Incident resolution status
enum IncidentStatus {
  submitted,
  underReview,
  investigating,
  pendingResponse,
  mediation,
  resolved,
  closed,
  escalated,
}

/// Extension for human-readable incident type names
extension IncidentTypeExtension on IncidentType {
  String get displayName {
    switch (this) {
      case IncidentType.unsafeEnvironment:
        return 'Environment Concern';
      case IncidentType.verbalConflict:
        return 'Communication Issue';
      case IncidentType.hostileEnvironment:
        return 'Environment Concern';
      case IncidentType.agreementBreach:
        return 'Agreement Discrepancy';
      case IncidentType.unableToProceed:
        return 'Unable to Proceed';
      case IncidentType.technicalIssue:
        return 'Technical Issue';
      case IncidentType.riderIssue:
        return 'Rider Discrepancy';
      case IncidentType.paymentDispute:
        return 'Payment Query';
      case IncidentType.schedulingConflict:
        return 'Scheduling Issue';
      case IncidentType.healthSituation:
        return 'Health Situation';
      case IncidentType.externalCircumstances:
        return 'External Circumstances';
      case IncidentType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case IncidentType.unsafeEnvironment:
        return 'Report concerns about the physical environment or venue safety';
      case IncidentType.verbalConflict:
        return 'Report communication difficulties or verbal disagreements';
      case IncidentType.hostileEnvironment:
        return 'Report an uncomfortable or unwelcoming environment';
      case IncidentType.agreementBreach:
        return 'Report when agreed terms differ from actual conditions';
      case IncidentType.unableToProceed:
        return 'Report when circumstances prevent proceeding with the booking';
      case IncidentType.technicalIssue:
        return 'Report equipment or technical problems';
      case IncidentType.riderIssue:
        return 'Report discrepancies with hospitality rider items';
      case IncidentType.paymentDispute:
        return 'Report payment or financial concerns';
      case IncidentType.schedulingConflict:
        return 'Report timing or scheduling discrepancies';
      case IncidentType.healthSituation:
        return 'Report health-related circumstances';
      case IncidentType.externalCircumstances:
        return 'Report external factors affecting the booking';
      case IncidentType.other:
        return 'Report other concerns not covered above';
    }
  }
}

