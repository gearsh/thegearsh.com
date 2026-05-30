import 'package:gearsh_app/services/api_service.dart';
import '../models/reliability_index.dart';

/// Reliability index — private ops metrics synced with `/api/reliability`.
class ReliabilityIndexService {
  static final ReliabilityIndexService _instance = ReliabilityIndexService._internal();
  factory ReliabilityIndexService() => _instance;
  ReliabilityIndexService._internal();

  ApiService? _api;
  final Map<String, ReliabilityIndex> _cache = {};

  void bindApi(ApiService api) => _api = api;

  Future<ReliabilityIndex> getOrCreateIndex({
    required String userId,
    required String userRole,
  }) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;

    if (_api != null) {
      final response = await _api!.get('/reliability/me');
      final row = response.getData<Map<String, dynamic>>();
      if (row != null) {
        final index = _indexFromRow(row, userId, userRole);
        _cache[userId] = index;
        return index;
      }
    }

    final index = ReliabilityIndex.empty(userId: userId, userRole: userRole);
    _cache[userId] = index;
    return index;
  }

  Future<ReliabilityIndex?> recordEvent({
    required String userId,
    required ReliabilityEventType type,
    String? bookingId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_api != null) {
      await _api!.post('/reliability/events', body: {
        'event_type': _eventTypeName(type),
        'booking_id': bookingId,
        'metadata': metadata,
      });
    }

    final index = _cache[userId];
    if (index == null) return null;

    final updated = _updateIndexForEvent(index, type);
    _cache[userId] = updated;
    return updated;
  }

  Future<ReliabilityIndex?> getIndex(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId];
    return getOrCreateIndex(userId: userId, userRole: 'artist');
  }

  ReliabilityIndex _indexFromRow(Map<String, dynamic> row, String userId, String userRole) {
    return ReliabilityIndex(
      userId: userId,
      userRole: userRole,
      totalBookings: row['total_bookings'] as int? ?? 0,
      completedBookings: row['completed_bookings'] as int? ?? 0,
      cancelledBookings: row['cancelled_bookings'] as int? ?? 0,
      disputedBookings: row['disputed_bookings'] as int? ?? 0,
      rescheduledBookings: row['rescheduled_bookings'] as int? ?? 0,
      onTimeArrivals: row['on_time_arrivals'] as int? ?? 0,
      lateArrivals: row['late_arrivals'] as int? ?? 0,
      noShows: row['no_shows'] as int? ?? 0,
      completionRate: (row['completion_rate'] as num?)?.toDouble() ?? 0,
      cancellationRate: (row['cancellation_rate'] as num?)?.toDouble() ?? 0,
      disputeRate: (row['dispute_rate'] as num?)?.toDouble() ?? 0,
      lastUpdated: DateTime.tryParse(row['last_updated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String _eventTypeName(ReliabilityEventType type) {
    return type.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => '_${m.group(0)!.toLowerCase()}')
        .replaceFirst('_', '');
  }

  ReliabilityIndex _updateIndexForEvent(ReliabilityIndex index, ReliabilityEventType type) {
    switch (type) {
      case ReliabilityEventType.bookingCompleted:
        return index.copyWith(
          totalBookings: index.totalBookings + 1,
          completedBookings: index.completedBookings + 1,
          lastUpdated: DateTime.now(),
        );
      case ReliabilityEventType.bookingCancelled:
        return index.copyWith(
          totalBookings: index.totalBookings + 1,
          cancelledBookings: index.cancelledBookings + 1,
          lastUpdated: DateTime.now(),
        );
      default:
        return index.copyWith(lastUpdated: DateTime.now());
    }
  }
}

final reliabilityIndexService = ReliabilityIndexService();
