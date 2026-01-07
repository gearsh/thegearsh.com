class VerificationRequest {
  final String id;
  final String reason;
  String status;
  final DateTime createdAt;

  VerificationRequest({required this.id, required this.reason, required this.status, required this.createdAt});
}

class VerificationService {
  final List<VerificationRequest> _store = [];

  List<VerificationRequest> getAll() => List.unmodifiable(_store);

  void submit(String reason) {
    final req = VerificationRequest(id: DateTime.now().millisecondsSinceEpoch.toString(), reason: reason, status: 'pending', createdAt: DateTime.now());
    _store.add(req);
  }

  void approve(String id) {
    for (var r in _store) {
      if (r.id == id) r.status = 'approved';
    }
  }

  void reject(String id) {
    for (var r in _store) {
      if (r.id == id) r.status = 'rejected';
    }
  }
}

final verificationService = VerificationService();

