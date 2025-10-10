import 'package:flutter/material.dart';
import '../../widgets/gearsh_footer.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // transparent background
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/allthestars.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Transparent header overlays the stars directly
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/');
                        },
                        child: Image.asset('assets/images/gearsh_logo.png', height: 48),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'GEARSH',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/login');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/signup');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Main content below header
          Padding(
            padding: const EdgeInsets.only(top: 80), // leave space for header
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ...existing hero section or placeholder...
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(
                          'Features Designed for You',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            return Flex(
                              direction: isWide ? Axis.horizontal : Axis.vertical,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _FeatureCard(
                                  icon: 'assets/images/storyboard.png',
                                  title: 'For Bookers',
                                  description:
                                      'Discover and book verified local talent for your events with secure, in-app payments and transparent booking statuses.',
                                ),
                                const SizedBox(width: 24, height: 24),
                                _FeatureCard(
                                  icon: 'assets/images/gearsh_logo.png',
                                  title: 'For Artists',
                                  description:
                                      'Get discovered by bookers, manage your schedule, and get paid securely and instantly for your gigs.',
                                ),
                                const SizedBox(width: 24, height: 24),
                                _FeatureCard(
                                  icon: 'assets/images/storyboard2.png',
                                  title: 'For Fans',
                                  description:
                                      'Follow your favorite local artists, get notified about new gigs, and discover fresh talent in your area.',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GearshFooter(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.transparent, // transparent card
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0x33000000), // 20% opacity black
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              icon,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFB0B0B0),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
