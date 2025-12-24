import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  // Color constants - matching Gearsh theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan400 = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _slate950.withAlpha(242),
                  border: const Border(
                    bottom: BorderSide(
                      color: Color(0x330EA5E9),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                        'Terms & Conditions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegalNotice(),
                      const SizedBox(height: 24),
                      _buildSection('1. Introduction', [
                        'Gearsh is a digital marketplace that connects Clients with Artists for entertainment bookings. By accessing or using the Gearsh application or website, you agree to be bound by these Terms & Conditions.',
                      ]),
                      _buildSection('2. Definitions', [
                        '• "Gearsh" refers to the Gearsh platform, including its app, website, directors, employees, and partners.',
                        '• "Artist" refers to performers or entertainers offering services through Gearsh.',
                        '• "Client" refers to individuals or entities booking Artists.',
                        '• "User" refers collectively to Artists and Clients.',
                      ]),
                      _buildSection('3. Registration & Account Rules', [
                        '1. Users must be at least 18 years old and legally able to enter contracts.',
                        '2. All information provided during registration must be accurate and current.',
                        '3. Gearsh may require identity verification using legal documents.',
                        '4. Verified users may display a verification tick.',
                        '5. Users are responsible for maintaining account security.',
                        '',
                        'Gearsh reserves the right to suspend or terminate accounts that provide false information.',
                      ]),
                      _buildSection('4. User Conduct & Platform Policy', [
                        'Users may not:',
                        '• Misrepresent identity or services',
                        '• Bypass Gearsh\'s payment system',
                        '• Engage in fraud, abuse, or harassment',
                        '• Use the platform for unlawful purposes',
                        '',
                        'Violation may result in suspension, termination, or loss of funds.',
                      ]),
                      _buildSection('5. Rights of Gearsh & Termination', [
                        'Gearsh may:',
                        '1. Suspend or terminate any User account for breach of these Terms.',
                        '2. Remove content or listings that violate policy.',
                        '3. Withhold or delay payouts in cases of disputes, fraud, or safety concerns.',
                        '',
                        'Users may close their accounts, subject to existing bookings and disputes.',
                      ]),
                      _buildSection('6. Financial Terms & Payments', [
                        '6.1 Payment Structure',
                        '1. Clients must pay 100% of the booking amount upfront through the Gearsh platform.',
                        '2. Funds are held by Gearsh until the performance is completed.',
                        '3. Artists receive payment after successful performance completion, less Gearsh\'s service fee (12.6%).',
                        '',
                        '6.2 Travel, Distance & Additional Costs',
                        '1. Artists may define travel radius, per-kilometer fees, and accommodation requirements.',
                        '2. Gearsh calculates distance using location data and displays it via an in-app map.',
                        '3. Additional costs are automatically added to the booking total.',
                        '',
                        'Clients are responsible for all agreed additional expenses.',
                      ]),
                      _buildSection('7. Cancellations & Refunds', [
                        '7.1 Client Cancellations',
                        '• Refund eligibility depends on cancellation timing.',
                        '• Cancellation terms are displayed at checkout.',
                        '• Late cancellations may result in partial or no refund.',
                        '',
                        '7.2 Artist Cancellations',
                        '• Artists who cancel without valid reason may face penalties, including suspension or loss of payout.',
                        '• Artists may be required to assist in finding a replacement.',
                        '',
                        'Gearsh reserves discretion in issuing refunds.',
                      ]),
                      _buildSection('8. Dispute Resolution', [
                        '1. Users must first attempt resolution via Gearsh support.',
                        '2. Gearsh may mediate disputes.',
                        '3. These Terms are governed by the laws of South Africa.',
                      ]),
                      _buildSection('9. Safety & Liability', [
                        '1. Artists must perform professionally and lawfully.',
                        '2. Clients must provide a safe event environment.',
                        '3. Gearsh is not responsible for injuries, damages, or losses arising from events.',
                        '4. Safety incidents must be reported promptly.',
                      ]),
                      _buildSection('10. Artist Obligations', [
                        'Artists agree to:',
                        '• Honour confirmed bookings',
                        '• Perform as agreed',
                        '• Avoid off-platform payments',
                        '',
                        'Failure may result in penalties or account termination.',
                      ]),
                      _buildSection('11. Client Obligations', [
                        'Clients agree to:',
                        '• Provide accurate event details',
                        '• Ensure venue access and safety',
                        '• Pay all fees upfront',
                      ]),
                      _buildSection('12. Amendments', [
                        'Gearsh may update these Terms at any time. Continued use constitutes acceptance of changes.',
                      ]),
                      _buildSection('13. Contact', [
                        'For questions regarding these Terms, contact Gearsh support through the app.',
                      ]),
                      const SizedBox(height: 40),
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

  Widget _buildLegalNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _sky500.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _sky400, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Legal Notice',
                  style: TextStyle(
                    color: _sky400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These Terms & Conditions govern the use of the Gearsh platform. This is a draft framework and must be reviewed by a qualified legal professional before public release.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_sky400, _cyan400],
            ).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...content.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

