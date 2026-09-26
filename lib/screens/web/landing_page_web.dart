import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/utils/static_site_navigation.dart';

class WebLandingPage extends StatelessWidget {
  const WebLandingPage({super.key});

  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate950 = Color(0xFF020617);

  void _signIn(BuildContext context) {
    if (kIsWeb) {
      openStaticSignIn();
      return;
    }
    context.go('/login');
  }

  Widget _button({
    required String label,
    required VoidCallback onPressed,
    bool primary = true,
  }) {
    return primary
        ? ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _sky500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          );
  }

  Widget _navLink(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String eyebrow, String title, String body) {
    return Column(
      children: [
        Text(
          eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _sky400,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 17,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _audienceCard({
    required String label,
    required String title,
    required String body,
    required String button,
    required VoidCallback onPressed,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _sky400,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 16,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          _button(label: button, onPressed: onPressed),
        ],
      ),
    );
  }

  Widget _step(int number, String title, String body) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sky500.withValues(alpha: 0.13),
                border: Border.all(color: _sky500.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: _sky400,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(String title, String body, IconData icon) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _sky400, size: 28),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slate950,
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Navigation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                child: Row(
                  children: [
                    Image.asset('assets/images/gearsh-logo.png', height: 42),
                    const Spacer(),
                    _navLink('Find Talent', () => context.go('/search')),
                    _navLink('For Artists', () => context.go('/join')),
                    _navLink('How It Works', () => context.go('/faq')),
                    _navLink('About', () => context.go('/about')),
                    const SizedBox(width: 16),
                    _button(label: 'Sign In', onPressed: () => _signIn(context)),
                  ],
                ),
              ),

              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(40, 80, 40, 110),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _slate950,
                      _slate900,
                      _slate950,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: _sky500.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _sky500.withValues(alpha: 0.25)),
                      ),
                      child: const Text(
                        'THE CREATIVE MARKETPLACE',
                        style: TextStyle(
                          color: _sky400,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: const Text(
                        'Find the right talent.\nBook with confidence.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          height: 1.03,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        'Discover DJs, musicians, photographers, videographers, producers, MCs and other creative professionals. Find a service, connect with the right person and book through Gearsh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 18,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        _button(
                          label: 'Find Talent',
                          onPressed: () => context.go('/search'),
                        ),
                        _button(
                          label: 'Join as an Artist',
                          primary: false,
                          onPressed: () => context.go('/join'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Two audiences
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 90, 40, 110),
                child: Column(
                  children: [
                    _sectionTitle(
                      'One marketplace',
                      'Built for both sides of the booking.',
                      'Clients need great creative work. Artists need opportunities. Gearsh brings both sides together in one place.',
                    ),
                    const SizedBox(height: 48),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _audienceCard(
                          label: 'For clients',
                          title: 'Need creative talent?',
                          body: 'Find people for your event, project or production. Explore their services, pricing and profiles, then start a booking.',
                          button: 'Find Talent',
                          onPressed: () => context.go('/search'),
                        ),
                        _audienceCard(
                          label: 'For artists',
                          title: 'Turn your skill into opportunity.',
                          body: 'Create your profile, list what you offer and make your services discoverable to people looking to book.',
                          button: 'Create Artist Profile',
                          onPressed: () => context.go('/join'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Services
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(40, 90, 40, 100),
                color: _slate900,
                child: Column(
                  children: [
                    _sectionTitle(
                      'What can you book?',
                      'Creative services for real work.',
                      'From events and productions to music and visual work, discover creative professionals offering services through Gearsh.',
                    ),
                    const SizedBox(height: 48),
                    Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      alignment: WrapAlignment.center,
                      children: [
                        _serviceCard('DJs', 'Book DJs for events and performances.', Icons.music_note_rounded),
                        _serviceCard('Photography', 'Find photographers for your next shoot or event.', Icons.camera_alt_rounded),
                        _serviceCard('Videography', 'Book video professionals for projects and events.', Icons.videocam_rounded),
                        _serviceCard('Music', 'Connect with musicians, producers and other music talent.', Icons.graphic_eq_rounded),
                        _serviceCard('MCs & Hosts', 'Find presenters and MCs for your event.', Icons.mic_external_on_rounded),
                        _serviceCard('More creative work', 'Explore other creative professionals and services.', Icons.auto_awesome_rounded),
                      ],
                    ),
                    const SizedBox(height: 36),
                    _button(
                      label: 'Explore Talent',
                      onPressed: () => context.go('/search'),
                    ),
                  ],
                ),
              ),

              // How it works
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 100, 40, 110),
                child: Column(
                  children: [
                    _sectionTitle(
                      'How it works',
                      'From discovery to delivery.',
                      'Gearsh is designed to make the journey from finding the right creative professional to completing the booking clearer and easier.',
                    ),
                    const SizedBox(height: 42),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _step(1, 'Discover', 'Find artists and creative services that fit what you need.'),
                          _step(2, 'Book', 'Choose the service and start the booking with the creative professional.'),
                          _step(3, 'Agree', 'Confirm the details and booking terms.'),
                          _step(4, 'Pay', 'Complete payment through the booking journey.'),
                          _step(5, 'Deliver', 'The creative professional delivers the agreed service.'),
                          _step(6, 'Review', 'Complete the booking and leave a genuine review where applicable.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Artist CTA
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(56),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _sky500.withValues(alpha: 0.18),
                      _cyan500.withValues(alpha: 0.07),
                    ],
                  ),
                  border: Border.all(color: _sky500.withValues(alpha: 0.18)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'FOR CREATIVES',
                      style: TextStyle(
                        color: _sky400,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your skill deserves to be discoverable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Text(
                        'Build your profile, list your services and make it easier for clients to find and book you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 17,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _button(
                      label: 'Join Gearsh',
                      onPressed: () => context.go('/join'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 110),

              // Vision
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _sectionTitle(
                      'The bigger picture',
                      'A more connected creative economy.',
                      'Gearsh is being built from Africa with a bigger ambition: make it easier for creative talent and opportunity to find each other, wherever they are.',
                    ),
                    const SizedBox(height: 32),
                    _button(
                      label: 'About Gearsh',
                      primary: false,
                      onPressed: () => context.go('/about'),
                    ),
                  ],
                ),
              ),

              // Footer
              const SizedBox(height: 100),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 18,
                  children: [
                    Text(
                      '© 2026 Gearsh. All rights reserved.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _navLink('Privacy', () => context.go('/privacy-policy')),
                        _navLink('Terms', () => context.go('/terms')),
                        _navLink('FAQ', () => context.go('/faq')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
