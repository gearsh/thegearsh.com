import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/screens/terms_of_service_page.dart';
import 'package:gearsh_app/screens/privacy_policy_page.dart';

// ---------------------------------------------------------------------------
// Particle data model
// ---------------------------------------------------------------------------
class _Particle {
  final double baseX;
  final double baseY;
  final double size;
  final double opacity;
  final double phaseOffset;
  final double amplitude;
  final Color color;

  const _Particle({
    required this.baseX,
    required this.baseY,
    required this.size,
    required this.opacity,
    required this.phaseOffset,
    required this.amplitude,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
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
  bool _hasSwiped = false;

  // Press-state tracking for scale-on-tap
  bool _buttonPressed = false;
  String? _pressedCard;

  // Animation controllers
  late AnimationController _floatingGlowController;
  late AnimationController _roleSelectionController;
  late AnimationController _pulseController;
  late AnimationController _swipeHintController;
  late AnimationController _particleController;

  // Staggered card animations derived from _roleSelectionController
  late Animation<double> _card1Anim;
  late Animation<double> _card2Anim;
  late Animation<double> _card3Anim;

  // Particles
  late List<_Particle> _particles;

  // ---------------------------------------------------------------------------
  // Color constants
  // ---------------------------------------------------------------------------
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _violet500 = Color(0xFF8B5CF6);
  static const Color _violet400 = Color(0xFFA78BFA);

  // ---------------------------------------------------------------------------
  // Onboarding slide data
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _floatingGlowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _roleSelectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _swipeHintController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Staggered card animations
    _card1Anim = CurvedAnimation(
      parent: _roleSelectionController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _card2Anim = CurvedAnimation(
      parent: _roleSelectionController,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
    );
    _card3Anim = CurvedAnimation(
      parent: _roleSelectionController,
      curve: const Interval(0.4, 0.95, curve: Curves.easeOut),
    );

    // Generate particles
    final random = math.Random(42);
    final particleColors = [
      _sky400,
      _sky500,
      _cyan400,
      _cyan500,
      _violet400,
      _violet500,
      Colors.white,
    ];
    _particles = List.generate(20, (_) {
      return _Particle(
        baseX: random.nextDouble(),
        baseY: random.nextDouble(),
        size: 1.5 + random.nextDouble() * 2.5,
        opacity: 0.15 + random.nextDouble() * 0.35,
        phaseOffset: random.nextDouble(),
        amplitude: 0.03 + random.nextDouble() * 0.05,
        color: particleColors[random.nextInt(particleColors.length)],
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingGlowController.dispose();
    _roleSelectionController.dispose();
    _pulseController.dispose();
    _swipeHintController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      if (page > 0) _hasSwiped = true;
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      setState(() => _hasSwiped = true);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showRoleSelectionScreen();
    }
  }

  void _showRoleSelectionScreen() {
    setState(() => _showRoleSelection = true);
    _roleSelectionController.forward();
  }

  void _selectRole(String role) {
    if (role == 'client') {
      userRoleService.setGuestRole(UserRole.client);
      context.go('/home');
    } else if (role == 'artist') {
      userRoleService.setGuestRole(UserRole.artist);
      context.go('/dashboard');
    } else if (role == 'fan') {
      userRoleService.setGuestRole(UserRole.fan);
      context.go('/home');
    }
  }

  // ---------------------------------------------------------------------------
  // Responsive helpers
  // ---------------------------------------------------------------------------
  bool _isSmall(double w) => w < 360;
  bool _isTablet(double w) => w >= 600 && w < 1024;
  bool _isDesktop(double w) => w >= 1024;

  double _fs(double w,
      {required double s,
      required double p,
      required double t,
      required double d}) {
    if (_isSmall(w)) return s;
    if (_isTablet(w)) return t;
    if (_isDesktop(w)) return d;
    return p;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Scaffold(
          body: Container(
            width: w,
            height: h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_slate950, _slate900, _slate950],
              ),
            ),
            child: Stack(
              children: [
                ..._buildFloatingGlows(w, h),
                _buildParticles(w, h),
                SafeArea(
                  child: _showRoleSelection
                      ? _buildRoleSelectionScreen(w)
                      : _buildOnboardingContent(w, h),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Background: floating glow orbs
  // ---------------------------------------------------------------------------
  List<Widget> _buildFloatingGlows(double w, double h) {
    return [
      // Top-right sky glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (_, __) {
          final v = _floatingGlowController.value;
          return Positioned(
            top: -100 + 30 * math.sin(v * math.pi),
            right: -80 + 20 * math.cos(v * math.pi),
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _sky500.withAlpha(50),
                    _sky500.withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Bottom-left cyan glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (_, __) {
          final v = _floatingGlowController.value;
          return Positioned(
            bottom: -120 + 25 * math.cos(v * math.pi),
            left: -100 + 35 * math.sin(v * math.pi),
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyan500.withAlpha(40),
                    _cyan500.withAlpha(12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Center mid-page sky glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (_, __) {
          final v = _floatingGlowController.value;
          return Positioned(
            top: h * 0.3 + 40 * math.sin(v * math.pi * 2),
            left: w * 0.5 - 110 + 30 * math.cos(v * math.pi),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_sky400.withAlpha(30), Colors.transparent],
                ),
              ),
            ),
          );
        },
      ),
      // Violet accent glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (_, __) {
          final v = _floatingGlowController.value;
          return Positioned(
            top: h * 0.6 + 20 * math.cos(v * math.pi * 1.5),
            right: w * 0.1 + 15 * math.sin(v * math.pi),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _violet500.withAlpha(30),
                    _violet400.withAlpha(10),
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

  // ---------------------------------------------------------------------------
  // Background: floating particles
  // ---------------------------------------------------------------------------
  Widget _buildParticles(double w, double h) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (_, __) {
        final t = _particleController.value;
        return Stack(
          children: _particles.map((p) {
            final x =
                (p.baseX +
                        p.amplitude *
                            math.sin(2 * math.pi * (t + p.phaseOffset))) *
                    w;
            final y =
                (p.baseY +
                        p.amplitude *
                            math.cos(
                                2 * math.pi * (t + p.phaseOffset * 0.7))) *
                    h;
            return Positioned(
              left: x - p.size / 2,
              top: y - p.size / 2,
              child: Container(
                width: p.size,
                height: p.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.color.withAlpha((p.opacity * 255).round()),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Onboarding slides content
  // ---------------------------------------------------------------------------
  Widget _buildOnboardingContent(double w, double h) {
    final maxW = _isDesktop(w) ? 640.0 : w;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: _buildProgressBar(),
            ),
            // Header: logo + skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildHeaderRow(w),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (_, i) => _buildOnboardingSlide(i, w),
              ),
            ),
            // Swipe hint + dot indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: (!_hasSwiped && _currentPage == 0) ? 1.0 : 0.0,
                    child: _buildSwipeHint(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (i) => _buildPageIndicator(i),
                    ),
                  ),
                ],
              ),
            ),
            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildNextButton(w),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (_, cons) {
          return Stack(
            children: [
              Container(
                width: cons.maxWidth,
                height: 3,
                decoration: BoxDecoration(
                  color: _slate800,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: cons.maxWidth *
                    (_currentPage + 1) /
                    _onboardingData.length,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient:
                      const LinearGradient(colors: [_sky500, _cyan500]),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(100),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow(double w) {
    final isSmall = _isSmall(w);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: isSmall ? 32 : 36,
              height: isSmall ? 32 : 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: _sky500.withAlpha(77), width: 1.5),
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
              child: Text(
                'Gearsh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showRoleSelectionScreen,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _sky500.withAlpha(51)),
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
    );
  }

  Widget _buildOnboardingSlide(int index, double w) {
    final data = _onboardingData[index];
    final isCurrentPage = _currentPage == index;
    final isSmall = _isSmall(w);
    final isTablet = _isTablet(w);
    final isDesktop = _isDesktop(w);

    final containerSize = isSmall
        ? 90.0
        : isTablet
            ? 150.0
            : isDesktop
                ? 160.0
                : 120.0;
    final iconSize = isSmall
        ? 36.0
        : isTablet
            ? 60.0
            : isDesktop
                ? 64.0
                : 48.0;
    final hPad = isSmall ? 20.0 : isTablet ? 56.0 : 32.0;
    final topSpacing = isSmall ? 16.0 : isTablet ? 48.0 : 32.0;
    final midSpacing = isSmall ? 20.0 : isTablet ? 40.0 : 32.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isCurrentPage ? 1.0 : 0.5,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: topSpacing),
              // Icon with float + scale pulse
              AnimatedBuilder(
                animation: _floatingGlowController,
                builder: (_, child) {
                  final v = _floatingGlowController.value;
                  final floatY = 8 * math.sin(v * math.pi);
                  final scale = 1.0 + 0.04 * math.sin(v * math.pi * 2);
                  return Transform.translate(
                    offset: Offset(0, floatY),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: Container(
                  width: containerSize,
                  height: containerSize,
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
                      color: (data['gradient'] as List<Color>)[0]
                          .withAlpha(77),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (data['gradient'] as List<Color>)[0]
                            .withAlpha(60),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Icon(
                    data['icon'] as IconData,
                    size: iconSize,
                    color: (data['gradient'] as List<Color>)[0],
                  ),
                ),
              ),
              SizedBox(height: midSpacing),
              // Title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: data['gradient'] as List<Color>,
                ).createShader(bounds),
                child: Text(
                  data['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _fs(w, s: 20, p: 26, t: 30, d: 32),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: isSmall ? 8 : 12),
              // Subtitle
              Text(
                data['subtitle'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(153),
                  fontSize: _fs(w, s: 13, p: 15, t: 17, d: 17),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: isSmall ? 14 : 20),
              // Description
              Text(
                data['description'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(128),
                  fontSize: _fs(w, s: 12, p: 14, t: 15, d: 15),
                  height: 1.6,
                ),
              ),
              SizedBox(height: isSmall ? 16 : 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return AnimatedBuilder(
      animation: _swipeHintController,
      builder: (_, __) {
        final v = _swipeHintController.value;
        return Opacity(
          opacity: 0.7 - 0.4 * v,
          child: Transform.translate(
            offset: Offset(-12 * v, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Swipe',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _sky400.withAlpha(150),
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
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
                )
              ]
            : null,
      ),
    );
  }

  Widget _buildNextButton(double w) {
    final isLastPage = _currentPage == _onboardingData.length - 1;
    final fontSize = _fs(w, s: 15, p: 17, t: 18, d: 18);

    return Listener(
      onPointerDown: (_) => setState(() => _buttonPressed = true),
      onPointerUp: (_) => setState(() => _buttonPressed = false),
      onPointerCancel: (_) => setState(() => _buttonPressed = false),
      child: GestureDetector(
        onTap: _nextPage,
        child: AnimatedScale(
          scale: _buttonPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final pulse = _pulseController.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha((50 + 60 * pulse).round()),
                      blurRadius: 16 + 20 * pulse,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color:
                          _cyan500.withAlpha((20 + 30 * pulse).round()),
                      blurRadius: 30 + 20 * pulse,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage
                          ? Icons.arrow_forward_rounded
                          : Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Role selection screen
  // ---------------------------------------------------------------------------
  Widget _buildRoleSelectionScreen(double w) {
    final isSmall = _isSmall(w);
    final isTablet = _isTablet(w);
    final isDesktop = _isDesktop(w);
    final maxW = isDesktop ? 660.0 : (isTablet ? 720.0 : w);
    final hPad = isSmall ? 16.0 : isTablet ? 40.0 : 24.0;
    final useWideCards = isTablet || isDesktop;

    return FadeTransition(
      opacity: _roleSelectionController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
              parent: _roleSelectionController, curve: Curves.easeOut),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [
                  SizedBox(height: isSmall ? 16 : 24),
                  // Logo
                  _buildRoleSelectionLogo(w),
                  SizedBox(height: isSmall ? 14 : 20),
                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_sky400, _cyan400],
                    ).createShader(bounds),
                    child: Text(
                      'Join Gearsh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _fs(w, s: 22, p: 28, t: 32, d: 34),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmall ? 6 : 8),
                  Text(
                    'Choose how you want to use Gearsh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(153),
                      fontSize:
                          _fs(w, s: 13, p: 15, t: 16, d: 16),
                    ),
                  ),
                  SizedBox(height: isSmall ? 18 : 28),
                  // Role cards
                  useWideCards
                      ? _buildWideRoleCards(w)
                      : _buildMobileRoleCards(w, isSmall),
                  SizedBox(height: isSmall ? 16 : 24),
                  // Sign in
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
                          shaderCallback: (bounds) =>
                              const LinearGradient(
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
                  // Terms
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
                          const TextSpan(
                              text: 'By continuing, you agree to our '),
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
                                    builder: (_) =>
                                        const TermsOfServicePage(),
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
                                    builder: (_) =>
                                        const PrivacyPolicyPage(),
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
        ),
      ),
    );
  }

  Widget _buildRoleSelectionLogo(double w) {
    final isSmall = _isSmall(w);
    final size = isSmall ? 48.0 : 60.0;
    final r = isSmall ? 14.0 : 18.0;
    final ri = isSmall ? 12.0 : 16.0;
    final iconSize = isSmall ? 22.0 : 28.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: _sky500.withAlpha(77), width: 2),
        boxShadow: [
          BoxShadow(color: _sky500.withAlpha(51), blurRadius: 30),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ri),
        child: Image.asset(
          'assets/images/gearsh_logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: _slate800,
            child: Icon(Icons.music_note_rounded,
                color: _sky400, size: iconSize),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileRoleCards(double w, bool isSmall) {
    final spacing = isSmall ? 10.0 : 14.0;
    return Column(
      children: [
        _buildCardWrapper(
          anim: _card1Anim,
          cardId: 'client',
          child: _buildRoleCard(
            icon: Icons.event_rounded,
            title: "I'm a Client",
            description:
                'Find and book talented artists for your events, parties, and special occasions.',
            gradient: [_sky500, _cyan500],
            onTap: () => _selectRole('client'),
            w: w,
          ),
        ),
        SizedBox(height: spacing),
        _buildCardWrapper(
          anim: _card2Anim,
          cardId: 'artist',
          child: _buildRoleCard(
            icon: Icons.music_note_rounded,
            title: "I'm an Artist",
            description:
                'Showcase your talent, manage bookings, and grow your creative business.',
            gradient: [_cyan400, _sky400],
            onTap: () => _selectRole('artist'),
            w: w,
          ),
        ),
        SizedBox(height: spacing),
        _buildCardWrapper(
          anim: _card3Anim,
          cardId: 'fan',
          child: _buildRoleCard(
            icon: Icons.favorite_rounded,
            title: "I'm a Fan",
            description:
                'Follow your favourite artists, discover gigs, buy tickets and merch.',
            gradient: [_violet500, _violet400],
            onTap: () => _selectRole('fan'),
            w: w,
          ),
        ),
      ],
    );
  }

  // 2-column grid for tablet / desktop
  Widget _buildWideRoleCards(double w) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCardWrapper(
                anim: _card1Anim,
                cardId: 'client',
                child: _buildRoleCard(
                  icon: Icons.event_rounded,
                  title: "I'm a Client",
                  description:
                      'Find and book talented artists for your events.',
                  gradient: [_sky500, _cyan500],
                  onTap: () => _selectRole('client'),
                  w: w,
                  vertical: true,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCardWrapper(
                anim: _card2Anim,
                cardId: 'artist',
                child: _buildRoleCard(
                  icon: Icons.music_note_rounded,
                  title: "I'm an Artist",
                  description:
                      'Showcase your talent and grow your creative business.',
                  gradient: [_cyan400, _sky400],
                  onTap: () => _selectRole('artist'),
                  w: w,
                  vertical: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildCardWrapper(
          anim: _card3Anim,
          cardId: 'fan',
          child: _buildRoleCard(
            icon: Icons.favorite_rounded,
            title: "I'm a Fan",
            description:
                'Follow your favourite artists, discover gigs, buy tickets and merch.',
            gradient: [_violet500, _violet400],
            onTap: () => _selectRole('fan'),
            w: w,
          ),
        ),
      ],
    );
  }

  /// Wraps a role card with staggered fade-in + scale-on-tap.
  Widget _buildCardWrapper({
    required Animation<double> anim,
    required String cardId,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(anim),
        child: Listener(
          onPointerDown: (_) =>
              setState(() => _pressedCard = cardId),
          onPointerUp: (_) =>
              setState(() => _pressedCard = null),
          onPointerCancel: (_) =>
              setState(() => _pressedCard = null),
          child: AnimatedScale(
            scale: _pressedCard == cardId ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: child,
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
    required double w,
    bool vertical = false,
  }) {
    final isSmall = _isSmall(w);
    final isTablet = _isTablet(w);
    final pad = isSmall ? 12.0 : isTablet ? 20.0 : 18.0;
    final br = isSmall ? 16.0 : 20.0;
    final icoBoxSize = isSmall ? 40.0 : isTablet ? 52.0 : 50.0;
    final icoSize = isSmall ? 20.0 : isTablet ? 26.0 : 24.0;
    final titleFs = _fs(w, s: 13, p: 15, t: 16, d: 16);
    final descFs = _fs(w, s: 10, p: 12, t: 13, d: 13);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (_, __) {
          final t = _floatingGlowController.value;
          final ang = t * math.pi * 2;
          final borderGrad = LinearGradient(
            begin: Alignment(math.cos(ang), math.sin(ang)),
            end: Alignment(-math.cos(ang), -math.sin(ang)),
            colors: [
              gradient[0].withAlpha(200),
              gradient[1].withAlpha(120),
              gradient[0].withAlpha(80),
            ],
          );

          return Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(br),
              gradient: borderGrad,
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(br - 1.5),
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(br - 1.5),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradient[0].withAlpha(22),
                        _slate900.withAlpha(210),
                      ],
                    ),
                  ),
                  child: vertical
                      ? _cardVertical(
                          icon: icon,
                          title: title,
                          description: description,
                          gradient: gradient,
                          icoBoxSize: icoBoxSize,
                          icoSize: icoSize,
                          titleFs: titleFs,
                          descFs: descFs,
                        )
                      : _cardHorizontal(
                          icon: icon,
                          title: title,
                          description: description,
                          gradient: gradient,
                          icoBoxSize: icoBoxSize,
                          icoSize: icoSize,
                          titleFs: titleFs,
                          descFs: descFs,
                          isSmall: isSmall,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cardHorizontal({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required double icoBoxSize,
    required double icoSize,
    required double titleFs,
    required double descFs,
    required bool isSmall,
  }) {
    return Row(
      children: [
        Container(
          width: icoBoxSize,
          height: icoBoxSize,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(isSmall ? 10 : 14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient[0].withAlpha(51),
                gradient[1].withAlpha(25)
              ],
            ),
            border: Border.all(color: gradient[0].withAlpha(77)),
          ),
          child: Icon(icon, size: icoSize, color: gradient[0]),
        ),
        SizedBox(width: isSmall ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFs,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmall ? 2 : 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withAlpha(153),
                  fontSize: descFs,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: isSmall ? 6 : 10),
        Container(
          width: isSmall ? 30 : 36,
          height: isSmall ? 30 : 36,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(isSmall ? 8 : 10),
            gradient: LinearGradient(colors: gradient),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withAlpha(77),
                blurRadius: 12,
              )
            ],
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: isSmall ? 16 : 18,
          ),
        ),
      ],
    );
  }

  Widget _cardVertical({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required double icoBoxSize,
    required double icoSize,
    required double titleFs,
    required double descFs,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: icoBoxSize,
          height: icoBoxSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient[0].withAlpha(51),
                gradient[1].withAlpha(25)
              ],
            ),
            border: Border.all(color: gradient[0].withAlpha(77)),
          ),
          child: Icon(icon, size: icoSize, color: gradient[0]),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleFs,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withAlpha(153),
            fontSize: descFs,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: gradient),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withAlpha(77),
                blurRadius: 12,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFs - 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}
