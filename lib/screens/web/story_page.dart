import 'package:flutter/material.dart';
import '../../widgets/gearsh_footer.dart';
import '../../widgets/bottom_nav_bar.dart'; // Import BottomNavBar

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        children: const [
          Expanded(
            child: Center(
              child: Text('Story Page (to be implemented with content)', style: TextStyle(color: Colors.white)),
            ),
          ),
          GearshFooter(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(), // Add BottomNavBar to the bottom of the Scaffold
    );
  }
}
