import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/user_role.dart';
import 'package:gearsh_app/providers/user_role_provider.dart';

/// Apply logged-in role state after a successful auth API / social sign-in.
void applyAuthenticatedUserRole(
  WidgetRef ref, {
  required UserRole role,
  required String name,
  required String email,
}) {
  ref.read(userRoleProvider.notifier).login(
        role: role,
        name: name,
        email: email,
      );
}

/// Customer name parts for PayFast and checkout flows.
(String firstName, String lastName) customerNameParts(UserRoleState role) {
  final parts = role.userName.split(' ');
  final firstName = parts.isNotEmpty ? parts.first : 'Guest';
  final lastName = parts.length > 1 ? parts.last : '';
  return (firstName, lastName);
}

/// Whether the user must sign up before accessing protected flows.
bool requiresSignUp(WidgetRef ref) => ref.read(userRoleProvider).requiresSignUp;

/// Whether the user is browsing as a guest without an account.
bool isGuestUser(WidgetRef ref) {
  final role = ref.read(userRoleProvider);
  return role.isGuest && !role.isLoggedIn;
}
