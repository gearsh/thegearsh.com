import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/screens/terms_of_service_page.dart';
import 'package:gearsh_app/screens/privacy_policy_page.dart';
import 'dart:math' as math;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showRoleSelection = false;

  // Animation controllers
  late AnimationController _floatingGlowController;
  late AnimationController _slideTransitionController;
  late AnimationController _roleSelectionController;

  // Color constants
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _cyan400 = Color(0xFF22D3EE);

  // Onboarding data
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'icon': Icons.search_rounded,
      'title': 'Find Creative Talent',
      'subtitle': 'Discover extraordinary artists',
      'description':
          'Browse through a curated selection of DJs, photographers, videographers, and more. Find the perfect creative professional for your event.',
      'gradient': [_sky500, _cyan500],
    },
    {
      'icon': Icons.calendar_today_rounded,
      'title': 'Book Instantly',
      'subtitle': 'Seamless booking experience',
      'description':
          'Select your date, choose services, and confirm your booking in just a few taps. No back-and-forth, just instant confirmation.',
      'gradient': [_cyan400, _sky400],
    },
    {
      'icon': Icons.chat_bubble_outline_rounded,
      'title': 'Direct Communication',
      'subtitle': 'Connect with artists directly',
      'description':
          'Chat directly with artists, discuss your vision, and ensure every detail is perfect for your event.',
      'gradient': [_sky400, _cyan500],
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatingGlowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _slideTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _roleSelectionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingGlowController.dispose();
    _slideTransitionController.dispose();
    _roleSelectionController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showRoleSelectionScreen();
    }
  }

  void _showRoleSelectionScreen() {
    setState(() {
      _showRoleSelection = true;
    });
    _roleSelectionController.forward();
  }

  void _selectRole(String role) {
    // Set the user as guest with selected role (they can browse but need to sign up for actions)
    if (role == 'client') {
      userRoleService.setGuestRole(UserRole.client);
      context.go('/home'); // Go to explore/home page with artists
    } else {
      userRoleService.setGuestRole(UserRole.artist);
      context.go('/dashboard'); // Go to artist dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _slate950,
              _slate900,
              _slate950,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated floating glows
            ..._buildFloatingGlows(screenWidth, screenHeight),

            // Main content
            SafeArea(
              child: _showRoleSelection
                  ? _buildRoleSelectionScreen(padding)
                  : _buildOnboardingContent(padding),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingGlows(double screenWidth, double screenHeight) {
    return [
      // Top-right glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            top: -100 + (30 * math.sin(value * math.pi)),
            right: -80 + (20 * math.cos(value * math.pi)),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _sky500.withAlpha(40),
                    _sky500.withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Bottom-left glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            bottom: -120 + (25 * math.cos(value * math.pi)),
            left: -100 + (35 * math.sin(value * math.pi)),
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyan500.withAlpha(35),
                    _cyan500.withAlpha(10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Center floating glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            top: screenHeight * 0.3 + (40 * math.sin(value * math.pi * 2)),
            left: screenWidth * 0.5 - 100 + (30 * math.cos(value * math.pi)),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _sky400.withAlpha(25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildOnboardingContent(EdgeInsets padding) {
    return Column(
      children: [
        // Skip button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _sky500.withAlpha(77),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/gearsh_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.music_note_rounded,
                          color: _sky400,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_sky400, _cyan400],
                    ).createShader(bounds),
                    child: const Text(
                      'Gearsh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              // Skip button
              GestureDetector(
                onTap: _showRoleSelectionScreen,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _sky500.withAlpha(51),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Page view
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return _buildOnboardingSlide(index);
            },
          ),
        ),

        // Page indicators
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingData.length,
              (index) => _buildPageIndicator(index),
            ),
          ),
        ),

        // Next/Get Started button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: _buildNextButton(),
        ),
      ],
    );
  }

  Widget _buildOnboardingSlide(int index) {
    final data = _onboardingData[index];
    final isCurrentPage = _currentPage == index;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isCurrentPage ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            AnimatedBuilder(
              animation: _floatingGlowController,
              builder: (context, child) {
                final value = _floatingGlowController.value;
                return Transform.translate(
                  offset: Offset(0, 8 * math.sin(value * math.pi)),
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (data['gradient'] as List<Color>)[0].withAlpha(51),
                      (data['gradient'] as List<Color>)[1].withAlpha(25),
                    ],
                  ),
                  border: Border.all(
                    color: (data['gradient'] as List<Color>)[0].withAlpha(77),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (data['gradient'] as List<Color>)[0].withAlpha(51),
                      blurRadius: 40,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  data['icon'] as IconData,
                  size: 56,
                  color: (data['gradient'] as List<Color>)[0],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Title with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: data['gradient'] as List<Color>,
              ).createShader(bounds),
              child: Text(
                data['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              data['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(153),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              data['description'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isActive
            ? const LinearGradient(colors: [_sky500, _cyan500])
            : null,
        color: isActive ? null : _slate800,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _sky500.withAlpha(102),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastPage = _currentPage == _onboardingData.length - 1;

    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_sky500, _cyan500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _sky500.withAlpha(77),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? 'Get Started' : 'Next',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLastPage ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionScreen(EdgeInsets padding) {
    return FadeTransition(
      opacity: _roleSelectionController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _roleSelectionController,
          curve: Curves.easeOut,
        )),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo and title
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _sky500.withAlpha(77),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(51),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/gearsh_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _slate800,
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: _sky400,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_sky400, _cyan400],
                ).createShader(bounds),
                child: const Text(
                  'Join Gearsh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Choose how you want to use Gearsh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(153),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // Role cards
              _buildRoleCard(
                icon: Icons.person_search_rounded,
                title: 'I\'m a Client',
                description:
                    'Find and book talented artists for your events, parties, and special occasions.',
                gradient: [_sky500, _cyan500],
                onTap: () => _selectRole('client'),
              ),
              const SizedBox(height: 12),

              _buildRoleCard(
                icon: Icons.music_note_rounded,
                title: 'I\'m an Artist',
                description:
                    'Showcase your talent, manage bookings, and grow your creative business.',
                gradient: [_cyan400, _sky400],
                onTap: () => _selectRole('artist'),
              ),

              const SizedBox(height: 24),

              // Sign In option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_sky400, _cyan400],
                      ).createShader(bounds),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Terms text
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 11,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsOfServicePage(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: '\nand '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient[0].withAlpha(25),
                  gradient[1].withAlpha(13),
                ],
              ),
              border: Border.all(
                color: gradient[0].withAlpha(51),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withAlpha(25),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradient[0].withAlpha(51),
                        gradient[1].withAlpha(25),
                      ],
                    ),
                    border: Border.all(
                      color: gradient[0].withAlpha(77),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: gradient[0],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: gradient),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withAlpha(77),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

