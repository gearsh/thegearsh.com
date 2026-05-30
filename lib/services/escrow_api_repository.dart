import 'package:gearsh_app/core/contracts/i_escrow_repository.dart';
import 'package:gearsh_app/services/api_service.dart';

class EscrowApiRepository implements IEscrowRepository {
  final ApiService _api;

  EscrowApiRepository(this._api);

  @override
  Future<EscrowSummary?> getForBooking(String bookingId) async {
    final response = await _api.get('/escrow/$bookingId');
    final data = response.getData<Map<String, dynamic>>();
    if (data == null) return null;
    final ledgerRaw = data['ledger'] as List<dynamic>? ?? [];
    final ledger = ledgerRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return EscrowLedgerEntry(
        id: m['id'] as String,
        eventType: m['event_type'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        note: m['note'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();

    return EscrowSummary(
      bookingId: data['booking_id'] as String? ?? bookingId,
      bookingStatus: data['booking_status'] as String? ?? '',
      currency: data['currency'] as String? ?? 'ZAR',
      totalHeld: (data['total_held'] as num?)?.toDouble() ?? 0,
      totalReleased: (data['total_released'] as num?)?.toDouble() ?? 0,
      totalRefunded: (data['total_refunded'] as num?)?.toDouble() ?? 0,
      remaining: (data['remaining'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'pending',
      ledger: ledger,
    );
  }
}
