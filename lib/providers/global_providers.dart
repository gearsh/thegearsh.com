//The Gearsh App - lib/providers/global_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/artist.dart';

final artistProvider = Provider<List<Artist>>((ref) {
  return [
    Artist(
      id: '1',
      name: 'Artist One',
      genre: 'R&B',
      image: 'https://via.placeholder.com/150',
      bio: 'Sample bio for artist one.',
      category: 'MC',
      hoursWorked: 0,
    ),
    Artist(
      id: '2',
      name: 'Artist Two',
      genre: 'Hip Hop',
      image: 'https://via.placeholder.com/150',
      bio: 'Sample bio for artist two.',
      category: 'DJ',
      hoursWorked: 0,
    ),
  ];
});

enum AuthState {
  unauthenticated,
  authenticated,
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.unauthenticated;

  void signIn() {
    state = AuthState.authenticated;
  }

  void signOut() {
    state = AuthState.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
