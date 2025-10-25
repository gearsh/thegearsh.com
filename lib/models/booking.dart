class Booking {
  final String id;
  final String artistId;
  final String clientId;
  final DateTime date;
  final String status;

  Booking({
    required this.id,
    required this.artistId,
    required this.clientId,
    required this.date,
    required this.status,
  });
}
