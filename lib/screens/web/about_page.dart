import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacementNamed('/'),
                    child: Row(
                      children: [
                        Image.asset('assets/images/gearsh_logo.png', height: 48),
                        const SizedBox(width: 8),
                        const Text('Gearsh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    child: const Text('Home', style: TextStyle(color: Colors.tealAccent)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('About', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/images/allthestars.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                // Hero / Intro
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
                        ).createShader(rect),
                        child: const Text(
                          'About Gearsh',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Gearsh is the ultimate artist e-booking service — built for musicians, dancers, actors, painters, comedians, and creators of all kinds. Our mission is to give artists full control over their careers, connect them directly with bookers, and create a global community of artistry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Why Choose Gearsh
                Container(
                  color: Color(0xFF191919),
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
                        ).createShader(rect),
                        child: const Text(
                          'Why Choose Gearsh?',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _featureCard('Full Control', 'Manage your calendar, set your own rates, and accept bookings directly without middlemen.'),
                          _featureCard('Instant Visibility', 'Create a profile that showcases your work, and get discovered by fans and venues instantly.'),
                          _featureCard('Secure Payments', 'Perform with confidence — we ensure all transactions are secure and payments are instant.'),
                          _featureCard('Build Your Brand', 'Upload your best work, grow your audience, and make your artistry unforgettable.'),
                          _featureCard('Community of Creators', 'Join a vibrant network of artists collaborating and inspiring each other worldwide.'),
                        ],
                      ),
                    ],
                  ),
                ),
                // How It Works
                Container(
                  color: Color(0xFF101010),
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
                        ).createShader(rect),
                        child: const Text(
                          'How It Works',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _featureCard('1. Create Your Profile', 'Upload your bio, photos, videos, and showcase your talent in one digital portfolio.'),
                          _featureCard('2. Set Your Terms', 'Control your availability, performance rates, and preferences with ease.'),
                          _featureCard('3. Get Booked & Paid', 'Receive booking requests, confirm gigs, perform, and get paid — instantly.'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Call to Action
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)]),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(
                    children: [
                      const Text(
                        'Exclusive Pre-Launch Access',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Be among the first. The first 100 artists to sign up get early access and lifetime zero sign-up fees!',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: StadiumBorder(),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)]),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Join the Movement',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  color: Color(0xFF222222),
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 16,
                        children: [
                          _footerSection('Gearsh', ['Visit Help Center']),
                          _footerSection('Company', ['About us', 'Our offerings', 'Newsroom', 'Investors', 'Blog', 'Careers']),
                          _footerSection('Products', ['Book an Artist', 'Gear Sharing', 'Events', 'Merchandise', 'Gearsh for Business', 'Gift Cards']),
                          _footerSection('Global Citizenship', ['Safety', 'Sustainability', 'Travel']),
                          _footerSection('Reserve', ['Book Talent', 'Venues', 'Cities']),
                        ],
                      ),
                      Divider(color: Colors.grey[700], height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('English', style: TextStyle(color: Colors.grey[400])),
                              SizedBox(width: 16),
                              Text('Makhado, Limpopo', style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                          Row(
                            children: [
                              Text('© 2025 Gearsh Inc.', style: TextStyle(color: Colors.grey[400])),
                              SizedBox(width: 16),
                              Text('Privacy', style: TextStyle(color: Colors.grey[400])),
                              SizedBox(width: 16),
                              Text('Accessibility', style: TextStyle(color: Colors.grey[400])),
                              SizedBox(width: 16),
                              Text('Terms', style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _featureCard(String title, String description) {
    return Container(
      width: 260,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
          SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _footerSection(String heading, List<String> items) {
    return Container(
      margin: EdgeInsets.only(right: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(e, style: TextStyle(color: Colors.grey[400])),
          )),
        ],
      ),
    );
  }
}
