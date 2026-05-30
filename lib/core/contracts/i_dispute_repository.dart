abstract class IDisputeRepository {
  Future<List<DisputeRecord>> listDisputes();
  Future<void> createDispute({
    required String bookingId,
    required String subject,
    required String description,
    String severity,
  });
}

class DisputeRecord {
  final String id;
  final String bookingId;
  final String subject;
  final String description;
  final String status;
  final String severity;
  final DateTime createdAt;
  final double? totalPrice;
  final String? eventDate;

  const DisputeRecord({
    required this.id,
    required this.bookingId,
    required this.subject,
    required this.description,
    required this.status,
    this.severity = 'medium',
    required this.createdAt,
    this.totalPrice,
    this.eventDate,
  });
}
