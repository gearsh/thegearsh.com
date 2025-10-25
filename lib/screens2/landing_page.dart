import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gearsh_app/widgets/custom_app_bar.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _showMessage = false;
  bool _isLoading = false;
  String? _errorMessage;
  late DateTime launchDate;
  Duration countdown = Duration();

  @override
  void initState() {
    super.initState();
    launchDate = DateTime.parse("2025-11-03T00:00:00Z");
    _updateCountdown();
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) setState(_updateCountdown);
      return true;
    });
  }

  void _updateCountdown() {
    final now = DateTime.now().toUtc();
    countdown = launchDate.difference(now);
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter your email.';
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://your-api-domain/signup'), // TODO: Replace with your actual endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _showMessage = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to sign up. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: ''),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                _buildHeroSection(theme),
                // Features Section
                _buildFeaturesSection(theme, isMobile),
                // Waitlist Section
                _buildWaitlistSection(theme),
                // Footer
                _buildFooter(theme, isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 1,
            color: theme.primaryColor,
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/allthestars.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Color.fromRGBO(0, 0, 0, 0.1), BlendMode.dstATop),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'The Manager in Your Pocket',
                    style: theme.textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Connect directly with local artists, book talent for your event, and manage it all in one seamless experience.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/dashboard'),
                        child: const Text('Manager Mode'),
                      ),
                      SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => context.go('/profile/1'),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Delayed Launch',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildCountdown(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ThemeData theme, bool isMobile) {
    final featureCards = [
      _featureCard(theme, 'Bookers', 'assets/images/icons/calendar.png', 'Discover and book verified local talent for your events with secure, in-app payments and transparent booking statuses.'),
      _featureCard(theme, 'Artists', 'assets/images/icons/art.png', 'Get discovered by bookers, manage your schedule, and get paid securely and instantly for your gigs.'),
      _featureCard(theme, 'Fans', 'assets/images/icons/superstar.png', 'Follow your favorite local artists, get notified about new gigs, and discover fresh talent in your area.'),
    ];

    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Text('Features Designed for You', style: theme.textTheme.displaySmall),
          SizedBox(height: 32),
          isMobile
              ? Column(children: featureCards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 16.0), child: card)).toList())
              : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: featureCards),
        ],
      ),
    );
  }

  Widget _buildWaitlistSection(ThemeData theme) {
    return Container(
      color: const Color(0xFF101010),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Text('Be An Early Adopter', style: theme.textTheme.displaySmall?.copyWith(color: theme.primaryColor)),
          SizedBox(height: 16),
          Text('Join our waitlist to get exclusive updates and early access to the Gearsh app when we launch.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
          SizedBox(height: 24),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(hintText: 'Enter your email address'),
            style: theme.textTheme.bodyMedium,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _registerUser,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sign Up'),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          if (_showMessage)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Thank you for joining the waitlist! We\'ll be in touch soon.', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isMobile) {
    final footerSections = [
      _footerSection(theme, 'Company', ['About us', 'Our offerings', 'Newsroom', 'Investors', 'Blog', 'Careers']),
      _footerSection(theme, 'Products', ['Book an Artist', 'Gear Sharing', 'Events', 'Merchandise', 'Gearsh for Business', 'Gift Cards']),
      _footerSection(theme, 'Global Citizenship', ['Safety', 'Sustainability', 'Travel']),
    ];

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: footerSections)
              : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: footerSections),
          Divider(color: Colors.grey[700], height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('English', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  SizedBox(width: 16),
                  Text('Makhado, Limpopo', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                ],
              ),
              Row(
                children: [
                  Text('© 2025 Gearsh Inc.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  SizedBox(width: 16),
                  Text('Privacy', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  SizedBox(width: 16),
                  Text('Accessibility', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  SizedBox(width: 16),
                  Text('Terms', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerSection(ThemeData theme, String title, List<String> links) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          ...links.map((link) => Text(link, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]))),
        ],
      ),
    );
  }

  Widget _buildCountdown(ThemeData theme) {
    if (countdown.isNegative) {
      return Text('The Gearsh App is LIVE!', style: theme.textTheme.headlineSmall);
    }
    final days = countdown.inDays;
    final hours = countdown.inHours % 24;
    final minutes = countdown.inMinutes % 60;
    final seconds = countdown.inSeconds % 60;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _countdownSegment(theme, days, 'Days'),
        SizedBox(width: 8),
        _countdownSegment(theme, hours, 'Hours'),
        SizedBox(width: 8),
        _countdownSegment(theme, minutes, 'Minutes'),
        SizedBox(width: 8),
        _countdownSegment(theme, seconds, 'Seconds'),
      ],
    );
  }

  Widget _countdownSegment(ThemeData theme, int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _featureCard(ThemeData theme, String title, String iconPath, String description) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Image.asset(iconPath, height: 48),
            SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor)),
            SizedBox(height: 4),
            Text(description, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
