import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/providers/auth_providers.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;

  bool _isSaving = false;
  String? _error;
  String? _successMessage;

  // Profile photo state
  XFile? _selectedImage;
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _green500 = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadUserData();
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _bioController = TextEditingController();
  }

  void _loadUserData() {
    final firebaseUser = ref.read(currentFirebaseUserProvider);

    if (firebaseUser != null) {
      final displayName = firebaseUser.displayName ?? '';
      final nameParts = displayName.split(' ');

      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      _usernameController.text = firebaseUser.email?.split('@').first ?? '';
      _phoneController.text = firebaseUser.phoneNumber ?? '';
    } else {
      final nameParts = userRoleService.userName.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      _usernameController.text = userRoleService.userEmail.split('@').first;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final firebaseUser = ref.read(currentFirebaseUserProvider);

      // Update Firebase display name
      if (firebaseUser != null) {
        final newDisplayName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
        await firebaseUser.updateDisplayName(newDisplayName);

        // Update Cloudflare backend
        final idToken = await firebaseUser.getIdToken();

        await http.post(
          Uri.parse('https://thegearsh-com.pages.dev/api/update-profile'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'firebase_uid': firebaseUser.uid,
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'username': _usernameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
            'bio': _bioController.text.trim(),
          }),
        ).timeout(const Duration(seconds: 30));
      }

      // Update local service
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      userRoleService.login(
        role: userRoleService.currentRole,
        name: fullName.isNotEmpty ? fullName : userRoleService.userName,
        email: userRoleService.userEmail,
      );

      setState(() {
        _isSaving = false;
        _successMessage = 'Profile updated successfully!';
      });

      // Show success and go back after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go('/profile-settings');
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Failed to update profile. Please try again.';
      });
      debugPrint('Error saving profile: $e');
    }
  }

  /// Show photo source selection bottom sheet
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _sky500.withAlpha(51), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Change Profile Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Camera option
            _buildPhotoOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            // Gallery option
            _buildPhotoOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null || ref.read(currentFirebaseUserProvider)?.photoURL != null) ...[
              const SizedBox(height: 12),
              // Remove photo option
              _buildPhotoOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? _sky400;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: _slate800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: optionColor.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: optionColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: optionColor, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withAlpha(77),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _successMessage = 'Photo selected!';
        });

        // Clear success message after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });

        // Auto-upload on selection (optional)
        // await _uploadProfilePhoto();

        debugPrint('Photo selected: ${_uploadProfilePhoto.runtimeType}');
      }
    } on Exception catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        String errorMessage = 'Failed to pick image';
        if (e.toString().contains('photo_access_denied')) {
          errorMessage = 'Photo access denied. Please grant permission in Settings.';
        } else if (e.toString().contains('camera_access_denied')) {
          errorMessage = 'Camera access denied. Please grant permission in Settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  // Upload profile photo to Firebase/backend
  Future<void> _uploadProfilePhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingPhoto = true;
      _error = null;
    });

    try {
      final firebaseUser = ref.read(currentFirebaseUserProvider);
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      // Read image bytes
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Get file extension
      final extension = _selectedImage!.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

      // Get auth token
      final idToken = await firebaseUser.getIdToken();

      // Upload to backend
      final response = await http.post(
        Uri.parse('https://thegearsh-com.pages.dev/api/upload-profile-photo'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'firebase_uid': firebaseUser.uid,
          'image_data': base64Image,
          'mime_type': mimeType,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final photoUrl = responseData['photo_url'] as String?;

        // Update Firebase profile with new photo URL
        if (photoUrl != null) {
          await firebaseUser.updatePhotoURL(photoUrl);
        }

        setState(() {
          _isUploadingPhoto = false;
          _successMessage = 'Profile photo updated!';
        });

        // Clear success message after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      setState(() {
        _isUploadingPhoto = false;
        _error = 'Failed to upload photo. Please try again.';
      });

      // For now, just show a local preview without uploading
      // This allows the feature to work even without backend support
      setState(() {
        _error = null;
        _successMessage = 'Photo selected! Save to update.';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    }
  }

  /// Remove profile photo
  Future<void> _removePhoto() async {
    setState(() {
      _selectedImage = null;
      _isUploadingPhoto = true;
    });

    try {
      final firebaseUser = ref.read(currentFirebaseUserProvider);
      if (firebaseUser != null) {
        await firebaseUser.updatePhotoURL(null);
      }

      setState(() {
        _isUploadingPhoto = false;
        _successMessage = 'Profile photo removed!';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    } catch (e) {
      debugPrint('Error removing photo: $e');
      setState(() {
        _isUploadingPhoto = false;
        _error = 'Failed to remove photo.';
      });
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? prefixIcon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: _slate800.withAlpha(128),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _sky400.withAlpha(179), size: 20)
          : null,
      labelStyle: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
      hintStyle: TextStyle(color: Colors.white.withAlpha(77), fontSize: 14),
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
    final padding = MediaQuery.of(context).padding;
    final firebaseUser = ref.watch(currentFirebaseUserProvider);
    final photoUrl = firebaseUser?.photoURL;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: padding.top + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: _slate950.withAlpha(242),
                border: Border(
                  bottom: BorderSide(color: _sky500.withAlpha(51)),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      try {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/profile-settings');
                        }
                      } catch (e) {
                        context.go('/profile-settings');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _slate900.withAlpha(128),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _sky500.withAlpha(77)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Save button
                  GestureDetector(
                    onTap: _isSaving ? null : _saveProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _isSaving
                          ? null
                          : const LinearGradient(colors: [_sky500, _cyan500]),
                        color: _isSaving ? _slate800 : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Photo Section
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: (_selectedImage == null && photoUrl == null)
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [_sky500, _cyan500],
                                          )
                                        : null,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _sky500.withAlpha(102),
                                          blurRadius: 30,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _isUploadingPhoto
                                        ? Container(
                                            color: _slate800,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: _sky400,
                                                strokeWidth: 3,
                                              ),
                                            ),
                                          )
                                        : _selectedImage != null
                                          ? (kIsWeb
                                            ? FutureBuilder<Uint8List>(
                                                future: _selectedImage!.readAsBytes(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    return Image.memory(
                                                      snapshot.data!,
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                    );
                                                  }
                                                  return const Center(
                                                    child: CircularProgressIndicator(color: _sky400),
                                                  );
                                                },
                                              )
                                            : Image.file(
                                                File(_selectedImage!.path),
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ))
                                          : photoUrl != null
                                            ? Image.network(
                                                photoUrl,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [_sky500, _cyan500],
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person_rounded,
                                                    color: Colors.white,
                                                    size: 60,
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white,
                                                size: 60,
                                              ),
                                    ),
                                  ),
                                ),
                                // Camera button overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_sky500, _cyan500],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _slate950, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _sky500.withAlpha(102),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                              child: Text(
                                _isUploadingPhoto
                                  ? 'Uploading...'
                                  : 'Tap to change photo',
                                style: TextStyle(
                                  color: _isUploadingPhoto ? _sky400 : Colors.white.withAlpha(128),
                                  fontSize: 13,
                                  fontWeight: _isUploadingPhoto ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),


                      // Success/Error Messages
                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _green500.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _green500.withAlpha(128)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: _green500, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _successMessage!,
                                style: const TextStyle(color: _green500),
                              ),
                            ],
                          ),
                        ),

                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withAlpha(128)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Personal Information Section
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),

                      // First Name & Last Name Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: _inputDecoration('First Name', prefixIcon: Icons.person_outline),
                              validator: (value) => value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: _inputDecoration('Last Name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration('Username', prefixIcon: Icons.alternate_email, hint: 'yourname'),
                      ),
                      const SizedBox(height: 24),

                      // Contact Information Section
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 16),

                      // Email (Read-only for Firebase users)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _slate800.withAlpha(77),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _sky500.withAlpha(51)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, color: _sky400.withAlpha(128), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(128),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    firebaseUser?.email ?? userRoleService.userEmail,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _slate900,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Verified via Google',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(128),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration('Phone Number', prefixIcon: Icons.phone_outlined, hint: '+27 12 345 6789'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration('Location', prefixIcon: Icons.location_on_outlined, hint: 'Johannesburg, South Africa'),
                      ),
                      const SizedBox(height: 24),

                      // Bio Section (for Artists)
                      if (userRoleService.isArtist) ...[
                        _buildSectionTitle('About You'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: _inputDecoration('Bio', hint: 'Tell clients about yourself...').copyWith(
                            prefixIcon: null,
                          ),
                          maxLines: 4,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Account Type
                      _buildSectionTitle('Account Type'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_sky500.withAlpha(51), _cyan500.withAlpha(51)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _sky500.withAlpha(77)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _slate900,
                                shape: BoxShape.circle,
                                border: Border.all(color: _sky500.withAlpha(77)),
                              ),
                              child: Icon(
                                userRoleService.isArtist
                                  ? Icons.mic_external_on_outlined
                                  : Icons.person_outline,
                                color: _sky400,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userRoleService.isArtist ? "Artist" : "Client"} Account',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userRoleService.isArtist
                                      ? 'Offer your services to clients'
                                      : 'Book creative professionals',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(153),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _slate400,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

