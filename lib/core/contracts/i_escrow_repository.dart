abstract class IEscrowRepository {
  Future<EscrowSummary?> getForBooking(String bookingId);
}

class EscrowLedgerEntry {
  final String id;
  final String eventType;
  final double amount;
  final String? note;
  final DateTime createdAt;

  const EscrowLedgerEntry({
    required this.id,
    required this.eventType,
    required this.amount,
    this.note,
    required this.createdAt,
  });
}

class EscrowSummary {
  final String bookingId;
  final String bookingStatus;
  final String currency;
  final double totalHeld;
  final double totalReleased;
  final double totalRefunded;
  final double remaining;
  final String status;
  final List<EscrowLedgerEntry> ledger;

  const EscrowSummary({
    required this.bookingId,
    required this.bookingStatus,
    required this.currency,
    required this.totalHeld,
    required this.totalReleased,
    required this.totalRefunded,
    required this.remaining,
    required this.status,
    this.ledger = const [],
  });
}
