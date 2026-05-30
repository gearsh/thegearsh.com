import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/user_role.dart';
import 'package:gearsh_app/providers/user_role_provider.dart';
import 'package:gearsh_app/services/auth_api_service.dart';

/// Apply logged-in role state after a successful auth API / social sign-in.
void applyAuthenticatedUserRole(
  WidgetRef ref, {
  required UserRole role,
  required String name,
  required String email,
  List<UserRole>? availableRoles,
}) {
  ref.read(userRoleProvider.notifier).login(
        role: role,
        name: name,
        email: email,
        availableRoles: availableRoles,
      );
}

/// Map backend auth payload to active role + available perspectives.
UserRole activeRoleFromAuthUser(AuthUser user) {
  final perspective = user.activePerspective;
  if (perspective == 'artist' && user.canActAsArtist) return UserRole.artist;
  if (perspective == 'fan') return UserRole.fan;
  return UserRole.client;
}

List<UserRole> availableRolesFromAuthUser(AuthUser user) {
  final roles = <UserRole>[];
  for (final r in user.roles) {
    switch (r) {
      case 'artist':
        roles.add(UserRole.artist);
      case 'client':
        roles.add(UserRole.client);
      case 'admin':
        roles.add(UserRole.client);
      default:
        break;
    }
  }
  if (roles.isEmpty) {
    roles.add(user.isArtist ? UserRole.artist : UserRole.client);
  }
  return roles.toSet().toList();
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
