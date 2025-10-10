import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_controller.dart';

class ArtistDashboardPage extends ConsumerWidget {
  const ArtistDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authControllerProvider).signOut();
              context.go('/auth');
            },
          ),
        ],
      ),
      body: const Center(child: Text('Welcome to the Artist Dashboard')),
    );
  }
}
