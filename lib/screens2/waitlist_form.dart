import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WaitlistFormPage extends StatefulWidget {
  const WaitlistFormPage({Key? key}) : super(key: key);

  @override
  State<WaitlistFormPage> createState() => _WaitlistFormPageState();
}

class _WaitlistFormPageState extends State<WaitlistFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'South Africa');
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _userType;
  String? _gender;
  List<String> _selectedSkills = [];
  bool _showSkillDropdown = false;
  bool _isSubmitting = false;

  final List<String> _skillOptions = [
    'DJ', 'Producer', 'Writer', 'Photographer', 'Designer', 'Videographer', 'Dancer', 'Host',
    'Influencer', 'Stylist', 'Rapper', 'Director', 'Actor', 'Model', 'Engineer', 'Animator',
    'Choreographer', 'Make Up Artist', 'Trap Star', 'Publicist'
  ];

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedSkills.isEmpty) return;
    setState(() { _isSubmitting = true; });
    final Map<String, dynamic> data = {
      'user_name': _usernameController.text,
      'first_name': _firstNameController.text,
      'surname': _surnameController.text,
      'email': _emailController.text,
      'contact_number': _contactController.text,
      'user_type': _userType,
      'country': _countryController.text,
      'location': _locationController.text,
      'skill_set': jsonEncode(_selectedSkills),
      'date_of_birth': _dobController.text,
      'gender': _gender,
      'created_date': DateTime.now().toIso8601String(),
    };
    try {
      final response = await http.post(
        Uri.parse('/api/waitlist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        _showModal('Success!', 'You have been added to the waitlist.');
        _formKey.currentState!.reset();
        setState(() { _selectedSkills.clear(); });
      } else {
        _showModal('Error', 'Something went wrong. Please try again later.');
      }
    } catch (e) {
      _showModal('Error', 'Network issue. Please try again.');
    }
    setState(() { _isSubmitting = false; });
  }

  void _showModal(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF00d2ff), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            constraints: BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo and Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/');
                        },
                        child: Image.asset('assets/images/gearsh_logo.png', height: 48),
                      ),
                      const SizedBox(width: 8),
                      const Text('Gearsh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
                    ).createShader(rect),
                    child: const Text(
                      'Join the Waitlist',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to know when we launch! Fill out the form below to secure your spot.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  // Form Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: _inputDecoration('Username'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _inputDecoration('First Name'),
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
                          decoration: _inputDecoration('Surname'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration('Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: _inputDecoration('Contact Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _userType,
                    decoration: _inputDecoration('I am a...'),
                    items: [
                      DropdownMenuItem(child: Text('-- Select User Type --'), value: null),
                      ...['Booker', 'Artist', 'Fan'].map((type) => DropdownMenuItem(child: Text(type), value: type)),
                    ],
                    onChanged: (v) => setState(() => _userType = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: _inputDecoration('Country'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: _inputDecoration('Location'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Skill Set Multi-select
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Skill Set (select all that apply)', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _toggleSkillDropdown,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF00d2ff)),
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
                          Icon(_showSkillDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (_showSkillDropdown)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF00d2ff)),
                      ),
                      constraints: BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          children: _skillOptions.map((skill) => CheckboxListTile(
                            value: _selectedSkills.contains(skill),
                            title: Text(skill, style: TextStyle(color: Colors.white)),
                            activeColor: Color(0xFF00d2ff),
                            checkColor: Colors.white,
                            onChanged: (selected) => _selectSkill(skill, selected ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          )).toList(),
                        ),
                      ),
                    ),
                  if (_selectedSkills.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Please select at least one skill.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    decoration: _inputDecoration('Date of Birth (YYYY-MM-DD)'),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: _inputDecoration('Gender'),
                    items: [
                      DropdownMenuItem(child: Text('-- Select Gender --'), value: null),
                      ...['Male', 'Female', 'Other', 'Prefer not to say'].map((g) => DropdownMenuItem(child: Text(g), value: g)),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                          return null;
                        }),
                      ),
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            _isSubmitting ? 'Submitting...' : 'Join the Waitlist',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Color(0xFF222222)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF00d2ff), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF00d2ff), width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF00d2ff)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
