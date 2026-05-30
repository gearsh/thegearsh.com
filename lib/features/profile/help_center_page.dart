import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/core/contracts/i_dispute_repository.dart';
import 'package:gearsh_app/core/di/service_providers.dart';

class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({super.key});

  @override
  ConsumerState<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bookingIdCtrl = TextEditingController();
  late Future<List<DisputeRecord>> _disputesFuture;

  @override
  void initState() {
    super.initState();
    _disputesFuture = Future.value(const <DisputeRecord>[]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _disputesFuture = ref.read(disputeRepositoryProvider).listDisputes();
      });
    });
  }

  Future<void> _reloadDisputes() async {
    setState(() {
      _disputesFuture = ref.read(disputeRepositoryProvider).listDisputes();
    });
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _bookingIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.read(contentRepositoryProvider).copy('help.title', fallback: 'Help Centre')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile-settings');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _bookingIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Booking ID (required for disputes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the issue or dispute',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final subject = _subjectCtrl.text.trim();
                      final desc = _descCtrl.text.trim();
                      final bookingId = _bookingIdCtrl.text.trim();
                      if (subject.isEmpty || desc.isEmpty || bookingId.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(disputeRepositoryProvider).createDispute(
                              bookingId: bookingId,
                              subject: subject,
                              description: desc,
                            );
                        if (!mounted) return;
                        await _reloadDisputes();
                        _subjectCtrl.clear();
                        _descCtrl.clear();
                        _bookingIdCtrl.clear();
                        messenger.showSnackBar(const SnackBar(content: Text('Dispute submitted')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    child: const Text('Submit Dispute'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Your disputes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<DisputeRecord>>(
                future: _disputesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading disputes: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No disputes submitted yet'));
                  }

                  final list = snapshot.data!;
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final d = list[index];
                      return Card(
                        child: ListTile(
                          title: Text(d.subject),
                          subtitle: Text(
                            'Booking: ${d.bookingId}\nStatus: ${d.status}\n${d.description}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
