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

final authProvider =
    StateProvider<AuthState>((ref) => AuthState.unauthenticated);

enum AuthState {
  unauthenticated,
  authenticated,
}
