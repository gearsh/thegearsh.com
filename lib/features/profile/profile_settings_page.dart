import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/widgets/auth_prompt.dart';
import 'package:gearsh_app/widgets/region_selector.dart';
import 'package:gearsh_app/providers/auth_providers.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate300 = Color(0xFFCBD5E1);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _sky300 = Color(0xFF7DD3FC);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _red500 = Color(0xFFEF4444);
  static const Color _red400 = Color(0xFFF87171);
  static const Color _purple500 = Color(0xFF8B5CF6);

  // Get user data from Firebase and local service
  Map<String, dynamic> _getUserData() {
    final firebaseUser = ref.read(currentFirebaseUserProvider);

    String roleName = 'Client';
    if (userRoleService.isArtist) {
      roleName = 'Artist';
    } else if (userRoleService.isFan) {
      roleName = 'Fan';
    }

    if (firebaseUser != null) {
      final displayName = firebaseUser.displayName ?? '';
      final nameParts = displayName.split(' ');
      return {
        'firstName': nameParts.isNotEmpty ? nameParts.first : 'User',
        'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        'email': firebaseUser.email ?? '',
        'phone': firebaseUser.phoneNumber ?? '',
        'photoUrl': firebaseUser.photoURL,
        'role': roleName,
        'isEmailVerified': firebaseUser.emailVerified,
      };
    }

    // Fallback to local service data
    return {
      'firstName': userRoleService.userName.split(' ').first,
      'lastName': userRoleService.userName.split(' ').length > 1
          ? userRoleService.userName.split(' ').last
          : '',
      'email': userRoleService.userEmail,
      'phone': '',
      'photoUrl': null,
      'role': roleName,
      'isEmailVerified': false,
    };
  }

  // Get role-specific settings sections
  List<Map<String, dynamic>> get _settingsSections {
    if (userRoleService.isArtist) {
      return [
        {
          'title': 'Dashboard',
          'items': [
            {'icon': Icons.dashboard_outlined, 'label': 'Artist Dashboard', 'route': '/dashboard'},
            {'icon': Icons.calendar_today_outlined, 'label': 'Manage Bookings', 'route': '/dashboard'},
            {'icon': Icons.attach_money_rounded, 'label': 'Earnings', 'route': '/dashboard'},
          ],
        },
        {
          'title': 'Services',
          'items': [
            {'icon': Icons.build_outlined, 'label': 'Manage Services', 'route': '/dashboard'},
            {'icon': Icons.photo_library_outlined, 'label': 'Portfolio', 'route': '/dashboard'},
          ],
        },
        {
          'title': 'Account',
          'items': [
            {'icon': Icons.person_outline_rounded, 'label': 'Edit Profile', 'route': '/edit-profile'},
            {'icon': Icons.notifications_outlined, 'label': 'Notifications', 'route': '/notifications'},
            {'icon': Icons.shield_outlined, 'label': 'Privacy & Security', 'route': '/privacy'},
          ],
        },
        {
          'title': 'Support',
          'items': [
            {'icon': Icons.help_outline_rounded, 'label': 'Help Centre', 'route': '/help'},
            {'icon': Icons.quiz_outlined, 'label': 'FAQ & About Gearsh', 'route': '/faq'},
            {'icon': Icons.privacy_tip_outlined, 'label': 'Privacy Policy', 'route': '/privacy-policy'},
            {'icon': Icons.description_outlined, 'label': 'Terms & Conditions', 'route': '/terms'},
          ],
        },
      ];
    } else if (userRoleService.isFan) {
      // Fan settings - Focus on following artists and events
      return [
        {
          'title': 'Following',
          'items': [
            {'icon': Icons.favorite_outline_rounded, 'label': 'Artists I Follow', 'route': '/saved-artists'},
            {'icon': Icons.event_outlined, 'label': 'Upcoming Gigs', 'route': '/gigs'},
            {'icon': Icons.notifications_active_outlined, 'label': 'Event Alerts', 'route': '/notifications'},
          ],
        },
        {
          'title': 'Account',
          'items': [
            {'icon': Icons.person_outline_rounded, 'label': 'Edit Profile', 'route': '/edit-profile'},
            {'icon': Icons.notifications_outlined, 'label': 'Notifications', 'route': '/notifications'},
            {'icon': Icons.shield_outlined, 'label': 'Privacy & Security', 'route': '/privacy'},
          ],
        },
        {
          'title': 'Support',
          'items': [
            {'icon': Icons.help_outline_rounded, 'label': 'Help Centre', 'route': '/help'},
            {'icon': Icons.quiz_outlined, 'label': 'FAQ & About Gearsh', 'route': '/faq'},
            {'icon': Icons.privacy_tip_outlined, 'label': 'Privacy Policy', 'route': '/privacy-policy'},
            {'icon': Icons.description_outlined, 'label': 'Terms & Conditions', 'route': '/terms'},
          ],
        },
      ];
    } else {
      // Client settings
      return [
        {
          'title': 'Bookings',
          'items': [
            {'icon': Icons.calendar_today_outlined, 'label': 'My Bookings', 'route': '/my-bookings'},
            {'icon': Icons.favorite_outline_rounded, 'label': 'Saved Artists', 'route': '/saved-artists'},
            {'icon': Icons.shopping_cart_outlined, 'label': 'My Cart', 'route': '/cart'},
          ],
        },
        {
          'title': 'Account',
          'items': [
            {'icon': Icons.person_outline_rounded, 'label': 'Edit Profile', 'route': '/edit-profile'},
            {'icon': Icons.payment_outlined, 'label': 'Payment Methods', 'route': '/payments'},
            {'icon': Icons.notifications_outlined, 'label': 'Notifications', 'route': '/notifications'},
            {'icon': Icons.shield_outlined, 'label': 'Privacy & Security', 'route': '/privacy'},
          ],
        },
        {
          'title': 'Support',
          'items': [
            {'icon': Icons.help_outline_rounded, 'label': 'Help Centre', 'route': '/help'},
            {'icon': Icons.quiz_outlined, 'label': 'FAQ & About Gearsh', 'route': '/faq'},
            {'icon': Icons.privacy_tip_outlined, 'label': 'Privacy Policy', 'route': '/privacy-policy'},
            {'icon': Icons.description_outlined, 'label': 'Terms & Conditions', 'route': '/terms'},
          ],
        },
      ];
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _sky500.withAlpha(51)),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white.withAlpha(179)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withAlpha(153)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Sign out from Firebase
              await ref.read(authControllerProvider).signOut();
              // Sign out from local service
              userRoleService.logout();
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: _red400, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Check if guest user trying to access profile settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userRoleService.requiresSignUp) {
        showSignUpPrompt(context, featureName: 'access your profile');
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;

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
                          context.go('/');
                        }
                      } catch (e) {
                        context.go('/');
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
                    'Profile & Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    _buildProfileCard(context),
                    const SizedBox(height: 24),

                    // Region & Currency Selector
                    _buildRegionSection(),
                    const SizedBox(height: 16),

                    // Settings Sections
                    ..._settingsSections.map((section) => _buildSettingsSection(context, section)),

                    // Role Switcher
                    const SizedBox(height: 8),
                    _buildRoleSwitcher(context),

                    // Logout Button
                    const SizedBox(height: 16),
                    _buildLogoutButton(context),

                    // Delete Account Button
                    const SizedBox(height: 12),
                    _buildDeleteAccountButton(context),

                    // App Info
                    const SizedBox(height: 24),
                    _buildAppInfo(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final userData = _getUserData();
    final photoUrl = userData['photoUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sky500.withAlpha(51),
            _cyan500.withAlpha(51),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sky500.withAlpha(77)),
      ),
      child: Column(
        children: [
          // User info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with profile photo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: photoUrl == null
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
                  child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 80,
                        height: 80,
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
                            size: 40,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                ),
              ),
              const SizedBox(width: 16),
              // User details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${userData['firstName']} ${userData['lastName']}'.trim().isEmpty
                                ? 'User'
                                : '${userData['firstName']} ${userData['lastName']}'.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (userData['isEmailVerified'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(51),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.green, size: 12),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(color: Colors.green, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['email'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userData['role']} Account',
                      style: const TextStyle(
                        color: _sky300,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Edit Profile button
                    GestureDetector(
                      onTap: () => context.go('/edit-profile'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _slate900.withAlpha(128),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _sky500.withAlpha(77)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: _sky300,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: _sky300,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Container(
            height: 1,
            color: _sky500.withAlpha(77),
          ),
          const SizedBox(height: 16),
          // Contact info
          _buildContactInfo(Icons.email_outlined, userData['email'] ?? ''),
          if ((userData['phone'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildContactInfo(Icons.phone_outlined, userData['phone'] ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _sky400, size: 18),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: _slate300,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, Map<String, dynamic> section) {
    final items = section['items'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            section['title'],
            style: const TextStyle(
              color: _slate400,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _slate900.withAlpha(102),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _sky500.withAlpha(51)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return GestureDetector(
                onTap: () {
                  final route = item['route'] as String?;
                  if (route != null && route.isNotEmpty) {
                    context.go(route);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: _sky500.withAlpha(25)),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _slate900.withAlpha(128),
                          shape: BoxShape.circle,
                          border: Border.all(color: _sky500.withAlpha(77)),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: _sky400,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _slate400,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRegionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Region & Currency',
            style: const TextStyle(
              color: _slate400,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _slate900.withAlpha(102),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _sky500.withAlpha(51)),
          ),
          child: const RegionSelectorWidget(),
        ),
      ],
    );
  }

  Widget _buildRoleSwitcher(BuildContext context) {
    final isArtist = userRoleService.isArtist;
    final targetRole = isArtist ? 'Client' : 'Artist';
    final targetIcon = isArtist ? Icons.person_outline : Icons.mic_external_on_outlined;

    return GestureDetector(
      onTap: () {
        userRoleService.switchRole();
        setState(() {});
        // Navigate to appropriate home screen
        if (userRoleService.isArtist) {
          context.go('/dashboard');
        } else {
          context.go('/');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_purple500.withAlpha(51), _sky500.withAlpha(51)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _purple500.withAlpha(77)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, color: _purple500, size: 22),
            const SizedBox(width: 10),
            Text(
              'Switch to $targetRole Mode',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Icon(targetIcon, color: _purple500, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleLogout(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _red500.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _red500.withAlpha(77)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: _red400, size: 22),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                color: _red400,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeleteAccountDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _red500.withAlpha(51)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, color: _red500.withAlpha(153), size: 20),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(
                color: _red500.withAlpha(179),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeleteAccountSheet(
        onConfirm: (password) => _handleDeleteAccount(ctx, password),
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context, String password) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: _sky500),
      ),
    );

    try {
      // Get current user from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context); // Close loading
        _showErrorSnackbar(context, 'No user logged in');
        return;
      }

      // Get email credential
      final email = user.email;
      if (email == null) {
        Navigator.pop(context); // Close loading
        _showErrorSnackbar(context, 'User email not found');
        return;
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user account from Firebase
      await user.delete();

      // Clear local data
      userRoleService.logout();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Close the bottom sheet if still open
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navigate to onboarding
      if (context.mounted) {
        _showSuccessSnackbar(context, 'Your account has been permanently deleted');
        context.go('/onboarding');
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      String errorMessage = 'Failed to delete account';
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Please logout and login again before deleting your account.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      if (context.mounted) {
        _showErrorSnackbar(context, errorMessage);
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _red500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Gearsh v1.0.0',
            style: TextStyle(
              color: _slate500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2025 Gearsh. All rights reserved.',
            style: TextStyle(
              color: _slate600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Delete Account Confirmation Sheet
class _DeleteAccountSheet extends StatefulWidget {
  final Function(String password) onConfirm;

  const _DeleteAccountSheet({required this.onConfirm});

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _confirmDelete = false;
  String? _errorText;

  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _red500 = Color(0xFFEF4444);
  static const Color _red400 = Color(0xFFF87171);

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: _slate900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _red500.withAlpha(51)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Warning Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _red500.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: _red500,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Warning Text
              Text(
                'This action is permanent and cannot be undone. All your data, including your profile, bookings, and messages will be permanently deleted.',
                style: TextStyle(
                  color: _slate400,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // What will be deleted
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _red500.withAlpha(13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _red500.withAlpha(51)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This will delete:',
                      style: TextStyle(
                        color: _red400,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDeleteItem('Your profile information'),
                    _buildDeleteItem('All booking history'),
                    _buildDeleteItem('Messages and conversations'),
                    _buildDeleteItem('Saved artists and preferences'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Password Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your password to confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: _slate400),
                      errorText: _errorText,
                      filled: true,
                      fillColor: _slate950,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _slate400.withAlpha(77)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _slate400.withAlpha(77)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _sky500),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _red500),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: _slate400,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Confirmation Checkbox
              GestureDetector(
                onTap: () => setState(() => _confirmDelete = !_confirmDelete),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _confirmDelete ? _red500 : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _confirmDelete ? _red500 : _slate400,
                          width: 2,
                        ),
                      ),
                      child: _confirmDelete
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I understand this action is permanent',
                        style: TextStyle(
                          color: _slate400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _slate950,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _slate400.withAlpha(77)),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _confirmDelete && _passwordController.text.isNotEmpty
                          ? () {
                              if (_passwordController.text.length < 6) {
                                setState(() => _errorText = 'Password must be at least 6 characters');
                                return;
                              }
                              Navigator.pop(context);
                              widget.onConfirm(_passwordController.text);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _confirmDelete && _passwordController.text.isNotEmpty
                              ? _red500
                              : _red500.withAlpha(77),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Permanently Delete',
                            style: TextStyle(
                              color: _confirmDelete && _passwordController.text.isNotEmpty
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, color: _red400, size: 16),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: _slate400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

