import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'dart:math' as math;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {

  // ── Colors ──────────────────────────────────────────────
  static const Color _bg     = Color(0xFF020617);
  static const Color _bg2    = Color(0xFF0F172A);
  static const Color _sky    = Color(0xFF0EA5E9);
  static const Color _skyL   = Color(0xFF38BDF8);
  static const Color _cyan   = Color(0xFF06B6D4);
  static const Color _cyanL  = Color(0xFF22D3EE);
  static const Color _border = Color(0x12FFFFFF);
  static const Color _muted  = Color(0x73FFFFFF);

  // ── Animation ───────────────────────────────────────────
  late AnimationController _tickerCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tickerCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 30),
    )..repeat();
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  // ── Helpers ─────────────────────────────────────────────
  Widget _divider({bool vertical = false}) => Container(
    width:  vertical ? 1 : double.infinity,
    height: vertical ? double.infinity : 1,
    color: _border,
  );

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w500,
      letterSpacing: 2.0, color: _skyL,
    ),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 36, fontWeight: FontWeight.w800,
      letterSpacing: -0.5, height: 1.1,
      color: Colors.white,
      fontFamily: 'Syne',
    ),
  );

  // ── Gradient text ────────────────────────────────────────
  Widget _gradientText(String text, double size, FontWeight w) =>
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [_skyL, _cyanL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(b),
        child: Text(text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: w,
            letterSpacing: -0.5,
            fontFamily: 'Syne',
          ),
        ),
      );

  // ── Outline text ─────────────────────────────────────────
  Widget _outlineText(String text, double size) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      fontFamily: 'Syne',
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _skyL.withAlpha(77),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 860;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(
              children: [
                // Nav spacer
                const SizedBox(height: 68),
                // Ticker
                _buildTicker(),
                _divider(),
                // Hero
                isWide ? _buildHeroWide() : _buildHeroNarrow(),
                _divider(),
                // Trust bar
                _buildTrustBar(isWide),
                _divider(),
                // How it works
                _buildHowItWorks(isWide),
                _divider(),
                // Categories
                _buildCategories(isWide),
                _divider(),
                // Social proof
                _buildSocialProof(isWide),
                _divider(),
                // Roles
                _buildRoles(isWide),
                _divider(),
                // Bottom CTA
                _buildBottomCta(isWide),
                _divider(),
                // Terms
                _buildTermsRow(),
                _divider(),
                // Footer
                _buildFooter(isWide),
              ],
            ),
          ),
          // Fixed nav
          _buildNav(isWide),
        ],
      ),
    );
  }

  // ── NAV ──────────────────────────────────────────────────
  Widget _buildNav(bool isWide) => Positioned(
    top: 0, left: 0, right: 0,
    child: Container(
      height: 68,
      decoration: BoxDecoration(
        color: _bg.withAlpha(240),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 56 : 20),
        child: Row(
          children: [
            // Logo
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _sky.withAlpha(77)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/gearsh_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _bg2,
                  child: const Icon(Icons.music_note, color: _skyL, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('THE GEARSH',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                letterSpacing: 3, color: Colors.white,
                fontFamily: 'Syne',
              ),
            ),
            const Spacer(),
            if (isWide) ...[
              _navTextBtn('About'),
              _navTextBtn('Discover'),
              const SizedBox(width: 8),
            ],
            _navPill('Sign in', () => context.go('/login')),
          ],
        ),
      ),
    ),
  );

  Widget _navTextBtn(String label) => TextButton(
    onPressed: () {},
    child: Text(label,
      style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w300,
        color: _muted, letterSpacing: 0.2,
      ),
    ),
  );

  Widget _navPill(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const LinearGradient(
          colors: [_sky, _cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Text('Sign in',
        style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: Colors.white, letterSpacing: 0.3,
        ),
      ),
    ),
  );

  // ── TICKER ───────────────────────────────────────────────
  Widget _buildTicker() {
    const items = [
      'DJs', 'Photographers', 'Videographers', 'MCs',
      'Live Acts', 'Event Hosts', 'Music Producers',
      'Sound Engineers', 'Lighting Techs', 'Creative Directors',
    ];
    return Container(
      height: 40,
      color: _bg2,
      child: AnimatedBuilder(
        animation: _tickerCtrl,
        builder: (_, __) {
          return OverflowBox(
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(-_tickerCtrl.value * 1200, 0),
              child: Row(
                children: [
                  ...List.generate(3, (_) => Row(
                    children: items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✦ ', style: TextStyle(
                            color: _skyL.withAlpha(200), fontSize: 10,
                          )),
                          Text(item.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 11,
                              letterSpacing: 2,
                              color: Colors.white.withAlpha(90),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── HERO WIDE ────────────────────────────────────────────
  Widget _buildHeroWide() => SizedBox(
    height: MediaQuery.of(context).size.height - 68 - 40,
    child: Row(
      children: [
        Expanded(child: _buildHeroLeft()),
        Container(width: 1, color: _border),
        Expanded(child: _buildHeroRight()),
      ],
    ),
  );

  Widget _buildHeroNarrow() => Column(
    children: [
      _buildHeroLeft(),
      _divider(),
      SizedBox(height: 300, child: _buildHeroRight()),
    ],
  );

  Widget _buildHeroLeft() => FadeTransition(
    opacity: _fadeAnim,
    child: SlideTransition(
      position: _slideAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _sky.withAlpha(64)),
                color: _sky.withAlpha(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, __) => Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _skyL.withAlpha(
                          ((_floatCtrl.value * 200 + 55).toInt()).clamp(0, 255),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('STARTING IN SA · GOING GLOBAL',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w400,
                      color: _skyL, letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Headline
            const Text('Book creative',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 72, fontWeight: FontWeight.w800,
                letterSpacing: -1.5, height: 1.0,
                color: Colors.white,
              ),
            ),
            _gradientText('talent', 72, FontWeight.w800),
            _outlineText('instantly.', 72),
            const SizedBox(height: 28),
            // Body
            Text(
              'Connect with DJs, photographers, videographers\nand more. Verified artists, direct booking,\nzero middlemen.',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(115),
                height: 1.75,
              ),
            ),
            const SizedBox(height: 44),
            // CTAs
            Row(
              children: [
                _ctaPrimary('Get started', () => _showRoleSheet()),
                const SizedBox(width: 12),
                _ctaSecondary("I'm an artist", () {
                  _selectRole('artist');
                }),
              ],
            ),
            const SizedBox(height: 56),
            // Stats
            Container(
              padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  _stat('500+', 'Artists'),
                  Container(
                    width: 1, height: 40,
                    color: _border,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  _stat('24H', 'Booking'),
                  Container(
                    width: 1, height: 40,
                    color: _border,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  _stat('100%', 'Verified'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeroRight() => Stack(
    fit: StackFit.expand,
    children: [
      // Background image
      Image.asset(
        'assets/images/allthestars.jpg',
        fit: BoxFit.cover,
        color: Colors.black.withAlpha(143),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (_, __, ___) => Container(
          color: _bg2,
          child: Center(
            child: Icon(Icons.music_note_rounded,
              color: _sky.withAlpha(50), size: 80),
          ),
        ),
      ),
      // Gradient overlay
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _bg.withAlpha(153),
              Colors.transparent,
            ],
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              _bg.withAlpha(179),
              Colors.transparent,
            ],
            stops: const [0, 0.5],
          ),
        ),
      ),
      // Bottom content
      Positioned(
        bottom: 40, left: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -4 * _floatCtrl.value),
                child: child,
              ),
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _skyL.withAlpha(102), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _sky.withAlpha(77),
                      blurRadius: 24, spreadRadius: 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/gearsh_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _bg2,
                    child: const Icon(Icons.music_note, color: _skyL),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('THE GEARSH',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: Colors.white.withAlpha(100),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _sky.withAlpha(64)),
                color: _sky.withAlpha(25),
              ),
              child: const Text('✦  Book Creative Talent',
                style: TextStyle(
                  fontSize: 10, color: _skyL, letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // ── TRUST BAR ────────────────────────────────────────────
  Widget _buildTrustBar(bool isWide) => Container(
    color: _bg2,
    padding: EdgeInsets.symmetric(
      horizontal: isWide ? 56 : 20, vertical: 18,
    ),
    child: isWide
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _trustItems().expand((w) sync* {
              yield w;
              yield Container(width: 1, height: 20, color: _border);
            }).toList()..removeLast(),
          )
        : Wrap(
            spacing: 20, runSpacing: 14,
            children: _trustItems(),
          ),
  );

  List<Widget> _trustItems() => [
    _trustItem('✅', 'Every artist is verified'),
    _trustItem('⚡', 'Instant booking confirmation'),
    _trustItem('💬', 'Direct chat with artists'),
    _trustItem('🔒', 'Secure payments'),
    _trustItem('🌍', 'Starting in SA · Going Global'),
  ];

  Widget _trustItem(String icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 8),
      Text(text,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w300,
          color: Colors.white.withAlpha(128), letterSpacing: 0.3,
        ),
      ),
    ],
  );

  // ── HOW IT WORKS ─────────────────────────────────────────
  Widget _buildHowItWorks(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: isWide ? 56 : 20, vertical: 80,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('How it works'),
        const SizedBox(height: 12),
        _sectionTitle('Three steps to your\nperfect event.'),
        const SizedBox(height: 56),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _stepCard('01', 'assets/images/storyboard.png',
                    'Browse & discover',
                    'Search hundreds of verified DJs, photographers, videographers and more. Filter by category, location, price and availability.')),
                  const SizedBox(width: 24),
                  Expanded(child: _stepCard('02', 'assets/images/storyboard2.png',
                    'Book instantly',
                    'Select your date, choose your services and confirm in minutes. No back-and-forth — just instant confirmation.')),
                  const SizedBox(width: 24),
                  Expanded(child: _stepCard('03', 'assets/images/allthestars.jpg',
                    'Connect & create',
                    'Chat directly with your artist, share your vision and make sure every detail is perfect. Then let the talent do its thing.')),
                ],
              )
            : Column(
                children: [
                  _stepCard('01', 'assets/images/storyboard.png',
                    'Browse & discover',
                    'Search hundreds of verified DJs, photographers, videographers and more.'),
                  const SizedBox(height: 24),
                  _stepCard('02', 'assets/images/storyboard2.png',
                    'Book instantly',
                    'Confirm your booking in minutes. No back-and-forth.'),
                  const SizedBox(height: 24),
                  _stepCard('03', 'assets/images/allthestars.jpg',
                    'Connect & create',
                    'Chat directly with your artist and make sure every detail is perfect.'),
                ],
              ),
      ],
    ),
  );

  Widget _stepCard(String num, String imgPath, String title, String desc) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: 200, width: double.infinity,
                  child: Image.asset(
                    imgPath,
                    fit: BoxFit.cover,
                    color: Colors.black.withAlpha(51),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => Container(
                      color: _bg2,
                      child: Center(
                        child: Icon(Icons.image_outlined,
                          color: _sky.withAlpha(77), size: 40),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14, left: 14,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_sky, _cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(num,
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 17, fontWeight: FontWeight.w700,
              letterSpacing: -0.3, color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(desc,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w300,
              color: Colors.white.withAlpha(115), height: 1.65,
            ),
          ),
        ],
      );

  // ── CATEGORIES ───────────────────────────────────────────
  Widget _buildCategories(bool isWide) => Container(
    padding: EdgeInsets.only(
      left: isWide ? 56 : 20,
      right: isWide ? 56 : 20,
      bottom: 80,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        _sectionLabel('Browse by category'),
        const SizedBox(height: 12),
        _sectionTitle('Find exactly what\nyour event needs.'),
        const SizedBox(height: 48),
        isWide
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _catCard(
                          'assets/images/artists/rixelton.jpg',
                          'DJs',
                          'The heartbeat of every event',
                          height: 320,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _catCard(
                          'assets/images/artists/dripmaker.png',
                          'Photographers',
                          'Capture every moment',
                          height: 320,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _catCard(
                          'assets/images/storyboard.png',
                          'Videographers',
                          'Tell your story in motion',
                          height: 240,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _catCard(
                          'assets/images/allthestars.jpg',
                          'Live Acts & MCs',
                          'Command the room',
                          height: 240,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  _catCard('assets/images/artists/rixelton.jpg', 'DJs', 'The heartbeat of every event', height: 200),
                  const SizedBox(height: 12),
                  _catCard('assets/images/artists/dripmaker.png', 'Photographers', 'Capture every moment', height: 180),
                  const SizedBox(height: 12),
                  _catCard('assets/images/storyboard.png', 'Videographers', 'Tell your story in motion', height: 180),
                  const SizedBox(height: 12),
                  _catCard('assets/images/allthestars.jpg', 'Live Acts & MCs', 'Command the room', height: 180),
                ],
              ),
      ],
    ),
  );

  Widget _catCard(String img, String name, String sub, {required double height}) =>
      GestureDetector(
        onTap: () => context.go('/home'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(img, fit: BoxFit.cover,
                  color: Colors.black.withAlpha(128),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (_, __, ___) => Container(color: _bg2),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, _bg.withAlpha(230)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(51)),
                      color: Colors.black.withAlpha(51),
                    ),
                    child: Center(
                      child: Text('→',
                        style: TextStyle(
                          color: Colors.white.withAlpha(128), fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(sub,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w300,
                          color: Colors.white.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ── SOCIAL PROOF ─────────────────────────────────────────
  Widget _buildSocialProof(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: isWide ? 56 : 20, vertical: 80,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('What people say'),
        const SizedBox(height: 12),
        _sectionTitle('Trusted by clients\nand artists across SA.'),
        const SizedBox(height: 48),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _proofCard('TM', 'Thabo M.', 'Event Organiser · Johannesburg',
                    '"Found the perfect DJ for my corporate event in under 10 minutes. The booking process was seamless."')),
                  const SizedBox(width: 16),
                  Expanded(child: _proofCard('DS', 'DJ Siya', 'DJ · Artist on The Gearsh',
                    '"The Gearsh has completely changed how I get bookings. My calendar is fuller than ever — no middleman."')),
                  const SizedBox(width: 16),
                  Expanded(child: _proofCard('NL', 'Naledi L.', 'Client · Cape Town',
                    '"Booked a photographer and a DJ for my wedding. Both were incredible. Coordinating two artists was so easy."')),
                ],
              )
            : Column(
                children: [
                  _proofCard('TM', 'Thabo M.', 'Event Organiser · Johannesburg',
                    '"Found the perfect DJ for my corporate event in under 10 minutes."'),
                  const SizedBox(height: 14),
                  _proofCard('DS', 'DJ Siya', 'DJ · Artist on The Gearsh',
                    '"The Gearsh has completely changed how I get bookings. No middleman."'),
                  const SizedBox(height: 14),
                  _proofCard('NL', 'Naledi L.', 'Client · Cape Town',
                    '"Booked a photographer and DJ for my wedding. Both were incredible."'),
                ],
              ),
      ],
    ),
  );

  Widget _proofCard(String initials, String name, String role, String quote) =>
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (_) => const Text('★',
                style: TextStyle(color: _skyL, fontSize: 13, letterSpacing: 2),
              )),
            ),
            const SizedBox(height: 16),
            Text(quote,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(179),
                height: 1.7, fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_sky, _cyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(initials,
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(role,
                      style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w300,
                        color: _muted, letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  // ── ROLES ────────────────────────────────────────────────
  Widget _buildRoles(bool isWide) => Column(
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(isWide ? 56 : 20, 72, isWide ? 56 : 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _sectionTitle('How do you want\nto use Gearsh?'),
            ),
            if (isWide)
              Text('Choose your path and\nget started in seconds.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w300,
                  color: Colors.white.withAlpha(90), height: 1.6,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 44),
      _divider(),
      isWide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _roleCard('01', '🎪', "I'm a Client",
                    'Find and book talented artists for your events, parties, corporate functions and special occasions.',
                    'Start booking', () => _selectRole('client'))),
                  Container(width: 1, color: _border),
                  Expanded(child: _roleCard('02', '🎵', "I'm an Artist",
                    'Showcase your talent, manage your bookings and grow your creative business on SA\'s most powerful platform.',
                    'List your profile', () => _selectRole('artist'))),
                  Container(width: 1, color: _border),
                  Expanded(child: _roleCard('03', '❤️', "I'm a Fan",
                    'Follow your favourite artists, discover upcoming gigs, buy tickets and exclusive merch directly from creators.',
                    'Explore gigs', () => _selectRole('fan'))),
                ],
              ),
            )
          : Column(
              children: [
                _roleCard('01', '🎪', "I'm a Client",
                  'Find and book talented artists for your events and occasions.',
                  'Start booking', () => _selectRole('client')),
                _divider(),
                _roleCard('02', '🎵', "I'm an Artist",
                  'Showcase your talent and grow your creative business.',
                  'List your profile', () => _selectRole('artist')),
                _divider(),
                _roleCard('03', '❤️', "I'm a Fan",
                  'Follow artists, discover gigs and buy tickets.',
                  'Explore gigs', () => _selectRole('fan')),
              ],
            ),
      _divider(),
      // Sign in row
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 56 : 20, vertical: 20,
        ),
        child: Row(
          children: [
            Text('Already have an account? ',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(90),
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: const Text('Sign in',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: _skyL,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _roleCard(String idx, String icon, String name, String desc,
      String action, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$idx / 03',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 11, fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: Colors.white.withAlpha(46),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _sky.withAlpha(51)),
                  color: _sky.withAlpha(15),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 18),
              Text(name,
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 20, fontWeight: FontWeight.w700,
                  letterSpacing: -0.3, color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(desc,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w300,
                  color: Colors.white.withAlpha(115), height: 1.65,
                ),
              ),
              const SizedBox(height: 32),
              Text('$action →',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: _skyL, letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );

  // ── BOTTOM CTA ───────────────────────────────────────────
  Widget _buildBottomCta(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: isWide ? 56 : 20, vertical: 80,
    ),
    child: Center(
      child: Column(
        children: [
          const Text('Ready to book your',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 44, fontWeight: FontWeight.w800,
              letterSpacing: -1, height: 1.1, color: Colors.white,
            ),
          ),
          _gradientText('next event?', 44, FontWeight.w800),
          const SizedBox(height: 20),
          Text('Starting in South Africa — expanding worldwide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w300,
              color: Colors.white.withAlpha(115),
            ),
          ),
          const SizedBox(height: 40),
          _ctaPrimary('Get started for free', () => _showRoleSheet()),
        ],
      ),
    ),
  );

  // ── TERMS ROW ────────────────────────────────────────────
  Widget _buildTermsRow() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    child: Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w300,
            color: Colors.white.withAlpha(51),
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: const TextStyle(
                color: _skyL,
                decoration: TextDecoration.underline,
                decorationColor: _skyL,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go('/terms'),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: const TextStyle(
                color: _skyL,
                decoration: TextDecoration.underline,
                decorationColor: _skyL,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go('/privacy-policy'),
            ),
          ],
        ),
      ),
    ),
  );

  // ── FOOTER ───────────────────────────────────────────────
  Widget _buildFooter(bool isWide) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: isWide ? 56 : 20, vertical: 24,
    ),
    child: isWide
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('© 2026 The Gearsh. All rights reserved.',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w300,
                  color: Colors.white.withAlpha(46), letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  _footerLink('Privacy Policy', '/privacy-policy'),
                  const SizedBox(width: 24),
                  _footerLink('Terms of Service', '/terms'),
                ],
              ),
            ],
          )
        : Column(
            children: [
              Text('© 2026 The Gearsh. All rights reserved.',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w300,
                  color: Colors.white.withAlpha(46),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _footerLink('Privacy Policy', '/privacy-policy'),
                  const SizedBox(width: 24),
                  _footerLink('Terms of Service', '/terms'),
                ],
              ),
            ],
          ),
  );

  Widget _footerLink(String label, String route) => GestureDetector(
    onTap: () => context.go(route),
    child: Text(label,
      style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w300,
        color: Colors.white.withAlpha(64),
        letterSpacing: 0.5,
      ),
    ),
  );

  // ── SHARED BUTTONS ───────────────────────────────────────
  Widget _ctaPrimary(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const LinearGradient(
          colors: [_sky, _cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(label,
        style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: Colors.white, letterSpacing: 0.3,
        ),
      ),
    ),
  );

  Widget _ctaSecondary(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Text(label,
        style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w300,
          color: Colors.white, letterSpacing: 0.3,
        ),
      ),
    ),
  );

  Widget _stat(String num, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [_skyL, _cyanL],
        ).createShader(b),
        child: Text(num,
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 28, fontWeight: FontWeight.w700,
            color: Colors.white, letterSpacing: -0.5,
          ),
        ),
      ),
      Text(label.toUpperCase(),
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w300,
          color: Colors.white.withAlpha(77),
          letterSpacing: 2,
        ),
      ),
    ],
  );

  // ── ROLE BOTTOM SHEET ────────────────────────────────────
  void _showRoleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('How do you want to use Gearsh?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _sheetRoleBtn('🎪', "I'm a Client", 'Book artists for your events',
              () { Navigator.pop(context); _selectRole('client'); }),
            const SizedBox(height: 12),
            _sheetRoleBtn('🎵', "I'm an Artist", 'Showcase your talent & get booked',
              () { Navigator.pop(context); _selectRole('artist'); }),
            const SizedBox(height: 12),
            _sheetRoleBtn('❤️', "I'm a Fan", 'Discover artists & gigs',
              () { Navigator.pop(context); _selectRole('fan'); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetRoleBtn(String icon, String title, String sub, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            color: _bg.withAlpha(128),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(sub,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w300,
                        color: Colors.white.withAlpha(115),
                      ),
                    ),
                  ],
                ),
              ),
              Text('→',
                style: TextStyle(
                  color: _skyL.withAlpha(179), fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
}

