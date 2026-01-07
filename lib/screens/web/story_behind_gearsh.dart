import 'package:flutter/material.dart';

class StoryBehindGearshPage extends StatefulWidget {
  const StoryBehindGearshPage({super.key});

  @override
  State<StoryBehindGearshPage> createState() => _StoryBehindGearshPageState();
}

class _StoryBehindGearshPageState extends State<StoryBehindGearshPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _showBackToTop = false;

  // Theme colors
  static const Color _darkBg = Color(0xFF0A0A0A);
  static const Color _cardBg = Color(0xFF141418);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _purple500 = Color(0xFF8B5CF6);
  static const Color _amber500 = Color(0xFFF59E0B);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _showBackToTop = _scrollOffset > 400;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // Parallax background
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, _scrollOffset * 0.3),
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/allthestars.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _darkBg.withAlpha(200),
                    _darkBg.withAlpha(240),
                    _darkBg,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: _buildAppBar(isMobile),
                ),

                // Hero Section
                SliverToBoxAdapter(
                  child: _buildHeroSection(isMobile),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: 40,
                      ),
                      child: Column(
                        children: [
                          _buildAnimatedSection(
                            delay: 0,
                            child: _buildStoryCard(
                              icon: Icons.lightbulb_rounded,
                              iconColor: _amber500,
                              title: 'From DJ Dreams to a New Idea',
                              imagePath: 'assets/images/blackcoffee.png',
                              imageCaption: 'Black Coffee at Hï Ibiza – a DJ performing on professional gear, the kind of setup that sparked the idea for Gearsh.',
                              content: '''The story of Gearsh begins with a personal passion and a challenge. Our founder aspired to be a DJ, but professional DJ equipment – the turntables, mixers, speakers, and more – was prohibitively expensive for a student.

As a computer science student with an entrepreneurial spirit, he looked at this problem and saw an opportunity: what if there were a way to share gear? Musicians and creators often have equipment that sits unused, while others need that gear temporarily.

This gap sparked an idea – a community-driven gear-sharing platform where people could hire or share equipment instead of everyone needing to buy their own.''',
                            ),
                          ),

                          const SizedBox(height: 32),

                          _buildAnimatedSection(
                            delay: 100,
                            child: _buildStoryCard(
                              icon: Icons.share_rounded,
                              iconColor: _sky500,
                              title: 'Inspired by the Sharing Economy',
                              content: '''The mid-2010s were a time when "Uber for X" became a buzzworthy concept. Uber's success in ride-sharing proved that peer-to-peer sharing models could revolutionise industries.

Our founder asked: "What if there was an Uber, but for gear?" Armed with his tech background, he set out to build a peer-to-peer gear-sharing platform – making it as easy to borrow a guitar or a DJ mixer as it is to catch a ride across town.

Just as homeowners share rooms on Airbnb or drivers share rides via Uber, why not let people share their musical or creative gear? It was a win-win: owners could earn money from idle equipment, and borrowers could access expensive gear affordably.''',
                            ),
                          ),

                          const SizedBox(height: 32),

                          _buildAnimatedSection(
                            delay: 200,
                            child: _buildNameOriginCard(),
                          ),

                          const SizedBox(height: 32),

                          _buildAnimatedSection(
                            delay: 300,
                            child: _buildStoryCard(
                              icon: Icons.rocket_launch_rounded,
                              iconColor: _purple500,
                              title: 'What "Gearsh" Means Today',
                              content: '''Although Gearsh's origin lies in gear-sharing, the platform has grown and evolved since its founding in 2016. Today, Gearsh is the ultimate artist e-booking service – a digital marketplace that connects musicians, dancers, actors, photographers, and other artists with those who want to book them.

At its heart, Gearsh has always been about connecting people with the resources and opportunities they need. Whether that resource was a DJ rig or a live gig, Gearsh stands for accessibility and community in the creative space.

"Gearsh" means innovation born from necessity. It's a name that reminds us of our founding story – a student with a dream, an unmet need, and a clever solution. It represents the idea that with creativity, we can bridge gaps and empower individuals through a seamless, modern platform.''',
                            ),
                          ),

                          const SizedBox(height: 32),

                          _buildAnimatedSection(
                            delay: 400,
                            child: _buildClosingCard(),
                          ),

                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                SliverToBoxAdapter(
                  child: _buildFooter(isMobile),
                ),
              ],
            ),
          ),

          // Back to top button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            right: 24,
            bottom: _showBackToTop ? 24 : -60,
            child: _buildBackToTopButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Image.asset('assets/images/gearsh_logo.png', height: 40),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_sky500, _cyan500],
                    ).createShader(bounds),
                    child: const Text(
                      'Gearsh',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation
          if (!isMobile)
            Row(
              children: [
                _buildNavButton('About', () => Navigator.pushNamed(context, '/about')),
                const SizedBox(width: 8),
                _buildNavButton('Artists', () => Navigator.pushNamed(context, '/artists')),
                const SizedBox(width: 16),
                _buildSignUpButton(),
              ],
            )
          else
            _buildSignUpButton(),
        ],
      ),
    );
  }

  Widget _buildNavButton(String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/signup'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_sky500, _cyan500]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _sky500.withAlpha(77),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      child: Column(
        children: [
          // Animated logo
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_sky500, _cyan500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _sky500.withAlpha(100),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE2E8F0)],
            ).createShader(bounds),
            child: Text(
              'The Story Behind',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 28 : 42,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 8),

          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_sky500, _cyan500, _purple500],
            ).createShader(bounds),
            child: Text(
              'GEARSH',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 48 : 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Subtitle
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'A fusion of "gear" and "share" — the story of how a student\'s DJ dreams became a global platform for creative talent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.white.withAlpha(153),
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Scroll indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  'Scroll to read',
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withAlpha(100),
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildStoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    String? imagePath,
    String? imageCaption,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withAlpha(51)),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.white.withAlpha(200)],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Image (if provided)
          if (imagePath != null) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            if (imageCaption != null) ...[
              const SizedBox(height: 12),
              Text(
                imageCaption,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withAlpha(100),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],

          const SizedBox(height: 24),

          // Content
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 16,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameOriginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sky500.withAlpha(26),
            _cyan500.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        children: [
          // Equation
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildWordChip('Gear', _sky500),
              Text(
                '+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withAlpha(150),
                ),
              ),
              _buildWordChip('Share', _cyan500),
              Text(
                '=',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withAlpha(150),
                ),
              ),
              _buildWordChip('Gearsh', _purple500, isResult: true),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Every start-up needs a memorable name. The brainstorming led to a simple combination: "gear" + "share". By blending these words and trimming a few letters, "Gearsh" was born.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 16,
              height: 1.8,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'It\'s short, catchy, and original — a name that feels both invented and meaningful, unique to our brand but intuitive once you know the story.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChip(String text, Color color, {bool isResult = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isResult ? 24 : 20,
        vertical: isResult ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(isResult ? 51 : 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(isResult ? 128 : 77)),
        boxShadow: isResult
            ? [
                BoxShadow(
                  color: color.withAlpha(51),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: isResult ? 22 : 18,
          fontWeight: isResult ? FontWeight.bold : FontWeight.w600,
          letterSpacing: isResult ? 2 : 0,
        ),
      ),
    );
  }

  Widget _buildClosingCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _purple500.withAlpha(26),
            _sky500.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple500.withAlpha(51)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: _amber500,
            size: 48,
          ),
          const SizedBox(height: 24),
          const Text(
            'More Than Just a Name',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gearsh is more than just a mash-up of words; it\'s a testament to our mission. It embodies the DIY spirit and collaborative ethos that kicked off the journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 16,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'From humble beginnings of trying to solve a personal hurdle, to building a community for artists and fans, the name Gearsh carries our history in its 6 letters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: 15,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 32),
          _buildSignUpButton(),
        ],
      ),
    );
  }

  Widget _buildBackToTopButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _scrollToTop,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_sky500, _cyan500]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _sky500.withAlpha(100),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: EdgeInsets.symmetric(
        vertical: 48,
        horizontal: isMobile ? 24 : 60,
      ),
      child: Column(
        children: [
          // Footer content
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 60,
            runSpacing: 32,
            children: [
              _buildFooterSection('Gearsh', ['Visit Help Centre', 'Download App']),
              _buildFooterSection('Company', ['About Us', 'Careers', 'Press', 'Blog']),
              _buildFooterSection('Products', ['Book Artists', 'For Artists', 'Events', 'Gift Cards']),
              _buildFooterSection('Legal', ['Privacy Policy', 'Terms of Service', 'Accessibility']),
            ],
          ),

          const SizedBox(height: 48),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withAlpha(26),
          ),

          const SizedBox(height: 32),

          // Bottom row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 24,
            runSpacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text('English', style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(width: 24),
                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text('Makhado, Limpopo', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
              Text(
                '© 2025 Gearsh Inc. All rights reserved.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(String heading, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              item,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        )),
      ],
    );
  }
}

