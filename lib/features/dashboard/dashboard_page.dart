import 'package:flutter/material.dart';

class ArtistDashboardPage extends StatelessWidget {
  const ArtistDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artist Dashboard')),
      body: const Center(child: Text('Welcome to the Artist Dashboard')),
    );
  }
}
