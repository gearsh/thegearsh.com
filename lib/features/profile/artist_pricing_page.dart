import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Artist pricing / join page.
/// URL: /join  or  /join?tier=standard  (to pre-select a tier)
///
/// Three tiers:
///   Basic     – R0/free
///   Standard  – R500/month
///   Premium   – R5 000/month
class ArtistPricingPage extends StatefulWidget {
  final String? preselectedTier;
  const ArtistPricingPage({super.key, this.preselectedTier});

  @override
  State<ArtistPricingPage> createState() => _ArtistPricingPageState();
}

class _ArtistPricingPageState extends State<ArtistPricingPage>
    with SingleTickerProviderStateMixin {

  // ── Palette ─────────────────────────────────────────────
  static const Color _bg      = Color(0xFF020617);
  static const Color _bg2     = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF111827);
  static const Color _sky     = Color(0xFF0EA5E9);
  static const Color _skyL    = Color(0xFF38BDF8);
  static const Color _cyan    = Color(0xFF06B6D4);
  static const Color _cyanL   = Color(0xFF22D3EE);
  static const Color _border  = Color(0x12FFFFFF);
  static const Color _gold    = Color(0xFFF59E0B);
  static const Color _goldL   = Color(0xFFFBBF24);

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final ScrollController _scrollCtrl = ScrollController();

  String _selectedTier = 'standard'; // default highlight

  @override
  void initState() {
    super.initState();
    if (widget.preselectedTier != null) {
      _selectedTier = widget.preselectedTier!;
    }
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _hPad(bool isWide) => isWide ? 80 : 24;

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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const SizedBox(height: 68), // nav spacer
                  _buildHero(isWide),
                  _buildPricingSection(isWide),
                  _buildFeatureComparison(isWide),
                  _buildFAQ(isWide),
                  _buildBottomCta(isWide),
                  _buildFooter(isWide),
                ],
              ),
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _hPad(isWide)),
        child: Row(
          children: [
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
            _clickable(
              child: const Text('Already a member? Sign in',
                style: TextStyle(fontSize: 13, color: _skyL, fontWeight: FontWeight.w500),
              ),
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    ),
  );

  // ── HERO ──────────────────────────────────────────────────
  Widget _buildHero(bool isWide) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide),
      vertical: isWide ? 80 : 56,
    ),
    child: Column(
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _sky.withAlpha(51)),
            color: _sky.withAlpha(13),
          ),
          child: const Text('FOR ARTISTS',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 2.5, color: _skyL,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Grow your career.\nGet booked.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: isWide ? 52 : 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1, height: 1.1, color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Join South Africa\'s fastest-growing creative marketplace. Choose the plan that fits your hustle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w300,
              color: Colors.white.withAlpha(128), height: 1.6,
            ),
          ),
        ),
      ],
    ),
  );

  // ── PRICING CARDS ─────────────────────────────────────────
  Widget _buildPricingSection(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 20,
    ),
    child: isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _tierCard(
                tier: 'basic',
                name: 'Basic',
                price: 'R0',
                period: 'Free forever',
                desc: 'Get discovered. Start receiving bookings.',
                features: [
                  'Profile listing on Gearsh',
                  'Up to 3 portfolio images',
                  'Booking requests via app',
                  'Basic search visibility',
                  'Community support',
                ],
                limitations: [
                  'Standard commission on bookings',
                  'No promoted placement',
                  'No analytics dashboard',
                ],
                cta: 'Start free',
                isPopular: false,
              )),
              const SizedBox(width: 16),
              Expanded(child: _tierCard(
                tier: 'standard',
                name: 'Standard',
                price: 'R500',
                period: '/month',
                desc: 'Stand out. Get more bookings. Grow faster.',
                features: [
                  'Everything in Basic, plus:',
                  'Up to 20 portfolio images',
                  'Priority in search results',
                  'Verified badge on profile',
                  'Booking analytics dashboard',
                  'Direct client messaging',
                  'Reduced commission rate',
                  'Email support',
                ],
                limitations: [],
                cta: 'Get Standard',
                isPopular: true,
              )),
              const SizedBox(width: 16),
              Expanded(child: _tierCard(
                tier: 'premium',
                name: 'Premium',
                price: 'R5 000',
                period: '/month',
                desc: 'Dominate your category. Maximum exposure.',
                features: [
                  'Everything in Standard, plus:',
                  'Unlimited portfolio media',
                  'Featured on homepage carousel',
                  'Top placement in all searches',
                  'Gold verified badge',
                  'Advanced analytics & insights',
                  'Priority customer support',
                  'Zero commission on bookings',
                  'Promotional social media posts',
                  'Dedicated account manager',
                ],
                limitations: [],
                cta: 'Go Premium',
                isPopular: false,
                isPremium: true,
              )),
            ],
          )
        : Column(
            children: [
              _tierCard(
                tier: 'standard',
                name: 'Standard',
                price: 'R500',
                period: '/month',
                desc: 'Stand out. Get more bookings. Grow faster.',
                features: [
                  'Everything in Basic, plus:',
                  'Up to 20 portfolio images',
                  'Priority in search results',
                  'Verified badge on profile',
                  'Booking analytics dashboard',
                  'Direct client messaging',
                  'Reduced commission rate',
                  'Email support',
                ],
                limitations: [],
                cta: 'Get Standard',
                isPopular: true,
              ),
              const SizedBox(height: 16),
              _tierCard(
                tier: 'basic',
                name: 'Basic',
                price: 'R0',
                period: 'Free forever',
                desc: 'Get discovered. Start receiving bookings.',
                features: [
                  'Profile listing on Gearsh',
                  'Up to 3 portfolio images',
                  'Booking requests via app',
                  'Basic search visibility',
                  'Community support',
                ],
                limitations: [
                  'Standard commission on bookings',
                  'No promoted placement',
                  'No analytics dashboard',
                ],
                cta: 'Start free',
                isPopular: false,
              ),
              const SizedBox(height: 16),
              _tierCard(
                tier: 'premium',
                name: 'Premium',
                price: 'R5 000',
                period: '/month',
                desc: 'Dominate your category. Maximum exposure.',
                features: [
                  'Everything in Standard, plus:',
                  'Unlimited portfolio media',
                  'Featured on homepage carousel',
                  'Top placement in all searches',
                  'Gold verified badge',
                  'Advanced analytics & insights',
                  'Priority customer support',
                  'Zero commission on bookings',
                  'Promotional social media posts',
                  'Dedicated account manager',
                ],
                limitations: [],
                cta: 'Go Premium',
                isPopular: false,
                isPremium: true,
              ),
            ],
          ),
  );

  Widget _tierCard({
    required String tier,
    required String name,
    required String price,
    required String period,
    required String desc,
    required List<String> features,
    required List<String> limitations,
    required String cta,
    required bool isPopular,
    bool isPremium = false,
  }) {
    final isSelected = _selectedTier == tier;
    final Color accent = isPremium ? _gold : _sky;
    final Color accentL = isPremium ? _goldL : _skyL;

    return _clickable(
      onTap: () => setState(() => _selectedTier = tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isSelected ? _surface : _bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent.withAlpha(128) : _border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accent.withAlpha(20), blurRadius: 32, spreadRadius: 0)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(name,
                  style: TextStyle(
                    fontFamily: 'Syne', fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_sky, _cyan]),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text('POPULAR',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 1.5,
                      ),
                    ),
                  ),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_gold, _goldL]),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text('PRO',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.black, letterSpacing: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [accentL, accent],
                  ).createShader(b),
                  child: Text(price,
                    style: const TextStyle(
                      fontFamily: 'Syne', fontSize: 40,
                      fontWeight: FontWeight.w800, color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(period,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(90),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(desc,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(115), height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // CTA button
            _clickable(
              onTap: () => context.go('/signup?role=artist&tier=$tier'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isSelected
                      ? LinearGradient(colors: isPremium ? [_gold, _goldL] : [_sky, _cyan])
                      : null,
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white.withAlpha(38)),
                  color: isSelected ? null : Colors.transparent,
                ),
                child: Text(cta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected && isPremium ? Colors.black : Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Divider
            Container(height: 1, color: _border),
            const SizedBox(height: 20),
            // Features
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 16, color: accentL),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w400,
                        color: Colors.white.withAlpha(190), height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            // Limitations
            ...limitations.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.remove, size: 16,
                    color: Colors.white.withAlpha(40)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w300,
                        color: Colors.white.withAlpha(64), height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ── FEATURE COMPARISON ────────────────────────────────────
  Widget _buildFeatureComparison(bool isWide) {
    if (!isWide) return const SizedBox.shrink(); // skip on mobile

    final features = [
      ['Profile listing',           '✓', '✓', '✓'],
      ['Portfolio images',          '3', '20', '∞'],
      ['Search visibility',         'Basic', 'Priority', 'Top'],
      ['Verified badge',            '—', '✓', 'Gold ✓'],
      ['Analytics dashboard',       '—', '✓', 'Advanced'],
      ['Direct messaging',          '—', '✓', '✓'],
      ['Commission rate',           '15%', '8%', '0%'],
      ['Homepage feature',          '—', '—', '✓'],
      ['Social media promotion',    '—', '—', '✓'],
      ['Dedicated account manager', '—', '—', '✓'],
      ['Support',                   'Community', 'Email', 'Priority'],
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: _hPad(isWide), vertical: 80),
      child: Column(
        children: [
          const Text('Compare plans',
            style: TextStyle(
              fontFamily: 'Syne', fontSize: 28,
              fontWeight: FontWeight.w700, color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              color: _surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: _bg2,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Feature',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(128), letterSpacing: 1,
                        ),
                      )),
                      Expanded(flex: 2, child: Text('Basic',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(128),
                        ),
                      )),
                      Expanded(flex: 2, child: Text('Standard',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _skyL,
                        ),
                      )),
                      Expanded(flex: 2, child: Text('Premium',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _goldL,
                        ),
                      )),
                    ],
                  ),
                ),
                // Rows
                ...features.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: i.isEven ? Colors.transparent : _bg2.withAlpha(80),
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(row[0],
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w400,
                            color: Colors.white.withAlpha(190),
                          ),
                        )),
                        Expanded(flex: 2, child: Text(row[1],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: row[1] == '—'
                                ? Colors.white.withAlpha(40)
                                : Colors.white.withAlpha(160),
                          ),
                        )),
                        Expanded(flex: 2, child: Text(row[2],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: Colors.white.withAlpha(200),
                          ),
                        )),
                        Expanded(flex: 2, child: Text(row[3],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: row[3] == '—'
                                ? Colors.white.withAlpha(40)
                                : _goldL,
                          ),
                        )),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAQ ───────────────────────────────────────────────────
  Widget _buildFAQ(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 80,
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        children: [
          const Text('Frequently asked questions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Syne', fontSize: 28,
              fontWeight: FontWeight.w700, color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _faqItem(
            'Can I upgrade or downgrade anytime?',
            'Yes. Change your plan anytime from your dashboard. Upgrades take effect immediately, and downgrades apply at the end of your billing cycle.',
          ),
          _faqItem(
            'How does the commission work?',
            'Basic artists pay 15% per completed booking. Standard pays 8%. Premium artists keep 100% of their booking fee — zero commission.',
          ),
          _faqItem(
            'What payment methods do you accept?',
            'We accept all major South African bank cards, EFT, and mobile payment methods through our secure payment partner.',
          ),
          _faqItem(
            'Do I need to be in South Africa?',
            'We\'re launching in South Africa first but expanding globally. Artists from any country can sign up — you\'ll be featured as we roll out in your region.',
          ),
          _faqItem(
            'Can I cancel my subscription?',
            'Cancel anytime with no penalties. Your profile stays active on the Basic (free) tier after cancellation.',
          ),
        ],
      ),
    ),
  );

  Widget _faqItem(String question, String answer) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
      color: _surface,
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      iconColor: _skyL,
      collapsedIconColor: Colors.white.withAlpha(64),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(question,
        style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      children: [
        Text(answer,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w300,
            color: Colors.white.withAlpha(140), height: 1.6,
          ),
        ),
      ],
    ),
  );

  // ── BOTTOM CTA ────────────────────────────────────────────
  Widget _buildBottomCta(bool isWide) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 80,
    ),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: _border),
        bottom: BorderSide(color: _border),
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_skyL, _cyanL],
              ).createShader(b),
              child: Text('Start getting booked today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: isWide ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Join hundreds of artists already growing their careers on The Gearsh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(115), height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12, runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _clickable(
                  onTap: () => context.go('/signup?role=artist&tier=standard'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: const LinearGradient(colors: [_sky, _cyan]),
                      boxShadow: [
                        BoxShadow(color: _sky.withAlpha(40), blurRadius: 16,
                          offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Text('Join as Standard — R500/mo',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _clickable(
                  onTap: () => context.go('/signup?role=artist&tier=basic'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withAlpha(38)),
                    ),
                    child: const Text('Start free',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // ── FOOTER ────────────────────────────────────────────────
  Widget _buildFooter(bool isWide) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: _hPad(isWide), vertical: 24,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('© 2026 The Gearsh. All rights reserved.',
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w300,
            color: Colors.white.withAlpha(46),
          ),
        ),
        if (isWide) Row(
          children: [
            _clickable(
              onTap: () => context.go('/privacy-policy'),
              child: Text('Privacy', style: TextStyle(
                fontSize: 11, color: Colors.white.withAlpha(64),
              )),
            ),
            const SizedBox(width: 20),
            _clickable(
              onTap: () => context.go('/terms'),
              child: Text('Terms', style: TextStyle(
                fontSize: 11, color: Colors.white.withAlpha(64),
              )),
            ),
          ],
        ),
      ],
    ),
  );

  // ── CLICKABLE HELPER ──────────────────────────────────────
  Widget _clickable({required Widget child, VoidCallback? onTap}) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: child),
      );
}
