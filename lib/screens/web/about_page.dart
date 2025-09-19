import 'package:flutter/material.dart';
import '../../widgets/gearsh_footer.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        children: const [
          Expanded(
            child: Center(
              child: Text('About Page (to be implemented)', style: TextStyle(color: Colors.white)),
            ),
          ),
          GearshFooter(),
        ],
      ),
    );
  }
}
