// Gearsh Incident Report Service
// Private incident reporting with no public visibility

import 'package:flutter/foundation.dart';
import '../models/incident_report.dart';

/// Service for managing private incident reports
class IncidentReportService {
  static final IncidentReportService _instance = IncidentReportService._internal();
  factory IncidentReportService() => _instance;
  IncidentReportService._internal();

  // In-memory storage (replace with API calls in production)
  final Map<String, IncidentReport> _reports = {};

  /// Submit a new incident report
  Future<IncidentReport> submitReport({
    required String bookingId,
    required String reporterId,
    required String reporterRole,
    required IncidentType type,
    required String description,
    IncidentSeverity severity = IncidentSeverity.medium,
    List<String> attachmentUrls = const [],
  }) async {
    final report = IncidentReport(
      id: _generateId(),
      bookingId: bookingId,
      reporterId: reporterId,
      reporterRole: reporterRole,
      reportedAt: DateTime.now(),
      type: type,
      severity: severity,
      description: description,
      attachmentUrls: attachmentUrls,
      status: IncidentStatus.submitted,
      isConfidential: true,
    );

    _reports[report.id] = report;
    debugPrint('[IncidentService] Incident ${report.id} submitted for booking $bookingId');

    // Auto-escalate critical incidents
    if (severity == IncidentSeverity.critical) {
      await _escalateIncident(report.id);
    }

    return report;
  }

  /// Add a note to an incident
  Future<IncidentReport?> addNote({
    required String reportId,
    required String authorId,
    required String authorRole,
    required String content,
    bool isInternal = false,
  }) async {
    final report = _reports[reportId];
    if (report == null) return null;

    final note = IncidentNote(
      id: _generateId(),
      authorId: authorId,
      authorRole: authorRole,
      createdAt: DateTime.now(),
      content: content,
      isInternal: isInternal,
    );

    final updated = report.copyWith(
      notes: [...report.notes, note],
    );

    _reports[reportId] = updated;
    debugPrint('[IncidentService] Note added to incident $reportId');
    return updated;
  }

  /// Update incident status
  Future<IncidentReport?> updateStatus({
    required String reportId,
    required IncidentStatus newStatus,
    String? assignedTo,
  }) async {
    final report = _reports[reportId];
    if (report == null) return null;

    final updated = report.copyWith(
      status: newStatus,
      assignedTo: assignedTo ?? report.assignedTo,
    );

    _reports[reportId] = updated;
    debugPrint('[IncidentService] Incident $reportId status updated to $newStatus');
    return updated;
  }

  /// Resolve an incident
  Future<IncidentReport?> resolveIncident({
    required String reportId,
    required String resolution,
    required String resolvedBy,
  }) async {
    final report = _reports[reportId];
    if (report == null) return null;

    final updated = report.copyWith(
      status: IncidentStatus.resolved,
      resolvedAt: DateTime.now(),
      resolution: resolution,
    );

    // Add resolution note
    final noteUpdated = await addNote(
      reportId: reportId,
      authorId: resolvedBy,
      authorRole: 'support',
      content: 'Incident resolved: $resolution',
      isInternal: false,
    );

    _reports[reportId] = noteUpdated ?? updated;
    debugPrint('[IncidentService] Incident $reportId resolved');
    return _reports[reportId];
  }

  /// Get incident report by ID
  Future<IncidentReport?> getReport(String reportId) async {
    return _reports[reportId];
  }

  /// Get all incidents for a booking
  Future<List<IncidentReport>> getIncidentsForBooking(String bookingId) async {
    return _reports.values.where((r) => r.bookingId == bookingId).toList();
  }

  /// Get all incidents reported by a user
  Future<List<IncidentReport>> getIncidentsByUser(String userId) async {
    return _reports.values.where((r) => r.reporterId == userId).toList();
  }

  /// Get incidents against a user (from their bookings)
  /// Note: This requires knowing which bookings involve the user
  Future<int> getIncidentCountAgainstUser(String userId, List<String> userBookingIds) async {
    return _reports.values
        .where((r) => userBookingIds.contains(r.bookingId) && r.reporterId != userId)
        .length;
  }

  /// Check if booking has unresolved incidents
  Future<bool> hasUnresolvedIncidents(String bookingId) async {
    return _reports.values.any((r) =>
        r.bookingId == bookingId &&
        r.status != IncidentStatus.resolved &&
        r.status != IncidentStatus.closed
    );
  }

  /// Private escalation for critical incidents
  Future<void> _escalateIncident(String reportId) async {
    await updateStatus(
      reportId: reportId,
      newStatus: IncidentStatus.escalated,
    );
    debugPrint('[IncidentService] Critical incident $reportId escalated');
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Singleton instance
final incidentReportService = IncidentReportService();

