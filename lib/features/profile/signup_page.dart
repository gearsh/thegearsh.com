import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/screens/terms_of_service_page.dart';
import 'package:gearsh_app/screens/privacy_policy_page.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/providers/auth_providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _countryController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _userType;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String? _error;
  bool _success = false;
  int _currentStep = 0;

  late AnimationController _floatingGlowController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _cyan400 = Color(0xFF22D3EE);

  final List<String> _skillOptions = [
    'DJ', 'Producer', 'Writer', 'Photographer', 'Designer', 'Videographer',
    'Dancer', 'Host', 'Influencer', 'Stylist', 'Rapper', 'Director', 'Actor',
    'Model', 'Engineer', 'Animator', 'Choreographer', 'Make Up Artist',
    'Mural Artist', 'Painter', 'Graphic Designer', 'Sculptor', 'Singer',
    'Musician', 'Band', 'Comedian', 'MC', 'Publicist',
  ];
  final List<String> _selectedSkills = [];
  final List<String> _customSkills = []; // User-added custom skills
  final TextEditingController _customSkillController = TextEditingController();
  bool _showSkillDropdown = false;

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

    _pageController = PageController();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _countryController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customSkillController.dispose();
    _floatingGlowController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSkillDropdown() {
    setState(() => _showSkillDropdown = !_showSkillDropdown);
  }

  void _selectSkill(String skill, bool selected) {
    setState(() {
      if (selected) {
        _selectedSkills.add(skill);
      } else {
        _selectedSkills.remove(skill);
      }
    });
  }

  void _addCustomSkill() {
    final skill = _customSkillController.text.trim();
    if (skill.isNotEmpty &&
        !_skillOptions.contains(skill) &&
        !_customSkills.contains(skill)) {
      setState(() {
        _customSkills.add(skill);
        _selectedSkills.add(skill);
        _customSkillController.clear();
      });
    }
  }

  void _removeCustomSkill(String skill) {
    setState(() {
      _customSkills.remove(skill);
      _selectedSkills.remove(skill);
    });
  }

  void _showAddCustomSkillDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _sky500.withAlpha(51)),
        ),
        title: const Text(
          'Add Custom Skill',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Can\'t find your skill? Add it here!',
              style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customSkillController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Beatboxer, Graffiti Artist...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(77)),
                filled: true,
                fillColor: _slate800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _sky500),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _customSkillController.clear();
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withAlpha(153)),
            ),
          ),
          TextButton(
            onPressed: () {
              _addCustomSkill();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Add Skill',
              style: TextStyle(color: _sky400, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (_currentStep == 1) {
      // Step 2: Profile Details - ensure user type is selected
      if (_userType == null) {
        setState(() => _error = 'Please select how you want to join Gearsh');
        return;
      }
      if (_countryController.text.isEmpty || _locationController.text.isEmpty) {
        setState(() => _error = 'Please enter your country and city');
        return;
      }
    }

    setState(() => _error = null);

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _error = 'Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
        _success = false;
      });

      try {
        // Use Firebase Auth for signup
        final result = await ref.read(authControllerProvider).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _userNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _surnameController.text.trim(),
        );

        if (!mounted) return;

        if (result.success && result.user != null) {
          // Log in the user with their info
          final fullName = '${_firstNameController.text.trim()} ${_surnameController.text.trim()}';
          final email = _emailController.text.trim();

          // Map user type selection to UserRole
          UserRole role;
          switch (_userType?.toLowerCase()) {
            case 'artist':
              role = UserRole.artist;
              break;
            case 'fan':
              role = UserRole.fan;
              break;
            case 'client':
            default:
              role = UserRole.client;
              break;
          }

          userRoleService.login(
            role: role,
            name: fullName,
            email: email,
          );

          // Also send additional profile data to Cloudflare backend
          await _saveAdditionalProfileData();

          setState(() {
            _success = true;
            _isLoading = false;
          });

          // Navigate to appropriate page after short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              switch (role) {
                case UserRole.artist:
                  // Artists go to their dashboard to set up their profile
                  context.go('/dashboard');
                case UserRole.fan:
                  // Fans go to discover artists
                  context.go('/');
                case UserRole.client:
                  // Clients go to browse and book artists
                  context.go('/');
              }
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = result.error ?? 'Failed to sign up. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Something went wrong. Please try again later.';
        });
        debugPrint('Signup error: $e');
      }
    }
  }

  /// Sign up with Google
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authControllerProvider).signInWithGoogle();

      if (!mounted) return;

      if (result.success && result.user != null) {
        userRoleService.login(
          role: UserRole.client, // Default to client for social signup
          name: result.user!.displayName ?? result.user!.email?.split('@').first ?? 'User',
          email: result.user!.email ?? '',
        );

        context.go('/');
      } else {
        setState(() {
          _error = result.error ?? 'Failed to sign up with Google';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to sign up with Google';
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  /// Sign up with Apple
  Future<void> _signUpWithApple() async {
    setState(() {
      _isAppleLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authControllerProvider).signInWithApple();

      if (!mounted) return;

      if (result.success && result.user != null) {
        userRoleService.login(
          role: UserRole.client, // Default to client for social signup
          name: result.user!.displayName ?? result.user!.email?.split('@').first ?? 'User',
          email: result.user!.email ?? '',
        );

        context.go('/');
      } else {
        setState(() {
          _error = result.error ?? 'Failed to sign up with Apple';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to sign up with Apple';
      });
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  /// Save additional profile data to Cloudflare backend
  Future<void> _saveAdditionalProfileData() async {
    try {
      const apiBaseUrl = 'https://thegearsh-com.pages.dev/api/update-profile';

      final user = ref.read(currentFirebaseUserProvider);
      if (user == null) return;

      final idToken = await user.getIdToken();

      await http.post(
        Uri.parse(apiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'firebase_uid': user.uid,
          'user_type': _userType,
          'contact_number': _contactNumberController.text.trim(),
          'country': _countryController.text.trim(),
          'location': _locationController.text.trim(),
          'skill_set': _selectedSkills.join(', '),
          'date_of_birth': _dateOfBirth?.toIso8601String(),
          'gender': _gender,
        }),
      ).timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('Failed to save additional profile data: $e');
      // Don't fail signup if this fails - the basic user was created
    }
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
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _currentStep > 0 ? _prevStep : () {
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
                              child: Icon(
                                _currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          // Step indicator
                          Row(
                            children: List.generate(3, (index) => _buildStepIndicator(index)),
                          ),
                          const SizedBox(width: 46), // Balance the layout
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_sky400, _cyan400],
                      ).createShader(bounds),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getStepTitle(),
                      style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Form pages
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1(),
                            _buildStep2(),
                            _buildStep3(),
                          ],
                        ),
                      ),
                    ),

                    // Bottom section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          // Error message
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
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

                          // Success message
                          if (_success)
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withAlpha(77)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.green.withAlpha(204), size: 20),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Account created successfully!',
                                      style: TextStyle(color: Colors.green, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Continue button
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : (_currentStep == 2 ? _signUp : _nextStep),
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
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _currentStep == 2 ? 'Create Account' : 'Continue',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _currentStep == 2
                                                ? Icons.check_rounded
                                                : Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Or divider
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: _sky500.withAlpha(38))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13),
                                ),
                              ),
                              Expanded(child: Container(height: 1, color: _sky500.withAlpha(38))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Social signup buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  label: 'Google',
                                  isLoading: _isGoogleLoading,
                                  onTap: _signUpWithGoogle,
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
                                    onTap: _signUpWithApple,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Sign in link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Step 1: Basic Information';
      case 1:
        return 'Step 2: Profile Details';
      case 2:
        return 'Step 3: Security';
      default:
        return '';
    }
  }

  Widget _buildStepIndicator(int index) {
    final isActive = _currentStep >= index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isActive ? const LinearGradient(colors: [_sky500, _cyan500]) : null,
        color: isActive ? null : _slate800,
        boxShadow: isActive
            ? [BoxShadow(color: _sky500.withAlpha(102), blurRadius: 8, spreadRadius: 0)]
            : null,
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TextFormField(
            controller: _userNameController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration('Username', prefixIcon: Icons.alternate_email_rounded),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration('First Name', prefixIcon: Icons.person_outline_rounded),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _surnameController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration('Surname'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration('Email', prefixIcon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactNumberController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration('Phone Number', prefixIcon: Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User type selection cards
          Text(
            'I am joining as a...',
            style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildUserTypeCard(
            type: 'Artist',
            icon: Icons.mic_external_on_rounded,
            description: 'I want to get booked for gigs and showcase my talent',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 10),
          _buildUserTypeCard(
            type: 'Client',
            icon: Icons.event_rounded,
            description: 'I want to book artists for events and projects',
            color: _sky500,
          ),
          const SizedBox(height: 10),
          _buildUserTypeCard(
            type: 'Fan',
            icon: Icons.favorite_rounded,
            description: 'I want to discover and follow amazing artists',
            color: const Color(0xFFEC4899),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _countryController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration('Country', prefixIcon: Icons.public_rounded),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration('City'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          // Only show skills if Artist is selected
          if (_userType == 'Artist') ...[
            const SizedBox(height: 16),
            // Skills multi-select
            Text(
              'Skills (select all that apply)',
              style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _toggleSkillDropdown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: _slate800.withAlpha(128),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _sky500.withAlpha(51), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _sky400.withAlpha(179), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedSkills.isEmpty ? 'Select skills...' : _selectedSkills.join(', '),
                        style: TextStyle(
                          color: _selectedSkills.isEmpty ? Colors.white.withAlpha(128) : Colors.white,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showSkillDropdown ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.expand_more_rounded, color: Colors.white.withAlpha(128)),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: _slate800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _sky500.withAlpha(51)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom skills (user-added)
                      if (_customSkills.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Your Custom Skills',
                            style: TextStyle(
                              color: _cyan400,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _customSkills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeCustomSkill(skill),
                                    child: const Icon(Icons.close, color: Colors.white70, size: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: _sky500.withAlpha(51), height: 1),
                        const SizedBox(height: 12),
                      ],
                      // Predefined skills
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Add Custom Skill button
                          GestureDetector(
                            onTap: _showAddCustomSkillDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _cyan400, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, color: _cyan400, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add Custom',
                                    style: TextStyle(
                                      color: _cyan400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Predefined skill options
                          ..._skillOptions.map((skill) {
                            final isSelected = _selectedSkills.contains(skill);
                            return GestureDetector(
                              onTap: () => _selectSkill(skill, !isSelected),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(colors: [_sky500, _cyan500])
                                      : null,
                                  color: isSelected ? null : _slate900,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : _sky500.withAlpha(51),
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white.withAlpha(179),
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              crossFadeState: _showSkillDropdown ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
          const SizedBox(height: 16),
          // Date of birth
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000, 1, 1),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: _sky500,
                      onPrimary: Colors.white,
                      surface: _slate800,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _slate800.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _sky500.withAlpha(51), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: _sky400.withAlpha(179), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _dateOfBirth == null
                        ? 'Date of Birth'
                        : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                    style: TextStyle(
                      color: _dateOfBirth == null ? Colors.white.withAlpha(128) : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gender dropdown
          _buildDropdownField(
            label: 'Gender',
            value: _gender,
            icon: Icons.person_outline_rounded,
            items: ['Male', 'Female', 'Other', 'Prefer not to say'],
            onChanged: (v) => setState(() => _gender = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Password requirements info
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
                    'Password must be at least 6 characters long',
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
          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'By creating an account, you agree to our ',
                    style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: _sky400,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsOfServicePage(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: _sky400,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String type,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    final isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(26) : _slate800.withAlpha(128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : _sky500.withAlpha(51),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withAlpha(51),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(51) : _slate900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white.withAlpha(153),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withAlpha(204),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.white.withAlpha(77),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _slate800.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(51), width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _sky400.withAlpha(179), size: 20),
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
        ),
        dropdownColor: _slate800,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        icon: Icon(Icons.expand_more_rounded, color: Colors.white.withAlpha(128)),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Required' : null,
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
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

