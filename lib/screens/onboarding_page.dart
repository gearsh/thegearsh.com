import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {

  // ── Palette ─────────────────────────────────────────────
  static const Color _bg      = Color(0xFF020617);
  static const Color _bg2     = Color(0xFF0F172A);
  static const Color _sky     = Color(0xFF0EA5E9);
  static const Color _skyL    = Color(0xFF38BDF8);
  static const Color _cyan    = Color(0xFF06B6D4);
  static const Color _cyanL   = Color(0xFF22D3EE);
  static const Color _border  = Color(0x12FFFFFF);
  static const Color _muted   = Color(0x73FFFFFF);
  static const Color _surface = Color(0xFF111827);

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
      vsync: this, duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04), end: Offset.zero,
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

  // ── Layout helpers ────────────────────────────────────────
  double _hPad(bool isWide) => isWide ? 80 : 24;

  Widget _divider() => Container(
    width: double.infinity, height: 1, color: _border,
  );

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      letterSpacing: 2.5, color: _skyL,
    ),
  );

  Widget _sectionTitle(String text, {double size = 32}) => Text(
    text,
    style: TextStyle(
      fontSize: size, fontWeight: FontWeight.w800,
      letterSpacing: -0.5, height: 1.15,
      color: Colors.white, fontFamily: 'Syne',
    ),
  );

  Widget _gradientText(String text, double size, FontWeight w) =>
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [_skyL, _cyanL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(b),
        child: Text(text,
          style: TextStyle(
            color: Colors.white, fontSize: size,
            fontWeight: w, letterSpacing: -0.5,
            fontFamily: 'Syne', height: 1.05,
          ),
        ),
      );

  Widget _outlineText(String text, double size) => Text(
    text,
    style: TextStyle(
      fontSize: size, fontWeight: FontWeight.w800,
      letterSpacing: -0.5, fontFamily: 'Syne',
      height: 1.05,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _skyL.withAlpha(77),
    ),
  );

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(
              children: [
                const SizedBox(height: 68), // nav spacer
                _buildTicker(),
                _divider(),
                isWide ? _buildHeroWide() : _buildHeroNarrow(),
                _divider(),
                _buildTrustBar(isWide),
                _divider(),
                _buildHowItWorks(isWide),
                _divider(),
                _buildCategories(isWide),
                _divider(),
                _buildSocialProof(isWide),
                _divider(),
                _buildRoles(isWide),
                _divider(),
                _buildBottomCta(isWide),
                _divider(),
                _buildTermsRow(),
                _buildFooter(isWide),
              ],
            ),
          ),
          _buildNav(isWide),
        ],
      ),
    );
  }

  // ── NAV ───────────────────────────────────────────────────
  Widget _buildNav(bool isWide) => Positioned(
    top: 0, left: 0, right: 0,
    child: Container(
      height: 68,
      decoration: BoxDecoration(
        color: _bg.withAlpha(245),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: ClipRect(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _hPad(isWide)),
          child: Row(
            children: [
              // Logo
              Container(
                width: 36, height: 36,
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
                  fontSize: 14, fontWeight: FontWeight.w700,
                  letterSpacing: 3, color: Colors.white, fontFamily: 'Syne',
                ),
              ),
              const Spacer(),
              if (isWide) ...[
                _navTextBtn('For Artists', () => context.go('/join')),
                _navTextBtn('Terms', () => context.go('/terms')),
                _navTextBtn('Privacy', () => context.go('/privacy-policy')),
                const SizedBox(width: 12),
              ],
              _navPill('Sign in', () => context.go('/login')),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _navTextBtn(String label, VoidCallback onTap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: TextButton(
      onPressed: onTap,
      child: Text(label,
        style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: _muted, letterSpacing: 0.2,
        ),
      ),
    ),
  );

  Widget _navPill(String label, VoidCallback onTap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
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
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Colors.white, letterSpacing: 0.3,
          ),
        ),
      ),
    ),
  );

  // ── TICKER ────────────────────────────────────────────────
  Widget _buildTicker() {
    const items = [
      'DJs', 'Photographers', 'Videographers', 'MCs',
      'Live Acts', 'Event Hosts', 'Music Producers',
      'Sound Engineers', 'Lighting Techs', 'Creative Directors',
    ];
    return ClipRect(
      child: Container(
        height: 40,
        color: _bg2,
        child: AnimatedBuilder(
          animation: _tickerCtrl,
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(-_tickerCtrl.value * 1200, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(3, (_) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✦ ', style: TextStyle(
                            color: _skyL.withAlpha(180), fontSize: 9,
                          )),
                          Text(item.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Syne', fontSize: 10,
                              letterSpacing: 2.5, fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(80),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── HERO — WIDE ───────────────────────────────────────────
  Widget _buildHeroWide() {
    final screenH = MediaQuery.of(context).size.height;
    return SizedBox(
      height: (screenH - 108).clamp(500.0, 800.0),
      child: Row(
        children: [
          Expanded(child: _buildHeroContent(isWide: true)),
          Container(width: 1, color: _border),
          Expanded(child: _buildHeroImage()),
        ],
      ),
    );
  }

  // ── HERO — NARROW ─────────────────────────────────────────
  Widget _buildHeroNarrow() => Column(
    children: [
      _buildHeroContent(isWide: false),
      _divider(),
      SizedBox(
        height: 280,
        width: double.infinity,
        child: _buildHeroImage(),
      ),
    ],
  );

  // ── HERO CONTENT (left / top) ─────────────────────────────
  Widget _buildHeroContent({required bool isWide}) {
    final headlineSize = isWide ? 64.0 : 44.0;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _hPad(isWide),
            vertical: isWide ? 0 : 48,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Tag pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _sky.withAlpha(51)),
                  color: _sky.withAlpha(13),
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
                        fontSize: 10, fontWeight: FontWeight.w500,
                        color: _skyL, letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Headline
              Text('Book creative',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: headlineSize, fontWeight: FontWeight.w800,
                  letterSpacing: -1.5, height: 1.05, color: Colors.white,
                ),
              ),
              _gradientText('talent', headlineSize, FontWeight.w800),
              _outlineText('instantly.', headlineSize),
              const SizedBox(height: 24),
              // Body
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'Connect with DJs, photographers, videographers and more. Verified artists, direct booking, zero middlemen.',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w300,
                    color: Colors.white.withAlpha(128), height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // CTAs
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ctaPrimary('Get started', () => _showRoleSheet()),
                  _ctaSecondary("I'm an artist", () => context.go('/join')),
                ],
              ),
              const SizedBox(height: 48),
              // Stats
              Container(
                padding: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _border)),
                ),
                child: Row(
                  children: [
                    _stat('500+', 'Artists'),
                    _statDivider(),
                    _stat('24H', 'Booking'),
                    _statDivider(),
                    _stat('100%', 'Verified'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider() => Container(
    width: 1, height: 36,
    color: _border,
    margin: const EdgeInsets.symmetric(horizontal: 20),
  );

  // ── HERO IMAGE (right / bottom) ───────────────────────────
  Widget _buildHeroImage() => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/images/allthestars.jpg',
        fit: BoxFit.cover,
        color: Colors.black.withAlpha(100),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (_, __, ___) => Container(
          color: _bg2,
          child: Center(child: Icon(Icons.music_note_rounded,
            color: _sky.withAlpha(40), size: 64)),
        ),
      ),
      // Gradient overlays
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_bg.withAlpha(180), Colors.transparent],
            stops: const [0, 0.4],
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [_bg.withAlpha(200), Colors.transparent],
            stops: const [0, 0.4],
          ),
        ),
      ),
      // Floating logo badge
      Positioned(
        bottom: 32, left: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -3 * _floatCtrl.value),
                child: child,
              ),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _skyL.withAlpha(90), width: 2),
                  boxShadow: [
                    BoxShadow(color: _sky.withAlpha(60), blurRadius: 20),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _sky.withAlpha(51)),
                color: _bg.withAlpha(180),
              ),
              child: const Text('✦  Book Creative Talent',
                style: TextStyle(fontSize: 10, color: _skyL, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // ── TRUST BAR ─────────────────────────────────────────────
  Widget _buildTrustBar(bool isWide) => Container(
    color: _bg2,
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 16,
    ),
    child: isWide
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _trustItems().expand((w) sync* {
              yield w;
              yield Container(width: 1, height: 18, color: _border);
            }).toList()..removeLast(),
          )
        : Wrap(
            spacing: 16, runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _trustItems(),
          ),
  );

  List<Widget> _trustItems() => [
    _trustItem(Icons.verified_outlined, 'Verified artists'),
    _trustItem(Icons.bolt_outlined, 'Instant confirmation'),
    _trustItem(Icons.chat_bubble_outline, 'Direct chat'),
    _trustItem(Icons.lock_outline, 'Secure payments'),
    _trustItem(Icons.public_outlined, 'SA to global'),
  ];

  Widget _trustItem(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: _skyL.withAlpha(180)),
      const SizedBox(width: 8),
      Text(text,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: Colors.white.withAlpha(115), letterSpacing: 0.2,
        ),
      ),
    ],
  );

  // ── HOW IT WORKS ──────────────────────────────────────────
  Widget _buildHowItWorks(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 80,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('How it works'),
        const SizedBox(height: 12),
        _sectionTitle('Three steps to your\nperfect event.'),
        const SizedBox(height: 48),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _stepCard('01', 'assets/images/storyboard.png',
                    'Browse & discover',
                    'Search hundreds of verified DJs, photographers, videographers and more. Filter by category, location, price and availability.')),
                  const SizedBox(width: 20),
                  Expanded(child: _stepCard('02', 'assets/images/storyboard2.png',
                    'Book instantly',
                    'Select your date, choose your services and confirm in minutes. No back-and-forth — just instant confirmation.')),
                  const SizedBox(width: 20),
                  Expanded(child: _stepCard('03', 'assets/images/allthestars.jpg',
                    'Connect & create',
                    'Chat directly with your artist, share your vision and make sure every detail is perfect.')),
                ],
              )
            : Column(
                children: [
                  _stepCard('01', 'assets/images/storyboard.png',
                    'Browse & discover',
                    'Search hundreds of verified DJs, photographers, videographers and more.'),
                  const SizedBox(height: 20),
                  _stepCard('02', 'assets/images/storyboard2.png',
                    'Book instantly',
                    'Confirm your booking in minutes. No back-and-forth.'),
                  const SizedBox(height: 20),
                  _stepCard('03', 'assets/images/allthestars.jpg',
                    'Connect & create',
                    'Chat directly with your artist and make sure every detail is perfect.'),
                ],
              ),
      ],
    ),
  );

  Widget _stepCard(String num, String imgPath, String title, String desc) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          color: _surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imgPath,
                    fit: BoxFit.cover,
                    color: Colors.black.withAlpha(64),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => Container(
                      color: _bg2,
                      child: Center(child: Icon(Icons.image_outlined,
                        color: _sky.withAlpha(60), size: 36)),
                    ),
                  ),
                  Positioned(
                    top: 14, left: 14,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_sky, _cyan],
                        ),
                      ),
                      child: Center(
                        child: Text(num,
                          style: const TextStyle(
                            fontFamily: 'Syne', fontSize: 12,
                            fontWeight: FontWeight.w700, color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(
                      fontFamily: 'Syne', fontSize: 16,
                      fontWeight: FontWeight.w700, color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(desc,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(110), height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── CATEGORIES ────────────────────────────────────────────
  Widget _buildCategories(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 80,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Browse by category'),
        const SizedBox(height: 12),
        _sectionTitle('Find exactly what\nyour event needs.'),
        const SizedBox(height: 48),
        isWide
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: _catCard(
                        'assets/images/artists/rixelton.jpg', 'DJs',
                        'The heartbeat of every event', height: 300,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _catCard(
                        'assets/images/artists/dripmaker.png', 'Photographers',
                        'Capture every moment', height: 300,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _catCard(
                        'assets/images/storyboard.png', 'Videographers',
                        'Tell your story in motion', height: 220,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _catCard(
                        'assets/images/allthestars.jpg', 'Live Acts & MCs',
                        'Command the room', height: 220,
                      )),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  _catCard('assets/images/artists/rixelton.jpg', 'DJs',
                    'The heartbeat of every event', height: 200),
                  const SizedBox(height: 12),
                  _catCard('assets/images/artists/dripmaker.png', 'Photographers',
                    'Capture every moment', height: 180),
                  const SizedBox(height: 12),
                  _catCard('assets/images/storyboard.png', 'Videographers',
                    'Tell your story in motion', height: 180),
                  const SizedBox(height: 12),
                  _catCard('assets/images/allthestars.jpg', 'Live Acts & MCs',
                    'Command the room', height: 180),
                ],
              ),
      ],
    ),
  );

  Widget _catCard(String img, String name, String sub, {required double height}) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(img, fit: BoxFit.cover,
                color: Colors.black.withAlpha(100),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => Container(color: _bg2),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _bg.withAlpha(220)],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 16, right: 16,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(40)),
                    color: Colors.black.withAlpha(60),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_outward, size: 15,
                      color: Colors.white70),
                  ),
                ),
              ),
              Positioned(
                bottom: 20, left: 20, right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: const TextStyle(
                        fontFamily: 'Syne', fontSize: 20,
                        fontWeight: FontWeight.w700, color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(sub,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w300,
                        color: Colors.white.withAlpha(140),
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

  // ── SOCIAL PROOF ──────────────────────────────────────────
  Widget _buildSocialProof(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 80,
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
                    'Found the perfect DJ for my corporate event in under 10 minutes. The booking process was seamless.')),
                  const SizedBox(width: 16),
                  Expanded(child: _proofCard('DS', 'DJ Siya', 'DJ · Artist on The Gearsh',
                    'The Gearsh has completely changed how I get bookings. My calendar is fuller than ever — no middleman.')),
                  const SizedBox(width: 16),
                  Expanded(child: _proofCard('NL', 'Naledi L.', 'Client · Cape Town',
                    'Booked a photographer and a DJ for my wedding. Both were incredible. So easy to coordinate.')),
                ],
              )
            : Column(
                children: [
                  _proofCard('TM', 'Thabo M.', 'Event Organiser · Johannesburg',
                    'Found the perfect DJ for my corporate event in under 10 minutes.'),
                  const SizedBox(height: 14),
                  _proofCard('DS', 'DJ Siya', 'DJ · Artist on The Gearsh',
                    'The Gearsh has completely changed how I get bookings. No middleman.'),
                  const SizedBox(height: 14),
                  _proofCard('NL', 'Naledi L.', 'Client · Cape Town',
                    'Booked a photographer and DJ for my wedding. Both were incredible.'),
                ],
              ),
      ],
    ),
  );

  Widget _proofCard(String initials, String name, String role, String quote) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.star_rounded, size: 14, color: _skyL),
              )),
            ),
            const SizedBox(height: 16),
            Text('"$quote"',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(190), height: 1.7,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: _border),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_sky, _cyan],
                    ),
                  ),
                  child: Center(
                    child: Text(initials,
                      style: const TextStyle(
                        fontFamily: 'Syne', fontSize: 12,
                        fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                          color: _muted, letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ── ROLES ─────────────────────────────────────────────────
  Widget _buildRoles(bool isWide) => Column(
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(_hPad(isWide), 72, _hPad(isWide), 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _sectionTitle('How do you want\nto use Gearsh?'),
            ),
            if (isWide)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text('Choose your path and\nget started in seconds.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w300,
                    color: Colors.white.withAlpha(90), height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 40),
      _divider(),
      isWide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _roleCard('01', Icons.celebration_outlined,
                    "I'm a Client",
                    'Find and book talented artists for your events, parties, corporate functions and special occasions.',
                    'Start booking', () => _selectRole('client'))),
                  Container(width: 1, color: _border),
                  Expanded(child: _roleCard('02', Icons.music_note_outlined,
                    "I'm an Artist",
                    'Showcase your talent, manage bookings and grow your creative business on SA\'s most powerful platform.',
                    'List your profile', () => context.go('/join'))),
                  Container(width: 1, color: _border),
                  Expanded(child: _roleCard('03', Icons.favorite_outline,
                    "I'm a Fan",
                    'Follow your favourite artists, discover upcoming gigs, buy tickets and exclusive merch.',
                    'Explore gigs', () => _selectRole('fan'))),
                ],
              ),
            )
          : Column(
              children: [
                _roleCard('01', Icons.celebration_outlined, "I'm a Client",
                  'Find and book artists for your events and occasions.',
                  'Start booking', () => _selectRole('client')),
                _divider(),
                _roleCard('02', Icons.music_note_outlined, "I'm an Artist",
                  'Showcase your talent and grow your creative business.',
                  'List your profile', () => context.go('/join')),
                _divider(),
                _roleCard('03', Icons.favorite_outline, "I'm a Fan",
                  'Follow artists, discover gigs and buy tickets.',
                  'Explore gigs', () => _selectRole('fan')),
              ],
            ),
      _divider(),
      // Sign in row
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _hPad(isWide), vertical: 20,
        ),
        child: Row(
          children: [
            Text('Already have an account? ',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(90),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text('Sign in',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _skyL,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _roleCard(String idx, IconData icon, String name, String desc,
      String action, VoidCallback onTap) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _sky.withAlpha(51)),
                      color: _sky.withAlpha(13),
                    ),
                    child: Center(
                      child: Icon(icon, color: _skyL, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Text('$idx / 03',
                    style: TextStyle(
                      fontFamily: 'Syne', fontSize: 11,
                      fontWeight: FontWeight.w500, letterSpacing: 2,
                      color: Colors.white.withAlpha(40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(name,
                style: const TextStyle(
                  fontFamily: 'Syne', fontSize: 19,
                  fontWeight: FontWeight.w700, color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(desc,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w300,
                  color: Colors.white.withAlpha(115), height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text('$action  ', style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _skyL, letterSpacing: 0.2,
                  )),
                  const Icon(Icons.arrow_forward, size: 14, color: _skyL),
                ],
              ),
            ],
          ),
        ),
        ),
      );

  // ── BOTTOM CTA ────────────────────────────────────────────
  Widget _buildBottomCta(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 80,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Text('Ready to book your',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: isWide ? 44 : 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1, height: 1.1, color: Colors.white,
              ),
            ),
            _gradientText('next event?', isWide ? 44 : 32, FontWeight.w800),
            const SizedBox(height: 20),
            Text('Starting in South Africa — expanding worldwide.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(115),
              ),
            ),
            const SizedBox(height: 36),
            _ctaPrimary('Get started for free', () => _showRoleSheet()),
          ],
        ),
      ),
    ),
  );

  // ── TERMS ROW ─────────────────────────────────────────────
  Widget _buildTermsRow() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text('By continuing, you agree to our ',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w300,
              color: Colors.white.withAlpha(51),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/terms'),
              child: const Text('Terms of Service',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w300,
                  color: _skyL,
                  decoration: TextDecoration.underline,
                  decorationColor: _skyL,
                ),
              ),
            ),
          ),
          Text(' and ',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w300,
              color: Colors.white.withAlpha(51),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/privacy-policy'),
              child: const Text('Privacy Policy',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w300,
                  color: _skyL,
                  decoration: TextDecoration.underline,
                  decorationColor: _skyL,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ── FOOTER ────────────────────────────────────────────────
  Widget _buildFooter(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 24,
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

  Widget _footerLink(String label, String route) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => context.go(route),
      child: Text(label,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w300,
          color: Colors.white.withAlpha(64), letterSpacing: 0.5,
        ),
      ),
    ),
  );

  // ── SHARED BUTTONS ────────────────────────────────────────
  Widget _ctaPrimary(String label, VoidCallback onTap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
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
          boxShadow: [
            BoxShadow(color: _sky.withAlpha(40), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(label,
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: Colors.white, letterSpacing: 0.3,
          ),
        ),
      ),
    ),
  );

  Widget _ctaSecondary(String label, VoidCallback onTap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withAlpha(38)),
        ),
        child: Text(label,
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400,
            color: Colors.white, letterSpacing: 0.3,
          ),
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
            fontFamily: 'Syne', fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white, letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(label.toUpperCase(),
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w400,
          color: Colors.white.withAlpha(70), letterSpacing: 2,
        ),
      ),
    ],
  );

  // ── ROLE BOTTOM SHEET ─────────────────────────────────────
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
                fontFamily: 'Syne', fontSize: 18,
                fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _sheetRoleBtn(Icons.celebration_outlined, "I'm a Client",
              'Book artists for your events',
              () { Navigator.pop(context); _selectRole('client'); }),
            const SizedBox(height: 10),
            _sheetRoleBtn(Icons.music_note_outlined, "I'm an Artist",
              'Showcase your talent & get booked',
              () { Navigator.pop(context); context.go('/join'); }),
            const SizedBox(height: 10),
            _sheetRoleBtn(Icons.favorite_outline, "I'm a Fan",
              'Discover artists & gigs',
              () { Navigator.pop(context); _selectRole('fan'); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetRoleBtn(IconData icon, String title, String sub, VoidCallback onTap) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
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
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _sky.withAlpha(15),
                    border: Border.all(color: _sky.withAlpha(40)),
                  ),
                  child: Center(child: Icon(icon, color: _skyL, size: 20)),
                ),
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
                Icon(Icons.arrow_forward_ios, size: 14,
                  color: _skyL.withAlpha(150)),
              ],
            ),
          ),
        ),
      );
}
