import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  final String? token;
  final String? email;

  const ResetPasswordPage({
    super.key,
    this.token,
    this.email,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _error;
  bool _success = false;
  bool _tokenValid = true;

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

    // Validate token on init
    if (widget.token == null || widget.email == null) {
      _tokenValid = false;
    } else {
      _validateToken();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _floatingGlowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    try {
      const apiBaseUrl = 'https://thegearsh-com.pages.dev/api/validate-reset-token';
      final response = await http.post(
        Uri.parse(apiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': widget.token,
          'email': widget.email,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        setState(() => _tokenValid = false);
      }
    } catch (e) {
      // If validation fails, still allow attempt - server will validate again
      debugPrint('Token validation error: $e');
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _error = 'Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        const apiBaseUrl = 'https://thegearsh-com.pages.dev/api/reset-password';

        final response = await http.post(
          Uri.parse(apiBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'token': widget.token,
            'email': widget.email,
            'password': _passwordController.text.trim(),
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          setState(() {
            _success = true;
            _isLoading = false;
          });
        } else if (response.statusCode == 400 || response.statusCode == 404) {
          String errorMessage = 'Invalid or expired reset link.';
          try {
            final body = jsonDecode(response.body);
            if (body['error'] != null) {
              errorMessage = body['error'];
            }
          } catch (_) {}

          setState(() {
            _isLoading = false;
            _error = errorMessage;
            _tokenValid = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Failed to reset password. Please try again.';
          });
        }
      } on TimeoutException {
        setState(() {
          _isLoading = false;
          _error = 'Connection timed out. Please try again.';
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Something went wrong. Please try again.';
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
            ..._buildFloatingGlows(screenWidth, screenHeight),
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
                            ),
                          ],
                        ),
                        child: Icon(
                          _success
                              ? Icons.check_circle_rounded
                              : !_tokenValid
                                  ? Icons.error_outline_rounded
                                  : Icons.lock_reset_rounded,
                          color: _success
                              ? Colors.green
                              : !_tokenValid
                                  ? Colors.red.withAlpha(204)
                                  : _sky400,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: _success
                              ? [Colors.green, Colors.green.shade300]
                              : !_tokenValid
                                  ? [Colors.red.shade400, Colors.red.shade300]
                                  : [_sky400, _cyan400],
                        ).createShader(bounds),
                        child: Text(
                          _success
                              ? 'Password Reset!'
                              : !_tokenValid
                                  ? 'Invalid Link'
                                  : 'Reset Password',
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
                          _success
                              ? 'Your password has been successfully reset. You can now sign in with your new password.'
                              : !_tokenValid
                                  ? 'This password reset link is invalid or has expired. Please request a new one.'
                                  : 'Enter your new password below. Make sure it\'s at least 6 characters long.',
                          style: TextStyle(
                            color: Colors.white.withAlpha(128),
                            fontSize: 15,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),

                      if (_success) ...[
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
                              const Expanded(
                                child: Text(
                                  'Password changed successfully!',
                                  style: TextStyle(color: Colors.green, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildPrimaryButton(
                          'Sign In',
                          Icons.login_rounded,
                          () => context.go('/login'),
                        ),
                      ] else if (!_tokenValid) ...[
                        // Invalid token state
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withAlpha(77)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.withAlpha(204), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This link has expired or is invalid.',
                                  style: TextStyle(color: Colors.red.withAlpha(230), fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildPrimaryButton(
                          'Request New Link',
                          Icons.refresh_rounded,
                          () => context.go('/forgot-password'),
                        ),
                      ] else ...[
                        // Password form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Password requirements
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: _sky500.withAlpha(25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _sky500.withAlpha(51)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: _sky400, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Password must be at least 6 characters',
                                        style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: _inputDecoration('New Password', prefixIcon: Icons.lock_outline_rounded).copyWith(
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                    child: Icon(
                                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.white.withAlpha(128),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: _inputDecoration('Confirm Password', prefixIcon: Icons.lock_outline_rounded).copyWith(
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                                    child: Icon(
                                      _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.white.withAlpha(128),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v != _passwordController.text) return 'Passwords do not match';
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

                              // Reset button
                              GestureDetector(
                                onTap: _isLoading ? null : _resetPassword,
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
                                                'Reset Password',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                            ],
                                          ),
                                  ),
                                ),
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

  Widget _buildPrimaryButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
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

