import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({Key? key}) : super(key: key);

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> with TickerProviderStateMixin {
  late AnimationController _floatingGlowController;

  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate950 = Color(0xFF020617);

  @override
  void initState() {
    super.initState();
    _floatingGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingGlowController.dispose();
    super.dispose();
  }

  List<Widget> _buildFloatingGlows(double screenWidth, double screenHeight) {
    return [
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            left: -150 + (60 * math.sin(value * math.pi)),
            bottom: -200 + (40 * math.cos(value * math.pi)),
            child: Container(
              height: 500,
              width: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_cyan500.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            right: -100 + (30 * math.cos(value * math.pi)),
            top: -150 + (50 * math.sin(value * math.pi)),
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_sky500.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        children: [
          Divider(
            height: 1.5,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2025 Gearsh. All rights reserved.',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Privacy',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Terms',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required List<Color> gradient,
    required String description,
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: gradient[0].withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradient),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.search_rounded,
        'title': 'Find Creative Talent',
        'description': 'Browse a curated selection of DJs, photographers, and more.',
        'gradient': [_sky500, _cyan500],
      },
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Book Instantly',
        'description': 'Seamless booking experience with instant confirmation.',
        'gradient': [_cyan500, _sky400],
      },
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'title': 'Direct Communication',
        'description': 'Connect and chat with artists directly to plan your event.',
        'gradient': [_sky400, _cyan500],
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Wrap(
        spacing: 40,
        runSpacing: 40,
        alignment: WrapAlignment.center,
        children: features.map((feature) {
          return _buildFeatureCard(
            gradient: feature['gradient'] as List<Color>,
            description: feature['description'] as String,
            title: feature['title'] as String,
            icon: feature['icon'] as IconData,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'The Ultimate Artist E-Booking Service.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 52,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect with DJs, photographers, videographers and more. Book instantly for your next event.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/signup'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        backgroundColor: _sky500,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        side: BorderSide(color: _sky500.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('I\'m an Artist', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: AnimatedBuilder(
                    animation: _floatingGlowController,
                    builder: (context, child) {
                      final value = _floatingGlowController.value;
                      return Transform.translate(
                        offset: Offset(0, 15 * math.sin(value * math.pi)),
                        child: Transform.rotate(
                          angle: -0.1 + (0.05 * math.sin(value * math.pi)),
                          child: Container(
                            height: 400,
                            width: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/storyboard.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: 400,
                  width: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_sky500.withOpacity(0.3), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/gearsh_logo.png', width: 36, height: 36),
          Row(
            children: [
              _buildAppBarButton('About'),
              const SizedBox(width: 20),
              _buildAppBarButton('Discover'),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: _sky500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign In', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: screenHeight,
        width: screenWidth,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_slate950, _slate900, _slate950],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              ..._buildFloatingGlows(screenWidth, screenHeight),
              Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 80),
                  _buildHeroSection(),
                  const SizedBox(height: 120),
                  _buildFeaturesSection(),
                  const SizedBox(height: 120),
                  _buildFooter(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
