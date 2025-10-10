// Flutter version of your HTML landing page
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    const double headerHeight = 80;
    return Scaffold(
      backgroundColor: Color(0xFF111111),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: headerHeight),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Section
                  Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Color(0xFF00BFFF), // Deep Sky Blue, 1px high
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/allthestars.jpg'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                            child: Column(
                              children: [
                                Text(
                                  'The Manager in Your Pocket',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00BFFF), // Deep Sky Blue
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Connect directly with local artists, book talent for your event, and manage it all in one seamless experience.',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[300]),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF00BFFF), // Deep sky blue
                                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                        shape: StadiumBorder(),
                                      ),
                                      onPressed: () {
                                        context.go('/signup');
                                      },
                                      child: Text('Sign Up Now', style: TextStyle(color: Colors.white)),
                                    ),
                                    SizedBox(width: 16),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                        shape: StadiumBorder(),
                                        side: BorderSide(color: Colors.grey[700]!),
                                      ),
                                      onPressed: () {
                                        context.go('/login');
                                      },
                                      child: Text('Login', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Delayed Launch',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFEEEEEE)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                _buildCountdown(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Features Section
                  Container(
                    color: Color(0xFF1A1A1A),
                    padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Column(
                      children: [
                        Text('Features Designed for You', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _featureCard('Bookers', 'assets/images/icons/calendar.png', 'Discover and book verified local talent for your events with secure, in-app payments and transparent booking statuses.'),
                            _featureCard('Artists', 'assets/images/icons/art.png', 'Get discovered by bookers, manage your schedule, and get paid securely and instantly for your gigs.'),
                            _featureCard('Fans', 'assets/images/icons/superstar.png', 'Follow your favorite local artists, get notified about new gigs, and discover fresh talent in your area.'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Waitlist Section
                  Container(
                    color: Color(0xFF101010),
                    padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Column(
                      children: [
                        Text('Be An Early Adopter', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00BFFF))),
                        SizedBox(height: 16),
                        Text('Join our waitlist to get exclusive updates and early access to the Gearsh app when we launch.', style: TextStyle(color: Colors.grey[400])),
                        SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
                            hintStyle: TextStyle(color: Color(0xFF00BFFF)), // Deep Sky Blue
                            filled: true,
                            fillColor: Color(0xFF222222),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00BFFF), width: 1), // 1px Deep Sky Blue bar
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00BFFF), width: 1), // 1px Deep Sky Blue bar
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00BFFF), // Deep Sky Blue
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: StadiumBorder(),
                          ),
                          onPressed: _isLoading ? null : _registerUser,
                          child: _isLoading
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Sign Up'),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(_errorMessage!, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        if (_showMessage)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Thank you for joining the waitlist! We\'ll be in touch soon.', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gearsh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                Text('Visit Help Center', style: TextStyle(color: Colors.grey[400])),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Company', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ...['About us', 'Our offerings', 'Newsroom', 'Investors', 'Blog', 'Careers'].map((e) => Text(e, style: TextStyle(color: Colors.grey[400]))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Products', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ...['Book an Artist', 'Gear Sharing', 'Events', 'Merchandise', 'Gearsh for Business', 'Gift Cards'].map((e) => Text(e, style: TextStyle(color: Colors.grey[400]))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Global Citizenship', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ...['Safety', 'Sustainability', 'Travel'].map((e) => Text(e, style: TextStyle(color: Colors.grey[400]))),
                              ],
                            ),
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
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: headerHeight,
              color: const Color(0xFF111111),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          child: Row(
                            children: [
                              Image.asset('assets/images/gearsh_logo.png', height: 48),
                              const SizedBox(width: 8),
                              const Text('GEARSH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          child: const Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/about');
                          },
                          child: const Text('About', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.lightBlueAccent,
                            shadowColor: Colors.white,
                          ),
                          onPressed: () {
                            context.go('/signup');
                          },
                          child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    if (countdown.isNegative) {
      return Text('The Gearsh App is LIVE!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20));
    }
    final days = countdown.inDays;
    final hours = countdown.inHours % 24;
    final minutes = countdown.inMinutes % 60;
    final seconds = countdown.inSeconds % 60;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _countdownSegment(days, 'Days'),
        SizedBox(width: 8),
        _countdownSegment(hours, 'Hours'),
        SizedBox(width: 8),
        _countdownSegment(minutes, 'Minutes'),
        SizedBox(width: 8),
        _countdownSegment(seconds, 'Seconds'),
      ],
    );
  }

  Widget _countdownSegment(int value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black)), // Changed to black font
        ],
      ),
    );
  }

  Widget _featureCard(String title, String iconPath, String description) {
    return Container(
      width: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Image.asset(iconPath, height: 48),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00BFFF))), // Deep Sky Blue
          SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
