import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/providers/auth_providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  final String? initialRole;
  final String? initialTier;
  const SignupPage({super.key, this.initialRole, this.initialTier});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage>
    with SingleTickerProviderStateMixin {

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
  String? _error;
  bool _success = false;
  int _currentStep = 0;
  String _selectedTier = 'basic';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late PageController _pageController;

  // ── Palette ─────────────────────────────────────────────
  static const Color _bg      = Color(0xFF020617);
  static const Color _bg2     = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF111827);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky     = Color(0xFF0EA5E9);
  static const Color _skyL    = Color(0xFF38BDF8);
  static const Color _cyan    = Color(0xFF06B6D4);
  static const Color _border  = Color(0x12FFFFFF);
  static const Color _gold    = Color(0xFFF59E0B);
  static const Color _goldL   = Color(0xFFFBBF24);

  final List<String> _skillOptions = [
    'DJ', 'Producer', 'Writer', 'Photographer', 'Designer', 'Videographer',
    'Dancer', 'Host', 'Influencer', 'Stylist', 'Rapper', 'Director', 'Actor',
    'Model', 'Engineer', 'Animator', 'Choreographer', 'Make Up Artist',
    'Trap Star', 'Publicist',
  ];
  final List<String> _selectedSkills = [];
  bool _showSkillDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      final r = widget.initialRole!.toLowerCase();
      if (r == 'artist') {
        _userType = 'Artist';
      } else if (r == 'fan') {
        _userType = 'Fan';
      } else if (r == 'client' || r == 'booker') {
        _userType = 'Booker';
      } else {
        _userType = widget.initialRole;
      }
    }
    if (widget.initialTier != null) {
      _selectedTier = widget.initialTier!;
    }
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
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
    _fadeCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────
  Widget _click({required Widget child, VoidCallback? onTap}) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: child),
      );

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: _slate800.withAlpha(100),
      prefixIcon: icon != null
          ? Icon(icon, color: _skyL.withAlpha(140), size: 20)
          : null,
      labelStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _skyL, fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _sky, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.withAlpha(128), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  // ── Sign up logic ─────────────────────────────────────
  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _error = 'Passwords do not match');
        return;
      }

      setState(() { _isLoading = true; _error = null; _success = false; });

      try {
        final result = await ref.read(authControllerProvider).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _userNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _surnameController.text.trim(),
        );

        if (!mounted) return;

        if (result.success && result.user != null) {
          final fullName = '${_firstNameController.text.trim()} ${_surnameController.text.trim()}';
          final email = _emailController.text.trim();
          final role = _userType?.toLowerCase() == 'artist' ? UserRole.artist : UserRole.client;

          userRoleService.login(role: role, name: fullName, email: email);
          await _saveAdditionalProfileData();

          setState(() { _success = true; _isLoading = false; });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go(role == UserRole.artist ? '/dashboard' : '/');
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
          'subscription_tier': _selectedTier,
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
    }
  }

  // ── BUILD ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStepIndicators(),
                    const SizedBox(height: 28),
                    if (_userType == 'Artist' && _selectedTier != 'basic')
                      _buildTierBadge(),
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
                    _buildBottom(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────
  Widget _buildHeader() => Row(
    children: [
      _click(
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
            color: _surface,
          ),
          child: Icon(
            _currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
            color: Colors.white, size: 20,
          ),
        ),
      ),
      const Spacer(),
      Text('THE GEARSH',
        style: TextStyle(
          fontFamily: 'Syne', fontSize: 12,
          fontWeight: FontWeight.w700, letterSpacing: 3,
          color: Colors.white.withAlpha(60),
        ),
      ),
      const Spacer(),
      const SizedBox(width: 42),
    ],
  );

  // ── STEP INDICATORS ───────────────────────────────────
  Widget _buildStepIndicators() {
    const labels = ['Account', 'Profile', 'Security'];
    return Row(
      children: List.generate(3, (i) {
        final isActive = _currentStep >= i;
        final isCurrent = _currentStep == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: isActive
                        ? const LinearGradient(colors: [_sky, _cyan])
                        : null,
                    color: isActive ? null : _slate800.withAlpha(128),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent
                        ? _skyL
                        : Colors.white.withAlpha(isActive ? 90 : 40),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── TIER BADGE ────────────────────────────────────────
  Widget _buildTierBadge() {
    final isPremium = _selectedTier == 'premium';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isPremium ? _gold.withAlpha(15) : _sky.withAlpha(15),
        border: Border.all(
          color: isPremium ? _gold.withAlpha(64) : _sky.withAlpha(64),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.star_rounded : Icons.verified,
            size: 16,
            color: isPremium ? _goldL : _skyL,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedTier[0].toUpperCase()}${_selectedTier.substring(1)} plan \u00b7 ${_selectedTier == 'standard' ? 'R500/mo' : 'R5 000/mo'}',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isPremium ? _goldL : _skyL,
            ),
          ),
          const SizedBox(width: 12),
          _click(
            onTap: () => context.go('/join?tier=$_selectedTier'),
            child: Text('Change',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha(80),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withAlpha(80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1 — Account ──────────────────────────────────
  Widget _buildStep1() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading('Basic information', 'Let\'s get you set up on The Gearsh.'),
        const SizedBox(height: 24),
        _card(children: [
          TextFormField(
            controller: _userNameController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDeco('Username', icon: Icons.alternate_email_rounded),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _firstNameController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDeco('First Name', icon: Icons.person_outline_rounded),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _surnameController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDeco('Surname'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            )),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDeco('Email', icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _contactNumberController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDeco('Phone Number', icon: Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ]),
      ],
    ),
  );

  // ── STEP 2 — Profile ──────────────────────────────────
  Widget _buildStep2() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading('Profile details', 'Tell us about yourself so clients can find you.'),
        const SizedBox(height: 24),
        _card(children: [
          _dropdownField(
            label: 'I am a...', value: _userType,
            icon: Icons.badge_outlined,
            items: ['Booker', 'Artist', 'Fan'],
            onChanged: (v) => setState(() => _userType = v),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _countryController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDeco('Country', icon: Icons.public_rounded),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDeco('City'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            )),
          ]),
          const SizedBox(height: 14),
          _buildSkillsSelector(),
          const SizedBox(height: 14),
          _buildDatePicker(),
          const SizedBox(height: 14),
          _dropdownField(
            label: 'Gender', value: _gender,
            icon: Icons.person_outline_rounded,
            items: ['Male', 'Female', 'Other', 'Prefer not to say'],
            onChanged: (v) => setState(() => _gender = v),
          ),
        ]),
      ],
    ),
  );

  // ── STEP 3 — Security ─────────────────────────────────
  Widget _buildStep3() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading('Set your password', 'Keep your account secure.'),
        const SizedBox(height: 24),
        _card(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _sky.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sky.withAlpha(40)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: _skyL, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Password must be at least 6 characters',
                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDeco('Password', icon: Icons.lock_outline_rounded).copyWith(
              suffixIcon: _click(
                onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                child: Icon(
                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white.withAlpha(100), size: 20,
                ),
              ),
            ),
            validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDeco('Confirm Password', icon: Icons.lock_outline_rounded).copyWith(
              suffixIcon: _click(
                onTap: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                child: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white.withAlpha(100), size: 20,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) { return 'Required'; }
              if (v != _passwordController.text) { return 'Passwords do not match'; }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky, _cyan]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(child: Wrap(children: [
                Text('By creating an account, you agree to our ',
                  style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
                _click(
                  onTap: () => context.go('/terms'),
                  child: const Text('Terms of Service',
                    style: TextStyle(color: _skyL, fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: _skyL))),
                Text(' and ',
                  style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
                _click(
                  onTap: () => context.go('/privacy-policy'),
                  child: const Text('Privacy Policy',
                    style: TextStyle(color: _skyL, fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: _skyL))),
              ])),
            ],
          ),
        ]),
      ],
    ),
  );

  // ── BOTTOM ────────────────────────────────────────────
  Widget _buildBottom() => Column(children: [
    if (_error != null)
      _banner(_error!, Colors.red, Icons.error_outline),
    if (_success)
      _banner('Account created successfully!', Colors.green, Icons.check_circle_outline),
    _click(
      onTap: _isLoading ? null : (_currentStep == 2 ? _signUp : _nextStep),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_sky, _cyan]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _sky.withAlpha(40), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_currentStep == 2 ? 'Create Account' : 'Continue',
                      style: const TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    const SizedBox(width: 8),
                    Icon(_currentStep == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                  ]),
        ),
      ),
    ),
    const SizedBox(height: 16),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ',
          style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13)),
        _click(
          onTap: () => context.go('/login'),
          child: const Text('Sign in',
            style: TextStyle(color: _skyL, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  ]);

  // ── SHARED ────────────────────────────────────────────

  Widget _stepHeading(String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(
        fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700,
        color: Colors.white, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      Text(sub, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w300,
        color: Colors.white.withAlpha(100), height: 1.5)),
    ],
  );

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _banner(String text, Color c, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: c.withAlpha(20), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withAlpha(64)),
    ),
    child: Row(children: [
      Icon(icon, color: c.withAlpha(200), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(color: c.withAlpha(220), fontSize: 13))),
    ]),
  );

  Widget _buildSkillsSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Skills', style: TextStyle(
        color: Colors.white.withAlpha(140), fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      _click(
        onTap: () => setState(() => _showSkillDropdown = !_showSkillDropdown),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _slate800.withAlpha(100), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Icon(Icons.auto_awesome_rounded, color: _skyL.withAlpha(140), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _selectedSkills.isEmpty ? 'Select skills...' : _selectedSkills.join(', '),
              style: TextStyle(
                color: _selectedSkills.isEmpty ? Colors.white.withAlpha(100) : Colors.white,
                fontSize: 14),
              overflow: TextOverflow.ellipsis)),
            AnimatedRotation(
              turns: _showSkillDropdown ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, color: Colors.white.withAlpha(80), size: 20)),
          ]),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxHeight: 160),
          decoration: BoxDecoration(
            color: _bg2, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border)),
          child: SingleChildScrollView(
            child: Wrap(spacing: 6, runSpacing: 6, children: _skillOptions.map((skill) {
              final sel = _selectedSkills.contains(skill);
              return _click(
                onTap: () => setState(() {
                  if (sel) { _selectedSkills.remove(skill); }
                  else { _selectedSkills.add(skill); }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: sel ? const LinearGradient(colors: [_sky, _cyan]) : null,
                    color: sel ? null : _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? Colors.transparent : _border)),
                  child: Text(skill, style: TextStyle(
                    color: sel ? Colors.white : Colors.white.withAlpha(160),
                    fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList()),
          ),
        ),
        crossFadeState: _showSkillDropdown ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ],
  );

  Widget _buildDatePicker() => _click(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2000, 1, 1),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _sky, onPrimary: Colors.white,
              surface: _bg2, onSurface: Colors.white)),
          child: child!),
      );
      if (picked != null) { setState(() => _dateOfBirth = picked); }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _slate800.withAlpha(100), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border)),
      child: Row(children: [
        Icon(Icons.calendar_today_rounded, color: _skyL.withAlpha(140), size: 18),
        const SizedBox(width: 10),
        Text(_dateOfBirth == null ? 'Date of Birth'
            : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
          style: TextStyle(
            color: _dateOfBirth == null ? Colors.white.withAlpha(100) : Colors.white,
            fontSize: 14)),
      ]),
    ),
  );

  Widget _dropdownField({
    required String label, required String? value, required IconData icon,
    required List<String> items, required ValueChanged<String?> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    decoration: BoxDecoration(
      color: _slate800.withAlpha(100), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border)),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _skyL.withAlpha(140), size: 18),
        border: InputBorder.none, labelText: label,
        labelStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14)),
      dropdownColor: _bg2,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      icon: Icon(Icons.expand_more, color: Colors.white.withAlpha(80), size: 20),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    ),
  );
}
