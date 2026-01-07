import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/dispute_service.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late Future<List<Dispute>> _disputesFuture;

  @override
  void initState() {
    super.initState();
    _disputesFuture = DisputeService().getDisputes();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Centre'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            try {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile-settings');
              }
            } catch (e) {
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
                      if (subject.isEmpty || desc.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      await DisputeService().createDispute(subject, desc);
                      if (!mounted) return;
                      setState(() {
                        _disputesFuture = DisputeService().getDisputes();
                      });
                      _subjectCtrl.clear();
                      _descCtrl.clear();
                      messenger.showSnackBar(const SnackBar(content: Text('Dispute submitted')));
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
              child: FutureBuilder<List<Dispute>>(
                future: _disputesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading disputes'));
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
                          subtitle: Text('Status: ${d.status}\n${d.description}'),
                          isThreeLine: true,
                          trailing: d.status == 'open'
                              ? TextButton(
                                  onPressed: () {
                                    DisputeService().closeDispute(d.id).then((_) {
                                      setState(() {
                                        _disputesFuture = DisputeService().getDisputes();
                                      });
                                    });
                                  },
                                  child: const Text('Close'))
                              : null,
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
