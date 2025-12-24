import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';

class WaitlistPage extends StatelessWidget {
  const WaitlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Waitlist Page (to be implemented with form and logic)'),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
