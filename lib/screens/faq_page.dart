import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/global_config_service.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Color constants - matching Gearsh theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _purple500 = Color(0xFF8B5CF6);
  static const Color _green500 = Color(0xFF22C55E);
  static const Color _amber500 = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: padding.top + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: _slate950.withAlpha(242),
                border: Border(
                  bottom: BorderSide(color: _sky500.withAlpha(51)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          try {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/profile-settings');
                            }
                          } catch (e) {
                            context.go('/profile-settings');
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _slate900.withAlpha(128),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _sky500.withAlpha(77)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_sky400, _cyan400],
                        ).createShader(bounds),
                        child: const Text(
                          'Help & Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: _slate800.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: _sky500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'FAQ'),
                        Tab(text: 'About'),
                        Tab(text: 'Privacy'),
                        Tab(text: 'Terms'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFAQTab(),
                  _buildAboutTab(),
                  _buildPrivacyTab(),
                  _buildTermsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FAQ TAB ====================
  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFAQSection('Getting Started', Icons.rocket_launch_rounded, _sky500, [
            _FAQItem(
              question: 'What is Gearsh?',
              answer: 'Gearsh is a global marketplace connecting clients with creative talent including DJs, photographers, videographers, musicians, and other artists for events and bookings worldwide.',
            ),
            _FAQItem(
              question: 'How do I create an account?',
              answer: 'Download the Gearsh app, tap "Get Started", and choose to sign up with your email, Google, or Apple account. You can join as a Client (to book artists), Artist (to get booked), or Fan (to follow artists).',
            ),
            _FAQItem(
              question: 'Is Gearsh available in my country?',
              answer: 'Gearsh operates globally! We support users in over 20 countries across Africa, Americas, Europe, and Asia Pacific. You can change your region in Profile Settings to see prices in your local currency.',
            ),
            _FAQItem(
              question: 'Do I need to pay to use Gearsh?',
              answer: 'Creating an account and browsing artists is completely free. You only pay when you book an artist. Artists pay a 12.6% service fee on completed bookings.',
            ),
          ]),

          _buildFAQSection('Booking Artists', Icons.calendar_today_rounded, _cyan500, [
            _FAQItem(
              question: 'How do I book an artist?',
              answer: 'Browse or search for artists, view their profile and services, select your desired service, choose your event date and details, then proceed to payment. The artist will confirm your booking.',
            ),
            _FAQItem(
              question: 'What payment methods are accepted?',
              answer: 'Payment methods vary by region. We support card payments, PayFast (South Africa), Flutterwave (Africa), Stripe (US/EU), M-Pesa (East Africa), and more.',
            ),
            _FAQItem(
              question: 'Can I book multiple artists at once?',
              answer: 'Yes! Use our cart feature to add multiple artists to your booking. This is perfect for events needing a DJ, photographer, and videographer together.',
            ),
            _FAQItem(
              question: 'What currencies are supported?',
              answer: 'Gearsh supports 15+ currencies including ZAR, USD, GBP, EUR, NGN, KES, GHS, AUD, CAD, INR, AED, and more. Prices are automatically converted based on your region.',
            ),
            _FAQItem(
              question: 'How are travel costs calculated?',
              answer: 'Artists can set their travel radius and per-kilometre rates. Our system automatically calculates distance and adds travel costs to your booking total.',
            ),
          ]),

          _buildFAQSection('For Artists', Icons.mic_external_on_rounded, _purple500, [
            _FAQItem(
              question: 'How do I become an artist on Gearsh?',
              answer: 'Sign up and select "I\'m an Artist" during onboarding. Complete your profile with your services, pricing, portfolio, and availability. Get verified to build trust with clients.',
            ),
            _FAQItem(
              question: 'What is the service fee?',
              answer: 'Gearsh charges a 12.6% service fee on completed bookings. This covers payment processing, platform maintenance, support, and marketing.',
            ),
            _FAQItem(
              question: 'When do I get paid?',
              answer: 'Payments are released after successful completion of your booking. Funds are typically available within 2-5 business days depending on your region.',
            ),
            _FAQItem(
              question: 'Can I set my own prices?',
              answer: 'Absolutely! You have full control over your service pricing, packages, travel fees, and accommodation requirements. Set prices in your local currency.',
            ),
            _FAQItem(
              question: 'How do I get verified?',
              answer: 'Go to your dashboard and apply for verification. You\'ll need to provide a government-issued ID and complete our verification process. Verified artists get a blue tick badge.',
            ),
          ]),

          _buildFAQSection('Cancellations & Refunds', Icons.replay_rounded, _green500, [
            _FAQItem(
              question: 'What is the cancellation policy?',
              answer: 'Cancellation terms vary by artist and are displayed at checkout. Generally, earlier cancellations receive fuller refunds. Late cancellations may receive partial or no refund.',
            ),
            _FAQItem(
              question: 'What if an artist cancels on me?',
              answer: 'If an artist cancels without valid reason, you\'ll receive a full refund. We\'ll also help you find a replacement artist. Repeat cancellers face account penalties.',
            ),
            _FAQItem(
              question: 'How long do refunds take?',
              answer: 'Refunds are processed within 5-10 business days. The time to appear in your account depends on your payment method and bank.',
            ),
          ]),

          _buildFAQSection('Safety & Support', Icons.shield_rounded, const Color(0xFFEF4444), [
            _FAQItem(
              question: 'Is Gearsh safe to use?',
              answer: 'Yes! We verify artists, secure all payments through trusted providers, and have a dedicated support team. All transactions are protected and we never share your payment details.',
            ),
            _FAQItem(
              question: 'How do I report an issue?',
              answer: 'Go to Profile > Help Centre or contact us at support@thegearsh.com. For urgent safety concerns, use the in-app emergency report feature.',
            ),
            _FAQItem(
              question: 'What if I have a dispute with an artist/client?',
              answer: 'Contact our support team through the Help Centre. We mediate disputes fairly and can hold payments until issues are resolved.',
            ),
          ]),

          const SizedBox(height: 20),
          _buildContactCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFAQSection(String title, IconData icon, Color color, List<_FAQItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _buildExpandableFAQ(item)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildExpandableFAQ(_FAQItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _slate800.withAlpha(102),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(38)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          iconColor: _sky400,
          collapsedIconColor: Colors.white54,
          title: Text(
            item.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Text(
              item.answer,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_sky500.withAlpha(38), _cyan500.withAlpha(38)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sky500.withAlpha(77)),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_rounded, color: _sky400, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Still have questions?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is here to help 24/7',
            style: TextStyle(color: Colors.white.withAlpha(153)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  'Email Us',
                  Icons.email_outlined,
                  () {/* Open email */},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  'Live Chat',
                  Icons.chat_bubble_outline_rounded,
                  () {/* Open chat */},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _slate900.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _sky500.withAlpha(77)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _sky400, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _sky400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ABOUT TAB ====================
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_sky500.withAlpha(51), _cyan500.withAlpha(51)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _sky500.withAlpha(77)),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_sky500, _cyan500],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _sky500.withAlpha(102),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_sky400, _cyan400],
                  ).createShader(bounds),
                  child: const Text(
                    'Gearsh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book Creative Talent Worldwide',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // The Name Origin
          _buildStorySection(
            'The Story Behind "Gearsh"',
            Icons.lightbulb_rounded,
            _amber500,
            '''People often ask where the word "Gearsh" comes from. In short, Gearsh is a fusion of "gear" and "share/sharing" — embodying the original vision of a platform for sharing gear (equipment) much like how Uber enables sharing rides.

The name reflects both the problem that inspired the company's founding and the innovative solution that followed.''',
          ),

          const SizedBox(height: 24),

          // Our Story
          _buildStorySection(
            'From DJ Dreams to a New Idea',
            Icons.auto_stories_rounded,
            _sky500,
            '''The story of Gearsh begins with a personal passion and a challenge. Our founder aspired to be a DJ, but professional DJ equipment — the turntables, mixers, speakers, and more — was prohibitively expensive for a student.

As a computer science student with an entrepreneurial spirit, he looked at this problem and saw an opportunity: what if there were a way to share gear? Musicians and creators often have equipment that sits unused, while others need that gear temporarily.

This gap sparked an idea — a community-driven gear-sharing platform where people could hire or share equipment instead of everyone needing to buy their own.''',
          ),

          const SizedBox(height: 24),

          // Sharing Economy
          _buildStorySection(
            'Inspired by the Sharing Economy',
            Icons.share_rounded,
            _cyan500,
            '''The mid-2010s were a time when "Uber for X" became a buzzworthy concept. Uber's success in ride-sharing proved that peer-to-peer sharing models could revolutionise industries.

Our founder asked: "What if there was an Uber, but for gear?" Armed with his tech background, he set out to build a peer-to-peer gear-sharing platform — making it as easy to borrow a DJ mixer as it is to catch a ride across town.

Just as homeowners share rooms on Airbnb or drivers share rides via Uber, why not let people share their musical or creative gear? It was a win-win: owners could earn money from idle equipment, and borrowers could access expensive gear affordably.''',
          ),

          const SizedBox(height: 24),

          // The Name
          _buildStorySection(
            'Gear + Sharing = Gearsh',
            Icons.text_fields_rounded,
            _purple500,
            '''Every start-up needs a memorable name. The brainstorming led to a simple combination: "gear" + "share". By blending these words and trimming a few letters, "Gearsh" was born.

This unique name encapsulates the platform's core purpose in a concise way. It's short, catchy, and original — a name that feels both invented and meaningful, unique to our brand but intuitive once you know the story.''',
          ),

          const SizedBox(height: 24),

          // Evolution
          _buildStorySection(
            'What "Gearsh" Means Today',
            Icons.rocket_launch_rounded,
            _green500,
            '''Although Gearsh's origin lies in gear-sharing, the platform has grown and evolved since its founding in 2016. Today, Gearsh is the ultimate artist e-booking service — a digital marketplace that connects musicians, dancers, actors, photographers, and other artists with those who want to book them.

At its heart, Gearsh has always been about connecting people with the resources and opportunities they need. Whether that resource was a DJ rig or a live gig, Gearsh stands for accessibility and community in the creative space.

"Gearsh" means innovation born from necessity — a student with a dream, an unmet need, and a clever solution. It's about empowering individuals and bridging gaps through a seamless, modern platform.''',
          ),

          const SizedBox(height: 24),

          // Global Presence
          _buildStorySection(
            'Global Presence',
            Icons.public_rounded,
            _sky500,
            '''Gearsh operates in over 20 countries across:

🌍 Africa: South Africa, Nigeria, Kenya, Ghana, Botswana, Namibia, Zimbabwe, Tanzania, Uganda, Rwanda

🌎 Americas: United States, Canada, Brazil

🌏 Europe: United Kingdom, Germany, France

🌏 Asia Pacific: Australia, India, UAE, Japan

We support 15+ currencies and work with region-specific payment providers to make bookings seamless wherever you are.''',
          ),

          const SizedBox(height: 24),

          // Values
          _buildValuesSection(),

          const SizedBox(height: 24),

          // Stats
          _buildStatsSection(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStorySection(String title, IconData icon, Color color, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _slate800.withAlpha(102),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _sky500.withAlpha(38)),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValuesSection() {
    final values = [
      {'icon': Icons.handshake_rounded, 'title': 'Trust', 'desc': 'Secure payments & verified artists'},
      {'icon': Icons.diversity_3_rounded, 'title': 'Community', 'desc': 'Supporting creators globally'},
      {'icon': Icons.lightbulb_rounded, 'title': 'Innovation', 'desc': 'Always improving the experience'},
      {'icon': Icons.favorite_rounded, 'title': 'Passion', 'desc': 'We love what we do'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _green500.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_rounded, color: _green500, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Our Values',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: values.map((v) => _buildValueCard(
            v['icon'] as IconData,
            v['title'] as String,
            v['desc'] as String,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildValueCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800.withAlpha(102),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(38)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _sky400, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(153),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple500.withAlpha(38), _sky500.withAlpha(38)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple500.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('20+', 'Countries'),
          _buildStatDivider(),
          _buildStatItem('1000+', 'Artists'),
          _buildStatDivider(),
          _buildStatItem('15+', 'Currencies'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_sky400, _cyan400],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(153),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withAlpha(51),
    );
  }

  // ==================== PRIVACY TAB ====================
  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegalHeader(
            'Privacy Policy',
            Icons.privacy_tip_outlined,
            'Last updated: December 2025',
            'This Privacy Policy explains how Gearsh collects, uses, shares, and protects personal information in compliance with applicable data protection laws worldwide, including GDPR (Europe), CCPA (California), POPIA (South Africa), and other regional regulations.',
          ),

          const SizedBox(height: 24),

          _buildLegalSection('What We Collect', [
            '• Account information (name, email, phone)',
            '• Identity verification documents',
            '• Location data (with permission)',
            '• Booking and transaction history',
            '• Usage and device information',
            '• Communications via the platform',
          ]),

          _buildLegalSection('How We Use Your Data', [
            '• Create and manage your account',
            '• Enable bookings between clients and artists',
            '• Process payments securely',
            '• Verify identity and prevent fraud',
            '• Improve our platform and services',
            '• Communicate important updates',
            '• Comply with legal obligations',
          ]),

          _buildLegalSection('Your Rights', [
            '• Access your personal information',
            '• Correct inaccurate data',
            '• Delete your account and data',
            '• Restrict or object to processing',
            '• Data portability',
            '• Withdraw consent at any time',
          ]),

          _buildLegalSection('Data Protection by Region', [
            'EU/EEA (GDPR): Full data subject rights, 30-day response',
            'California (CCPA): Right to know, delete, opt-out',
            'South Africa (POPIA): Access, correction, objection rights',
            'All regions: We never sell your personal data',
          ]),

          _buildLegalSection('Data Security', [
            '• Encrypted data transmission (TLS/SSL)',
            '• Secure payment processing via trusted providers',
            '• Regular security audits',
            '• Limited employee access to personal data',
          ]),

          _buildLegalSection('Contact Us', [
            'Email: privacy@thegearsh.com',
            'In-app: Settings > Help Centre > Privacy',
            'Website: thegearsh.com/privacy',
          ]),

          const SizedBox(height: 20),
          _buildViewFullDocButton('View Full Privacy Policy', () {
            context.push('/privacy-policy');
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== TERMS TAB ====================
  Widget _buildTermsTab() {
    final jurisdiction = globalConfigService.getTermsJurisdiction();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegalHeader(
            'Terms & Conditions',
            Icons.description_outlined,
            'Last updated: December 2025',
            'These Terms & Conditions govern the use of the Gearsh platform globally. By using Gearsh, you agree to these terms.',
          ),

          const SizedBox(height: 24),

          _buildLegalSection('Using Gearsh', [
            '• You must be 18+ to create an account',
            '• Provide accurate and current information',
            '• Keep your account credentials secure',
            '• Don\'t misrepresent your identity or services',
            '• Don\'t bypass our payment system',
          ]),

          _buildLegalSection('Bookings & Payments', [
            '• Clients pay 100% upfront through Gearsh',
            '• Payments accepted in your local currency',
            '• Artists receive payment after service completion',
            '• Service fee: 12.6% on all bookings',
            '• Travel costs calculated automatically',
          ]),

          _buildLegalSection('Cancellations', [
            '• Cancellation terms shown at checkout',
            '• Earlier cancellations = fuller refunds',
            '• Artist cancellations result in full refund',
            '• Repeated cancellations may affect your account',
          ]),

          _buildLegalSection('For Artists', [
            '• Honour all confirmed bookings',
            '• Perform services as agreed',
            '• Don\'t accept off-platform payments',
            '• Maintain professional conduct',
            '• Respond to booking requests promptly',
          ]),

          _buildLegalSection('For Clients', [
            '• Provide accurate event details',
            '• Ensure safe venue access',
            '• Pay all fees upfront',
            '• Communicate clearly with artists',
          ]),

          _buildLegalSection('Disputes & Governing Law', [
            '• Contact support first to resolve issues',
            '• Gearsh may mediate disputes',
            'These terms are governed by the laws of $jurisdiction.',
            '• EU users may use EU ODR platform',
          ]),

          const SizedBox(height: 20),
          _buildViewFullDocButton('View Full Terms & Conditions', () {
            context.push('/terms');
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLegalHeader(String title, IconData icon, String date, String summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_sky500.withAlpha(38), _cyan500.withAlpha(38)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sky500.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _sky500.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _sky400, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withAlpha(128),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary,
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _sky400,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _slate800.withAlpha(102),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sky500.withAlpha(38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewFullDocButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _sky500,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;

  _FAQItem({required this.question, required this.answer});
}

