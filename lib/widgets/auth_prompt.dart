import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';

/// Color constants matching Gearsh theme
const Color _slate950 = Color(0xFF020617);
const Color _slate900 = Color(0xFF0F172A);
const Color _sky500 = Color(0xFF0EA5E9);
const Color _sky400 = Color(0xFF38BDF8);
const Color _cyan400 = Color(0xFF22D3EE);

/// Shows a sign-up prompt dialog when guest users try to access protected features
/// Returns true if user is logged in and can proceed, false otherwise
bool checkAuthAndPrompt(BuildContext context, {String? featureName}) {
  if (!userRoleService.requiresSignUp) {
    return true; // User is logged in, allow action
  }

  // Show sign-up prompt
  showSignUpPrompt(context, featureName: featureName);
  return false;
}

/// Shows a beautiful sign-up prompt dialog
void showSignUpPrompt(BuildContext context, {String? featureName}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SignUpPromptSheet(featureName: featureName),
  );
}

class SignUpPromptSheet extends StatelessWidget {
  final String? featureName;

  const SignUpPromptSheet({super.key, this.featureName});

  @override
  Widget build(BuildContext context) {
    final feature = featureName ?? 'this feature';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_slate950, _slate900],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _sky500.withAlpha(51), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _sky500.withAlpha(25),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon with glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_sky500, _cyan400],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _sky500.withAlpha(102),
                    blurRadius: 25,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_sky400, _cyan400],
              ).createShader(bounds),
              child: const Text(
                'Join Gearsh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Create an account to $feature and unlock all the amazing features Gearsh has to offer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Benefits
            _buildBenefitItem(Icons.bookmark_rounded, 'Save your favorite artists'),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.calendar_today_rounded, 'Book services instantly'),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.chat_bubble_outline_rounded, 'Message artists directly'),
            const SizedBox(height: 32),

            // Sign Up Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/signup');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_sky500, _cyan400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(102),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sign In Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/login');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _sky500.withAlpha(77), width: 1.5),
                ),
                child: const Text(
                  'I already have an account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _sky400,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Continue browsing
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Continue browsing',
                style: TextStyle(
                  color: Colors.white.withAlpha(128),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _sky500.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _sky500.withAlpha(51)),
          ),
          child: Icon(icon, color: _sky400, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withAlpha(204),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

