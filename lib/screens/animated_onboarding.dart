// Gearsh App - Premium Onboarding Animation
// Elegant sequential text reveal with smooth, premium motion
// Inspired by modern lifestyle app onboarding patterns

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium animated onboarding screen for Gearsh
/// Features elegant sequential text animations with Apple-level polish
class GearshAnimatedOnboarding extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const GearshAnimatedOnboarding({
    super.key,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<GearshAnimatedOnboarding> createState() => _GearshAnimatedOnboardingState();
}

class _GearshAnimatedOnboardingState extends State<GearshAnimatedOnboarding>
    with TickerProviderStateMixin {

  // Animation controllers for each phrase
  late AnimationController _phrase1Controller;
  late AnimationController _phrase2Controller;
  late AnimationController _phrase3Controller;
  late AnimationController _ctaController;
  late AnimationController _backgroundController;

  // Animations
  late Animation<double> _phrase1Opacity;
  late Animation<Offset> _phrase1Slide;
  late Animation<double> _phrase1Scale;

  late Animation<double> _phrase2Opacity;
  late Animation<Offset> _phrase2Slide;
  late Animation<double> _phrase2Scale;

  late Animation<double> _phrase3Opacity;
  late Animation<Offset> _phrase3Slide;
  late Animation<double> _phrase3Scale;

  late Animation<double> _ctaOpacity;
  late Animation<double> _ctaScale;

  late Animation<double> _backgroundGlow;

  // Timing configuration (in milliseconds)
  static const int _initialDelay = 400;
  static const int _phraseDuration = 800;
  static const int _phraseStagger = 600;
  static const int _ctaDelay = 400;

  // Colors
  static const Color _bgDark = Color(0xFF020617);
  static const Color _bgMid = Color(0xFF0F172A);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeAnimations() {
    // Background glow animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Phrase 1: "more bookings,"
    _phrase1Controller = AnimationController(
      duration: const Duration(milliseconds: _phraseDuration),
      vsync: this,
    );

    _phrase1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _phrase1Controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _phrase1Slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _phrase1Controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _phrase1Scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _phrase1Controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Phrase 2: "more gigs,"
    _phrase2Controller = AnimationController(
      duration: const Duration(milliseconds: _phraseDuration),
      vsync: this,
    );

    _phrase2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _phrase2Controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _phrase2Slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _phrase2Controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _phrase2Scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _phrase2Controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Phrase 3: "more artists"
    _phrase3Controller = AnimationController(
      duration: const Duration(milliseconds: _phraseDuration),
      vsync: this,
    );

    _phrase3Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _phrase3Controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _phrase3Slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _phrase3Controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _phrase3Scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _phrase3Controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // CTA Button
    _ctaController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _ctaOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctaController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _ctaScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctaController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  Future<void> _startAnimationSequence() async {
    // Initial delay for screen settle
    await Future.delayed(const Duration(milliseconds: _initialDelay));

    // Phrase 1: "more bookings,"
    _phrase1Controller.forward();

    // Phrase 2: "more gigs," (staggered)
    await Future.delayed(const Duration(milliseconds: _phraseStagger));
    _phrase2Controller.forward();

    // Phrase 3: "more artists" (staggered)
    await Future.delayed(const Duration(milliseconds: _phraseStagger));
    _phrase3Controller.forward();

    // CTA Button (after phrases complete)
    await Future.delayed(const Duration(milliseconds: _phraseDuration + _ctaDelay));
    _ctaController.forward();
  }

  @override
  void dispose() {
    _phrase1Controller.dispose();
    _phrase2Controller.dispose();
    _phrase3Controller.dispose();
    _ctaController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(size),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildSkipButton(),
                    ),
                  ),

                  // Spacer to center content
                  const Spacer(flex: 2),

                  // Animated phrases
                  _buildAnimatedPhrases(),

                  // Spacer
                  const Spacer(flex: 2),

                  // CTA Button
                  _buildCTAButton(),

                  SizedBox(height: padding.bottom + 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundGlow,
      builder: (context, child) {
        return Stack(
          children: [
            // Base gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgDark, _bgMid, _bgDark],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Subtle animated glow - top right
            Positioned(
              top: -size.height * 0.2,
              right: -size.width * 0.3,
              child: Opacity(
                opacity: 0.15 + (_backgroundGlow.value * 0.1),
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _sky400.withAlpha(102),
                        _sky400.withAlpha(26),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Subtle animated glow - bottom left
            Positioned(
              bottom: -size.height * 0.15,
              left: -size.width * 0.3,
              child: Opacity(
                opacity: 0.12 + (_backgroundGlow.value * 0.08),
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _cyan400.withAlpha(77),
                        _cyan400.withAlpha(26),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkipButton() {
    return FadeTransition(
      opacity: _ctaOpacity,
      child: GestureDetector(
        onTap: widget.onSkip ?? widget.onComplete,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'skip',
                style: TextStyle(
                  color: _textSecondary.withAlpha(179),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPhrases() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Phrase 1: "more bookings,"
        AnimatedBuilder(
          animation: _phrase1Controller,
          builder: (context, child) {
            return Opacity(
              opacity: _phrase1Opacity.value,
              child: SlideTransition(
                position: _phrase1Slide,
                child: Transform.scale(
                  scale: _phrase1Scale.value,
                  child: _buildPhrase('more bookings,', isAccent: false),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Phrase 2: "more gigs,"
        AnimatedBuilder(
          animation: _phrase2Controller,
          builder: (context, child) {
            return Opacity(
              opacity: _phrase2Opacity.value,
              child: SlideTransition(
                position: _phrase2Slide,
                child: Transform.scale(
                  scale: _phrase2Scale.value,
                  child: _buildPhrase('more gigs,', isAccent: true),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Phrase 3: "more artists"
        AnimatedBuilder(
          animation: _phrase3Controller,
          builder: (context, child) {
            return Opacity(
              opacity: _phrase3Opacity.value,
              child: SlideTransition(
                position: _phrase3Slide,
                child: Transform.scale(
                  scale: _phrase3Scale.value,
                  child: _buildPhrase('more artists', isAccent: false),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhrase(String text, {bool isAccent = false}) {
    // Typography: Clean, modern, lowercase
    // Font: System default (San Francisco on iOS) for premium feel
    // Weight: Light to Regular for elegance
    // Size: 42-48pt for hero text
    // Letter spacing: Slightly loose for breathing room

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isAccent ? _sky400 : _textPrimary,
        fontSize: 44,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        height: 1.15,
      ),
    );
  }

  Widget _buildCTAButton() {
    return AnimatedBuilder(
      animation: _ctaController,
      builder: (context, child) {
        return Opacity(
          opacity: _ctaOpacity.value,
          child: Transform.scale(
            scale: _ctaScale.value,
            child: GestureDetector(
              onTap: widget.onComplete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_sky400, _cyan400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _sky400.withAlpha(77),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'get started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom AnimatedBuilder that takes any Animation
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
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<dynamic> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
