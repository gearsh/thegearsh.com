// Gearsh App - Block & Report Service
// Handles user blocking and reporting for community safety
// Required for Apple App Store compliance

import 'package:flutter/foundation.dart';

/// Report reasons for user reports
enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  fraud,
  impersonation,
  other,
}

/// Report status
enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

/// A user report
class UserReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.details,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolvedAt,
  });

  /// Get display text for reason
  String get reasonText {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam or misleading';
      case ReportReason.harassment:
        return 'Harassment or bullying';
      case ReportReason.inappropriateContent:
        return 'Inappropriate content';
      case ReportReason.fraud:
        return 'Fraud or scam';
      case ReportReason.impersonation:
        return 'Impersonation';
      case ReportReason.other:
        return 'Other';
    }
  }
}

/// Block & Report Service
class BlockReportService {
  static final BlockReportService _instance = BlockReportService._internal();
  factory BlockReportService() => _instance;
  BlockReportService._internal();

  // In-memory storage (replace with backend in production)
  final Set<String> _blockedUsers = {};
  final List<UserReport> _reports = [];
  String? _currentUserId;

  /// Initialize with current user ID
  void initialize(String userId) {
    _currentUserId = userId;
    // In production: Load blocked users from backend/local storage
  }

  /// Check if a user is blocked
  bool isBlocked(String userId) {
    return _blockedUsers.contains(userId);
  }

  /// Get all blocked user IDs
  Set<String> get blockedUsers => Set.unmodifiable(_blockedUsers);

  /// Block a user
  Future<bool> blockUser(String userId) async {
    if (_currentUserId == null) {
      debugPrint('BlockReportService: No current user set');
      return false;
    }

    try {
      _blockedUsers.add(userId);

      // In production: Sync to backend
      // await _apiClient.post('/users/block', body: {'blocked_user_id': userId});

      debugPrint('Blocked user: $userId');
      return true;
    } catch (e) {
      debugPrint('Failed to block user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    if (_currentUserId == null) return false;

    try {
      _blockedUsers.remove(userId);

      // In production: Sync to backend
      // await _apiClient.delete('/users/block/$userId');

      debugPrint('Unblocked user: $userId');
      return true;
    } catch (e) {
      debugPrint('Failed to unblock user: $e');
      return false;
    }
  }

  /// Report a user
  Future<UserReport?> reportUser({
    required String reportedUserId,
    required ReportReason reason,
    String? details,
  }) async {
    if (_currentUserId == null) {
      debugPrint('BlockReportService: No current user set');
      return null;
    }

    try {
      final report = UserReport(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        reporterId: _currentUserId!,
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
        createdAt: DateTime.now(),
      );

      _reports.add(report);

      // In production: Send to backend
      // await _apiClient.post('/reports', body: {
      //   'reported_user_id': reportedUserId,
      //   'reason': reason.name,
      //   'details': details,
      // });

      debugPrint('Reported user: $reportedUserId for ${reason.name}');
      return report;
    } catch (e) {
      debugPrint('Failed to report user: $e');
      return null;
    }
  }

  /// Get reports made by current user
  List<UserReport> getMyReports() {
    if (_currentUserId == null) return [];
    return _reports.where((r) => r.reporterId == _currentUserId).toList();
  }

  /// Clear all data (for logout)
  void clear() {
    _blockedUsers.clear();
    _reports.clear();
    _currentUserId = null;
  }
}

/// Global instance
final blockReportService = BlockReportService();
