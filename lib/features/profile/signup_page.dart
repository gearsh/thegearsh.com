import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _userTypeController = TextEditingController();
  final _countryController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _error;
  bool _success = false;

  // 1. Use deep sky blue theme and structure from WaitlistFormPage
  // 2. Use multi-select for skill_set, dropdowns for user_type and gender, and grouped fields
  // 3. Use the same _inputDecoration helper for all fields
  // 4. Use a gradient button and similar layout

  final List<String> _skillOptions = [
    'DJ', 'Producer', 'Writer', 'Photographer', 'Designer', 'Videographer', 'Dancer', 'Host',
    'Influencer', 'Stylist', 'Rapper', 'Director', 'Actor', 'Model', 'Engineer', 'Animator',
    'Choreographer', 'Make Up Artist', 'Trap Star', 'Publicist'
  ];
  List<String> _selectedSkills = [];
  bool _showSkillDropdown = false;

  void _toggleSkillDropdown() {
    setState(() {
      _showSkillDropdown = !_showSkillDropdown;
    });
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

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint ?? label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0x12FFFFFF), // replaces Colors.white.withOpacity(0.07)
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
  void dispose() {
    _userNameController.dispose();
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _userTypeController.dispose();
    _countryController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Future<void> _signUp() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     final user = {
  //       'user_name': _userNameController.text.trim(),
  //       'first_name': _firstNameController.text.trim(),
  //       'surname': _surnameController.text.trim(),
  //       'email': _emailController.text.trim(),
  //       'contact_number': _contactNumberController.text.trim(),
  //       'user_type': _userTypeController.text.trim(),
  //       'country': _countryController.text.trim(),
  //       'location': _locationController.text.trim(),
  //       'skill_set': _selectedSkills.join(', '),
  //       'date_of_birth': _dateOfBirth?.toIso8601String(),
  //       'gender': _gender,
  //       'created_date': DateTime.now().toIso8601String(),
  //       'password': _passwordController.text.trim(),
  //     };
  //     setState(() {
  //       _isLoading = true;
  //       _error = null;
  //       _success = false;
  //     });
  //     try {
  //       final response = await http.post(
  //         Uri.parse('https://signup-worker.thegearsh.workers.dev/signup'),
  //         headers: {'Content-Type': 'application/json'},
  //         body: jsonEncode(user),
  //       );
  //       if (response.statusCode == 200) {
  //         setState(() {
  //           _success = true;
  //           _isLoading = false;
  //         });
  //       } else if (response.statusCode == 409) {
  //         setState(() {
  //           _isLoading = false;
  //           _error = 'Email already registered.';
  //         });
  //       } else {
  //         setState(() {
  //           _isLoading = false;
  //           _error = 'Failed to sign up. Please try again.';
  //         });
  //       }
  //     } catch (e) {
  //       setState(() {
  //         _isLoading = false;
  //         _error = 'Network error. Please try again.';
  //       });
  //     }
  //   }
  // }

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
                constraints: const BoxConstraints(maxWidth: 500),
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
                          'Sign Up',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your Gearsh account to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _userNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Username'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('First Name'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _surnameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Surname'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactNumberController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Contact Number'),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _userTypeController.text.isNotEmpty ? _userTypeController.text : null,
                        decoration: _inputDecoration('I am a...'),
                        items: [
                          const DropdownMenuItem(child: Text('-- Select User Type --'), value: null),
                          ...['Booker', 'Artist', 'Fan'].map((type) => DropdownMenuItem(child: Text(type), value: type)),
                        ],
                        onChanged: (v) => setState(() => _userTypeController.text = v ?? ''),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Country'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Location'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Skill Set (select all that apply)', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _toggleSkillDropdown,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.ease,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00d2ff)),
                            boxShadow: _showSkillDropdown
                              ? [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.15), blurRadius: 12, offset: Offset(0, 4))]
                              : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedSkills.isEmpty ? 'Select skills...' : _selectedSkills.join(', '),
                                  style: TextStyle(color: _selectedSkills.isEmpty ? Colors.grey : Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AnimatedRotation(
                                turns: _showSkillDropdown ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: const Icon(Icons.expand_more, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF23242A),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.18), blurRadius: 16, offset: Offset(0, 6))],
                            border: Border.all(color: const Color(0xFF00d2ff)),
                          ),
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: SingleChildScrollView(
                            child: Column(
                              children: _skillOptions.map((skill) => Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _selectSkill(skill, !_selectedSkills.contains(skill)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: _selectedSkills.contains(skill),
                                          onChanged: (selected) => _selectSkill(skill, selected ?? false),
                                          activeColor: const Color(0xFF00d2ff),
                                          checkColor: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(skill, style: const TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                        crossFadeState: _showSkillDropdown ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                      if (_selectedSkills.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Please select at least one skill.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: _dateOfBirth == null ? '' : _dateOfBirth!.toLocal().toString().split(' ')[0]),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Date of Birth (YYYY-MM-DD)'),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFF00d2ff),
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF23242A),
                                    onSurface: Colors.white,
                                  ),
                                  dialogTheme: DialogThemeData(
                                    backgroundColor: const Color(0xFF181A20),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _dateOfBirth = picked;
                            });
                          }
                        },
                        validator: (v) => _dateOfBirth == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _inputDecoration('Gender'),
                        items: [
                          const DropdownMenuItem(child: Text('-- Select Gender --'), value: null),
                          ...['Male', 'Female', 'Other', 'Prefer not to say'].map((g) => DropdownMenuItem(child: Text(g), value: g)),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Password'),
                        validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                        onChanged: (v) => setState(() {}),
                        enableSuggestions: false,
                        autocorrect: false,
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
                          onPressed: _isLoading ? null : _signUp,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                _isLoading ? 'Signing Up...' : 'Sign Up',
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
                      if (_success)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text('Sign up successful! You can now log in.', style: TextStyle(color: Color(0xFF00d2ff), fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 24),
                      const Divider(height: 32, thickness: 1.2, color: Color(0xFF23242A)),
                      TextButton(
                        onPressed: () {
                          GoRouter.of(context).go('/login');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF00d2ff),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        child: const Text('Already have an account? Login'),
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


  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = {
        'user_name': _userNameController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'user_type': _userTypeController.text.trim(),
        'country': _countryController.text.trim(),
        'location': _locationController.text.trim(),
        'skill_set': jsonEncode(_selectedSkills), // JSON array as string
        'date_of_birth': _dateOfBirth?.toIso8601String(),
        'gender': _gender,
        'created_date': DateTime.now().toIso8601String(),
      };
      setState(() {
        _isLoading = true;
        _error = null;
        _success = false;
      });
      try {
        final response = await http.post(
          Uri.parse('/api/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user),
        );
        if (response.statusCode == 200) {
          setState(() {
            _success = true;
            _isLoading = false;
          });
        } else if (response.statusCode == 409) {
          setState(() {
            _isLoading = false;
            _error = 'Email already registered.';
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Failed to sign up. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Network error. Please try again.';
        });
      }
    }
  }
}
