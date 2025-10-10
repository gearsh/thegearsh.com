import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/global_providers.dart';
import '../../providers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _error;

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint ?? label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0x12FFFFFF),
      labelStyle: const TextStyle(color: Color(0xFF00d2ff), fontWeight: FontWeight.w600),
      floatingLabelStyle: const TextStyle(color: Color(0xFF00d2ff), fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00d2ff), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00d2ff), width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00d2ff)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and navigate if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AuthState>(authProvider, (previous, next) {
        if (next == AuthState.authenticated) {
          GoRouter.of(context).go('/dashboard');
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      try {
        await ref.read(authControllerProvider).signIn(email, password);
        if (!mounted) return;
        GoRouter.of(context).go('/dashboard');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/allthestars.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent, // fully transparent
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF00d2ff), width: 1.5),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 16)],
                ),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/gearsh_logo.png', height: 48),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
                        ).createShader(rect),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to your Gearsh account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Email'),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter password' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                _isLoading ? 'Logging In...' : 'Login',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 24),
                      const Divider(height: 32, thickness: 1.2, color: Color(0xFF23242A)),
                      TextButton(
                        onPressed: () {
                          GoRouter.of(context).go('/signup');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF00d2ff),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
