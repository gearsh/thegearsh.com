import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                        'Privacy Policy',
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

                      // I. Overview
                      _buildMainSection('I. Overview'),
                      _buildSection('Scope', [
                        'This Privacy Policy applies when you use the Gearsh mobile application or website to request, book, or receive entertainment services.',
                        '',
                        'It applies specifically to:',
                        '• Clients who book Artists through Gearsh',
                        '• Artists who offer services through Gearsh',
                        '• Guest Users who receive services booked by another User',
                        '',
                        'Our privacy practices may vary depending on applicable laws in the country or region where you use Gearsh.',
                      ]),

                      // II. Data Collection & Use
                      _buildMainSection('II. Data Collection & Use'),

                      _buildSection('A. Data We Collect', [
                        'Gearsh collects personal information in three ways:',
                        '1. Information you provide',
                        '2. Information collected when you use the platform',
                        '3. Information received from third parties',
                      ]),

                      _buildSubSection('1. Data You Provide'),
                      _buildSection('a. Account Information', [
                        '• Full name',
                        '• Email address',
                        '• Phone number',
                        '• Login credentials',
                        '• Profile photo',
                        '• Payment method details (processed securely by third-party providers)',
                        '• User preferences and settings',
                      ]),
                      _buildSection('b. Demographic Information', [
                        '• Age or date of birth (to verify eligibility)',
                        '• Gender (optional, where relevant for analytics or features)',
                      ]),
                      _buildSection('c. Identity Verification Information', [
                        '• Government-issued ID (ID card, passport, or equivalent)',
                        '• Selfie or photo for verification',
                        '• Verification status (displayed as a verification tick)',
                      ]),
                      _buildSection('d. User Content', [
                        '• Ratings and reviews',
                        '• Feedback and support messages',
                        '• Uploaded images or documents',
                      ]),

                      _buildSubSection('2. Data Collected When You Use Gearsh'),
                      _buildSection('a. Location Data', [
                        '• Approximate and/or precise location (with permission)',
                        '• Event location and Artist location',
                        '',
                        'This data is used to:',
                        '• Calculate distance',
                        '• Display maps during booking',
                        '• Automatically calculate travel and accommodation costs',
                      ]),
                      _buildSection('b. Booking & Transaction Information', [
                        '• Booking details (date, time, location)',
                        '• Distance travelled',
                        '• Fees paid and payout amounts',
                        '• Cancellation history',
                      ]),
                      _buildSection('c. Usage & Device Data', [
                        '• App usage statistics',
                        '• Device type, operating system, and IP address',
                        '• Log and crash data',
                      ]),
                      _buildSection('d. Communications Data', [
                        '• Messages exchanged via the platform',
                        '• Support communications',
                      ]),

                      _buildSubSection('3. Data from Third Parties'),
                      _buildSection('', [
                        'Gearsh may receive data from:',
                        '• Payment processors',
                        '• Identity verification providers',
                        '• Fraud prevention services',
                        '• Law enforcement or regulators where legally required',
                      ]),

                      _buildSection('B. How We Use Personal Information', [
                        'Gearsh uses personal data to:',
                        '1. Create and manage user accounts',
                        '2. Enable bookings between Clients and Artists',
                        '3. Calculate pricing, distance, and additional costs',
                        '4. Process payments and payouts',
                        '5. Verify identity and prevent fraud',
                        '6. Provide customer support',
                        '7. Improve platform performance and features',
                        '8. Communicate policy updates and service notices',
                        '9. Comply with legal and regulatory obligations',
                      ]),

                      _buildSection('C. Core Automated Processes', [
                        'Gearsh uses automated systems to:',
                        '• Match Clients with suitable Artists',
                        '• Calculate booking prices and travel costs',
                        '• Detect fraudulent or suspicious activity',
                        '',
                        'These processes are essential to providing a secure and efficient marketplace experience.',
                      ]),

                      _buildSection('D. Cookies & Similar Technologies', [
                        'Gearsh uses cookies and similar technologies to:',
                        '• Authenticate users',
                        '• Remember preferences',
                        '• Analyze platform usage',
                        '• Improve performance',
                        '',
                        'Users may manage cookie preferences through their device or browser settings.',
                      ]),

                      _buildSection('E. Data Sharing & Disclosure', [
                        'Gearsh may share personal information:',
                        '',
                        '1. With other Users',
                        '   • Booking-related details (name, event details, location)',
                        '',
                        '2. With Service Providers',
                        '   • Payment processors',
                        '   • Identity verification partners',
                        '   • Cloud hosting and analytics providers',
                        '',
                        '3. For Legal Reasons',
                        '   • Compliance with laws, court orders, or regulatory requests',
                        '   • Investigation of fraud, disputes, or safety incidents',
                        '',
                        'Gearsh does not sell personal information.',
                      ]),

                      _buildSection('F. Data Retention & Deletion', [
                        'Gearsh retains personal data only as long as necessary to:',
                        '• Provide services',
                        '• Meet legal, tax, and regulatory requirements',
                        '• Resolve disputes or enforce agreements',
                        '',
                        'Users may request account deletion through the app. Some data may be retained where legally required or necessary for fraud prevention.',
                      ]),

                      // III. Choice & Transparency
                      _buildMainSection('III. Choice & Transparency'),
                      _buildSection('Your Rights', [
                        'Depending on your location, you may have the following rights:',
                        '',
                        '• Access your personal information',
                        '• Correct inaccurate data',
                        '• Delete your personal data ("right to be forgotten")',
                        '• Restrict or object to processing',
                        '• Data portability',
                        '• Withdraw consent',
                        '• Lodge a complaint with a supervisory authority',
                        '',
                        'Requests can be made via Gearsh support.',
                      ]),
                      _buildSection('Regional Rights', [
                        'EU/EEA Users (GDPR):',
                        '• All rights listed above apply',
                        '• 30-day response time for requests',
                        '',
                        'California Users (CCPA):',
                        '• Right to know what data is collected',
                        '• Right to delete personal information',
                        '• Right to opt-out of sale (Gearsh does not sell data)',
                        '• Right to non-discrimination',
                        '',
                        'South African Users (POPIA):',
                        '• Right to access and correction',
                        '• Right to object to processing',
                        '• Right to complain to the Information Regulator',
                      ]),

                      // IV. Legal Information
                      _buildMainSection('IV. Legal Information'),

                      _buildSection('A. Data Controller', [
                        'Gearsh is the data controller responsible for personal information processed through the platform.',
                      ]),

                      _buildSection('B. Legal Basis for Processing', [
                        'We process personal information based on:',
                        '• Contractual necessity',
                        '• User consent',
                        '• Legal obligations',
                        '• Legitimate business interests (such as safety and fraud prevention)',
                      ]),

                      _buildSection('C. Data Transfers', [
                        'Gearsh operates globally and may process or store data on secure servers located in different countries. When we transfer personal data internationally, we ensure appropriate safeguards are in place, including:',
                        '',
                        '• Standard Contractual Clauses (for EU/EEA data)',
                        '• Adequacy decisions where applicable',
                        '• Consent-based transfers where legally permitted',
                        '',
                        'Data may be processed in the following regions:',
                        '• South Africa (primary operations)',
                        '• European Union (for EU users)',
                        '• United States (cloud infrastructure)',
                        '• Other regions as necessary for service delivery',
                      ]),

                      _buildSection('D. Updates to This Privacy Policy', [
                        'Gearsh may update this Privacy Policy from time to time. Continued use of the platform constitutes acceptance of the updated policy.',
                      ]),

                      _buildSection('Contact', [
                        'For privacy-related questions or requests, contact Gearsh:',
                        '',
                        '• Email: privacy@thegearsh.com',
                        '• In-app: Settings > Help Centre > Privacy',
                        '• Website: thegearsh.com/privacy',
                        '',
                        'For EU users, you may also contact your local data protection authority.',
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
          const Icon(Icons.privacy_tip_outlined, color: _sky400, size: 24),
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
                  'This Privacy Policy explains how Gearsh collects, uses, shares, and protects personal information in compliance with applicable data protection laws worldwide, including GDPR (Europe), CCPA (California), POPIA (South Africa), and other regional regulations.',
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

  Widget _buildMainSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_sky500.withAlpha(38), _cyan400.withAlpha(25)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _sky500.withAlpha(51)),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_sky400, _cyan400],
          ).createShader(bounds),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: _cyan400.withAlpha(230),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_sky400, _cyan400],
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...content.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
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

