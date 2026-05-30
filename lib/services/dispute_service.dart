import 'package:gearsh_app/core/contracts/i_dispute_repository.dart';
import 'package:gearsh_app/services/api_service.dart';

class DisputeService implements IDisputeRepository {
  final ApiService _api;

  DisputeService(this._api);

  @override
  Future<List<DisputeRecord>> listDisputes() async {
    final response = await _api.get('/disputes');
    final rows = response.getData<List<dynamic>>();
    if (rows == null) return [];
    return rows.map((row) => _mapDispute(row as Map<String, dynamic>)).toList();
  }

  DisputeRecord _mapDispute(Map<String, dynamic> m) {
    return DisputeRecord(
      id: m['id'] as String,
      bookingId: m['booking_id'] as String? ?? '',
      subject: m['subject'] as String? ?? '',
      description: m['description'] as String? ?? '',
      status: m['status'] as String? ?? 'open',
      severity: m['severity'] as String? ?? 'medium',
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      totalPrice: (m['total_price'] as num?)?.toDouble(),
      eventDate: m['event_date'] as String?,
    );
  }

  @override
  Future<void> createDispute({
    required String bookingId,
    required String subject,
    required String description,
    String severity = 'medium',
  }) async {
    final response = await _api.post('/disputes', body: {
      'booking_id': bookingId,
      'subject': subject,
      'description': description,
      'severity': severity,
    });
    if (!response.success) {
      throw Exception(response.error ?? 'Failed to create dispute');
    }
  }
}
