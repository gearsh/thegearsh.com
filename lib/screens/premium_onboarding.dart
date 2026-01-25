// Gearsh App - Premium Multi-Page Animated Onboarding
// Apple-level polish with elegant sequential animations
// Full onboarding flow with multiple screens

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Complete premium onboarding experience for Gearsh
class GearshPremiumOnboarding extends StatefulWidget {
  const GearshPremiumOnboarding({super.key});

  @override
  State<GearshPremiumOnboarding> createState() => _GearshPremiumOnboardingState();
}

class _GearshPremiumOnboardingState extends State<GearshPremiumOnboarding>
    with TickerProviderStateMixin {

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Background animation
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  // Colors
  static const Color _bgDark = Color(0xFF020617);
  static const Color _bgMid = Color(0xFF0F172A);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _cyan500 = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Animated background
          _buildBackground(),

          // Page content
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: const [
              _OnboardingPage1(),
              _OnboardingPage2(),
              _OnboardingPage3(),
            ],
          ),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bgDark, _bgMid, _bgDark],
                ),
              ),
            ),
            // Floating orb 1
            Positioned(
              top: size.height * 0.1 + (_bgAnimation.value * 20),
              right: size.width * 0.1 - (_bgAnimation.value * 15),
              child: _buildOrb(_sky400, size.width * 0.5, 0.12),
            ),
            // Floating orb 2
            Positioned(
              bottom: size.height * 0.2 - (_bgAnimation.value * 25),
              left: size.width * 0.05 + (_bgAnimation.value * 10),
              child: _buildOrb(_cyan400, size.width * 0.4, 0.1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrb(Color color, double size, double opacity) {
    final alpha = (opacity * 255).round();
    final halfAlpha = (opacity * 0.5 * 255).round();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withAlpha(alpha),
            color.withAlpha(halfAlpha),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final padding = MediaQuery.of(context).padding;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(32, 0, 32, padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => _buildIndicator(index)),
              ),
              const SizedBox(height: 32),
              // CTA Button
              _buildCTAButton(),
              const SizedBox(height: 16),
              // Skip button
              if (_currentPage < 2)
                GestureDetector(
                  onTap: _completeOnboarding,
                  child: Text(
                    'skip',
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isActive
            ? const LinearGradient(colors: [_sky400, _cyan400])
            : null,
        color: isActive ? null : Colors.white.withAlpha(51),
      ),
    );
  }

  Widget _buildCTAButton() {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_sky500, _cyan500]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _sky500.withAlpha(77),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _currentPage == 2 ? 'get started' : 'continue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 1: Hero text animation - "more bookings, more gigs, more artists"
class _OnboardingPage1 extends StatefulWidget {
  const _OnboardingPage1();

  @override
  State<_OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<_OnboardingPage1>
    with TickerProviderStateMixin {

  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  late Animation<double> _opacity1, _opacity2, _opacity3;
  late Animation<Offset> _slide1, _slide2, _slide3;
  late Animation<double> _scale1, _scale2, _scale3;

  // Timing
  static const int _duration = 700;
  static const int _stagger = 500;
  static const int _initialDelay = 300;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Controller 1
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: _duration),
      vsync: this,
    );
    _opacity1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller1, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slide1 = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller1, curve: const Interval(0, 0.8, curve: Curves.easeOutCubic)),
    );
    _scale1 = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller1, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)),
    );

    // Controller 2
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: _duration),
      vsync: this,
    );
    _opacity2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller2, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slide2 = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller2, curve: const Interval(0, 0.8, curve: Curves.easeOutCubic)),
    );
    _scale2 = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller2, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)),
    );

    // Controller 3
    _controller3 = AnimationController(
      duration: const Duration(milliseconds: _duration),
      vsync: this,
    );
    _opacity3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller3, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slide3 = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller3, curve: const Interval(0, 0.8, curve: Curves.easeOutCubic)),
    );
    _scale3 = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller3, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: _initialDelay));
    if (!mounted) return;
    _controller1.forward();

    await Future.delayed(const Duration(milliseconds: _stagger));
    if (!mounted) return;
    _controller2.forward();

    await Future.delayed(const Duration(milliseconds: _stagger));
    if (!mounted) return;
    _controller3.forward();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // Phrase 1
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, _) => Opacity(
              opacity: _opacity1.value,
              child: SlideTransition(
                position: _slide1,
                child: Transform.scale(
                  scale: _scale1.value,
                  child: _buildText('more bookings,'),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Phrase 2 (accent)
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, _) => Opacity(
              opacity: _opacity2.value,
              child: SlideTransition(
                position: _slide2,
                child: Transform.scale(
                  scale: _scale2.value,
                  child: _buildText('more gigs,', isAccent: true),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Phrase 3
          AnimatedBuilder(
            animation: _controller3,
            builder: (context, _) => Opacity(
              opacity: _opacity3.value,
              child: SlideTransition(
                position: _slide3,
                child: Transform.scale(
                  scale: _scale3.value,
                  child: _buildText('more artists'),
                ),
              ),
            ),
          ),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  Widget _buildText(String text, {bool isAccent = false}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isAccent ? const Color(0xFF38BDF8) : Colors.white,
        fontSize: 42,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    );
  }
}

/// Page 2: For Artists
class _OnboardingPage2 extends StatefulWidget {
  const _OnboardingPage2();

  @override
  State<_OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<_OnboardingPage2>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF38BDF8).withAlpha(51),
                        const Color(0xFF22D3EE).withAlpha(51),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Color(0xFF38BDF8),
                    size: 40,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'for artists',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'showcase your talent,\nget discovered,\nget booked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Build your portfolio, set your rates,\nand connect with clients worldwide.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 3: For Clients
class _OnboardingPage3 extends StatefulWidget {
  const _OnboardingPage3();

  @override
  State<_OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<_OnboardingPage3>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF22D3EE).withOpacity(0.2),
                        const Color(0xFF38BDF8).withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: Color(0xFF22D3EE),
                    size: 40,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'for clients',
                  style: TextStyle(
                    color: Color(0xFF22D3EE),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'find the perfect artist\nfor your event',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Browse verified talent, book securely,\nand make your event unforgettable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget for animations
class AnimatedBuilder extends StatelessWidget {
  final Animation<dynamic> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedWidget2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedWidget2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedWidget2({
    super.key,
    required Animation<dynamic> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
