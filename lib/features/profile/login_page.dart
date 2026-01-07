import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/providers/auth_providers.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Username or Email
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String? _error;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AuthState>(authStateProvider, (previous, next) {
        if (next == AuthState.authenticated) {
          GoRouter.of(context).go('/dashboard');
        }
      });
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _floatingGlowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final identifier = _identifierController.text.trim(); // Username or email
      final password = _passwordController.text.trim();
      try {
        final result = await ref.read(authControllerProvider).signInWithEmail(identifier, password);
        if (!mounted) return;

        if (result.success && result.user != null) {
          // Determine display name
          final displayName = result.user!.displayName ??
              (identifier.contains('@') ? identifier.split('@').first : identifier);

          // Set user as logged in (not guest) with their current role
          userRoleService.login(
            role: userRoleService.currentRole,
            name: displayName,
            email: result.user!.email ?? identifier,
          );

          // Navigate based on role
          if (userRoleService.isArtist) {
            GoRouter.of(context).go('/dashboard');
          } else {
            GoRouter.of(context).go('/');
          }
        } else {
          setState(() {
            _error = result.error ?? 'Login failed';
          });
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authControllerProvider).signInWithGoogle();

      if (!mounted) return;

      if (result.cancelled) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      if (result.success && result.user != null) {
        final user = result.user!;

        // Set user as logged in
        userRoleService.login(
          role: UserRole.client, // Default role for social sign-in
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
        );

        // Navigate to home
        GoRouter.of(context).go('/');
      } else {
        setState(() {
          _error = result.error ?? 'Google sign-in failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Google sign-in failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isAppleLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authControllerProvider).signInWithApple();

      if (!mounted) return;

      if (result.cancelled) {
        setState(() => _isAppleLoading = false);
        return;
      }

      if (result.success && result.user != null) {
        final user = result.user!;

        // Set user as logged in
        userRoleService.login(
          role: UserRole.client, // Default role for social sign-in
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
        );

        // Navigate to home
        GoRouter.of(context).go('/');
      } else {
        setState(() {
          _error = result.error ?? 'Apple sign-in failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Apple sign-in failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
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
                          onTap: () {
                            try {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/onboarding');
                              }
                            } catch (e) {
                              context.go('/onboarding');
                            }
                          },
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
                      const SizedBox(height: 32),

                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _sky500.withAlpha(77), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _sky500.withAlpha(51),
                              blurRadius: 30,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/gearsh_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _slate800,
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: _sky400,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_sky400, _cyan400],
                        ).createShader(bounds),
                        child: const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue to Gearsh',
                        style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _identifierController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: _inputDecoration('Username or Email', prefixIcon: Icons.person_outline_rounded),
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Please enter your username or email' : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: _inputDecoration('Password', prefixIcon: Icons.lock_outline_rounded).copyWith(
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  child: Icon(
                                    _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.white.withAlpha(128),
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Please enter your password' : null,
                            ),
                            const SizedBox(height: 16),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.go('/forgot-password'),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: _sky400.withAlpha(204),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

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

                            // Login button
                            GestureDetector(
                              onTap: _isLoading ? null : _login,
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
                                              'Sign In',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Container(height: 1, color: _sky500.withAlpha(38))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 13),
                                  ),
                                ),
                                Expanded(child: Container(height: 1, color: _sky500.withAlpha(38))),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Social login buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSocialButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'Google',
                                    isLoading: _isGoogleLoading,
                                    onTap: _signInWithGoogle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Only show Apple button on iOS/macOS or web
                                if (!kIsWeb && Platform.isIOS || !kIsWeb && Platform.isMacOS || kIsWeb)
                                  Expanded(
                                    child: _buildSocialButton(
                                      icon: Icons.apple_rounded,
                                      label: 'Apple',
                                      isLoading: _isAppleLoading,
                                      onTap: _signInWithApple,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [_sky400, _cyan400],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Sign Up',
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
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
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

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _slate800.withAlpha(128),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _sky500.withAlpha(51)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 14,
                fontWeight: FontWeight.w500,
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

