import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _emailSent = false;

  late AnimationController _floatingGlowController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _cyan400 = Color(0xFF22D3EE);

  @override
  void initState() {
    super.initState();
    _floatingGlowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _floatingGlowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final email = _emailController.text.trim();

      try {
        // API base URL - use pages.dev URL (Cloudflare Pages)
        const apiBaseUrl = 'https://thegearsh-com.pages.dev/api/forgot-password';

        final uri = Uri.parse(apiBaseUrl);

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'email': email}),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _emailSent = true;
            _isLoading = false;
          });
        } else if (response.statusCode == 404) {
          setState(() {
            _isLoading = false;
            _error = 'No account found with this email address.';
          });
        } else {
          String errorMessage = 'Failed to send reset email. Please try again.';
          try {
            final body = jsonDecode(response.body);
            if (body['error'] != null) {
              errorMessage = body['error'];
            }
          } catch (_) {}

          setState(() {
            _isLoading = false;
            _error = errorMessage;
          });
        }
      } on TimeoutException {
        setState(() {
          _isLoading = false;
          _error = 'Connection timed out. Please check your internet and try again.';
        });
      } on http.ClientException {
        setState(() {
          _isLoading = false;
          _error = 'Connection failed. Please check your internet connection.';
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Something went wrong. Please try again later.';
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: _slate800.withAlpha(128),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _sky400.withAlpha(179), size: 20)
          : null,
      labelStyle: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: _sky400, fontWeight: FontWeight.w500),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _sky500.withAlpha(51), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _sky500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withAlpha(128), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Stack(
          children: [
            // Animated floating glows
            ..._buildFloatingGlows(screenWidth, screenHeight),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _sky500.withAlpha(51)),
                              color: _slate800.withAlpha(77),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _sky500.withAlpha(77), width: 2),
                          color: _slate800.withAlpha(128),
                          boxShadow: [
                            BoxShadow(
                              color: _sky500.withAlpha(51),
                              blurRadius: 30,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _emailSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                          color: _sky400,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_sky400, _cyan400],
                        ).createShader(bounds),
                        child: Text(
                          _emailSent ? 'Check Your Email' : 'Forgot Password?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _emailSent
                              ? 'We\'ve sent a password reset link to ${_emailController.text.trim()}. Check your inbox and follow the instructions.'
                              : 'No worries! Enter your email address and we\'ll send you a link to reset your password.',
                          style: TextStyle(
                            color: Colors.white.withAlpha(128),
                            fontSize: 15,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),

                      if (_emailSent) ...[
                        // Success state
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withAlpha(77)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green.withAlpha(204), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Reset link sent successfully!',
                                  style: TextStyle(color: Colors.green.withAlpha(230), fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Resend button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _emailSent = false;
                            });
                          },
                          child: Text(
                            'Didn\'t receive the email? Send again',
                            style: TextStyle(
                              color: _sky400.withAlpha(204),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Back to login button
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _sky500.withAlpha(77),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: _inputDecoration('Email Address', prefixIcon: Icons.email_outlined),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Error message
                              if (_error != null)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.withAlpha(77)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red.withAlpha(204), size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(color: Colors.red.withAlpha(230), fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Send button
                              GestureDetector(
                                onTap: _isLoading ? null : _sendResetEmail,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _sky500.withAlpha(77),
                                        blurRadius: 20,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Send Reset Link',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Back to login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Remember your password? ',
                                    style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [_sky400, _cyan400],
                                      ).createShader(bounds),
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingGlows(double screenWidth, double screenHeight) {
    return [
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            top: -100 + (30 * math.sin(value * math.pi)),
            right: -80 + (20 * math.cos(value * math.pi)),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _sky500.withAlpha(40),
                    _sky500.withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            bottom: -120 + (25 * math.cos(value * math.pi)),
            left: -100 + (35 * math.sin(value * math.pi)),
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyan500.withAlpha(35),
                    _cyan500.withAlpha(10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }
}

