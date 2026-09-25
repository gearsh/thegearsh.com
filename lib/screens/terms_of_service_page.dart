import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                        'The Gearsh (Pty) Ltd operates a marketplace connecting Clients with independent Artists. This draft requires legal approval before paid bookings are offered under it.',
                        '',
                        'These Terms apply to users in all regions where Gearsh operates. Some provisions may vary based on local law requirements.',
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
                        'Violation may result in suspension or termination, subject to applicable law and existing booking obligations.',
                      ]),
                      _buildSection('5. Rights of Gearsh & Termination', [
                        'Gearsh may:',
                        '1. Suspend or terminate any User account for breach of these Terms.',
                        '2. Remove content or listings that violate policy.',
                        '3. Review disputes and payment concerns before communicating a resolution to affected users.',
                        '',
                        'Users may close their accounts, subject to existing bookings and disputes.',
                      ]),
                      _buildSection('6. Financial Terms & Payments', [
                        '6.1 Payment Structure',
                        '1. Where checkout is enabled, payment follows Artist acceptance and a confirmed positive price. A booking is confirmed only after verified payment notification.',
                        '2. The Client pays the Artist Subtotal plus a 12.6% Client fee. Gearsh deducts a 4% Artist fee from the Artist Subtotal. The combined fees are 16.6% of the Artist Subtotal.',
                        '3. For a R1,000 Artist Subtotal, the Client pays R1,126 and the Artist\'s calculated share is R960 before adjustments. No separate Artist deposit or PayFast processing charge is added at checkout.',
                        '4. A calculated Artist share is not a completed payout. Gearsh must confirm payout method and timing before accepting live paid bookings; automated escrow release is not available.',
                        '',
                        '6.2 Currency & Conversion',
                        'The current booking checkout is denominated in South African rand. Any later currency support must be disclosed before payment.',
                        '',
                        '6.3 Travel, Distance & Additional Costs',
                        '1. Artists may define travel radius, per-kilometre fees, and accommodation requirements.',
                        '2. Gearsh calculates distance using location data and displays it via an in-app map.',
                        '3. Additional costs must be agreed and reflected in the confirmed price before payment.',
                        '',
                        'Clients are responsible for all agreed additional expenses.',
                      ]),
                      _buildSection('7. Cancellations & Refunds', [
                        '7.1 Client Cancellations',
                        '• Before payment, either party may request cancellation.',
                        '• After payment, contact support@thegearsh.com with the booking reference and reason. A status change does not issue a refund.',
                        '• Gearsh reviews the agreed terms, facts, payment record and applicable law. Any cancellation charge must be reasonable in the circumstances.',
                        '',
                        '7.2 Artist Cancellations',
                        '• Report an Artist cancellation or no-show promptly with supporting information.',
                        '',
                        'An approved refund is complete only when confirmed by the payment provider. Statutory consumer rights remain available.',
                      ]),
                      _buildSection('8. Dispute Resolution', [
                        '1. Users must first attempt resolution via Gearsh support.',
                        '2. Gearsh may mediate disputes between Clients and Artists.',
                        '3. The platform does not currently enforce an automatic 36-hour dispute window, freeze a payout, or issue split refunds. South African law applies to these draft terms.',
                        '',
                        'For international disputes:',
                        '• Report a dispute promptly to support@thegearsh.com with the booking reference and available evidence.',
                      ]),
                      _buildSection('9. Safety & Liability', [
                        '1. Artists must perform professionally and lawfully.',
                        '2. Clients must provide a safe event environment.',
                        '3. Nothing in these draft terms limits rights or liabilities that cannot lawfully be excluded.',
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
                        '• Pay the displayed amount when a booking is accepted and checkout is enabled',
                      ]),
                      _buildSection('12. Amendments', [
                        'Gearsh may update these Terms at any time. Continued use constitutes acceptance of changes.',
                      ]),
                      _buildSection('13. Contact', [
                        'For questions regarding these Terms, contact Gearsh:',
                        '',
                        '• Email: support@thegearsh.com',
                        '• In-app: Settings > Help Centre',
                        '• Website: thegearsh.com/terms',
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
                  'Draft for legal review, 25 September 2026. These terms require approval before paid bookings are offered under them. Payment and consumer rights depend on applicable law.',
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
