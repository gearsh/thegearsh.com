class Dispute {
  final String id;
  final String subject;
  final String description;
  String status;
  final DateTime createdAt;

  Dispute({required this.id, required this.subject, required this.description, required this.status, required this.createdAt});
}

class DisputeService {
  final List<Dispute> _store = [];

  List<Dispute> getAll() => List.unmodifiable(_store);

  Future<List<Dispute>> getDisputes() async {
    // Simulate async (in future this may call an API)
    await Future.delayed(const Duration(milliseconds: 50));
    return getAll();
  }

  Future<void> createDispute(String subject, String description) async {
    create(subject, description);
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> closeDispute(String id) async {
    close(id);
    await Future.delayed(const Duration(milliseconds: 50));
  }

  void create(String subject, String description) {
    final d = Dispute(id: DateTime.now().millisecondsSinceEpoch.toString(), subject: subject, description: description, status: 'open', createdAt: DateTime.now());
    _store.add(d);
  }

  void close(String id) {
    for (var d in _store) {
      if (d.id == id) d.status = 'closed';
    }
  }
}

final disputeService = DisputeService();

