import 'package:flutter/material.dart';
import '../../services/verification_service.dart';

class ArtistVerificationPage extends StatefulWidget {
  const ArtistVerificationPage({super.key});

  @override
  State<ArtistVerificationPage> createState() => _ArtistVerificationPageState();
}

class _ArtistVerificationPageState extends State<ArtistVerificationPage> {
  final _controller = TextEditingController();
  List<VerificationRequest> _submissions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _submissions = verificationService.getAll();
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    verificationService.submit(text);
    _controller.clear();
    _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification request submitted')));
  }

  void _approve(String id) {
    verificationService.approve(id);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit verification request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tell us about your artist profile and provide links (website/socials)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _submit, child: const Text('Submit Request')),
            const SizedBox(height: 16),
            const Text('Pending requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: _submissions.isEmpty
                  ? const Center(child: Text('No verification requests yet'))
                  : ListView.builder(
                      itemCount: _submissions.length,
                      itemBuilder: (context, index) {
                        final item = _submissions[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.reason),
                            subtitle: Text('Status: ${item.status}'),
                            trailing: item.status == 'pending'
                                ? TextButton(onPressed: () => _approve(item.id), child: const Text('Approve'))
                                : null,
                          ),
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
