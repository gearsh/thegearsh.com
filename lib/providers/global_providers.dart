//The Gearsh App - lib/providers/global_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/services/airtable_service.dart';

final String apiKey =
    'pat9PYLZ3jMlj9AN2.d3ecc72334962e299bd9757bb7badbcf734de2fea1528186e112abfca9c4c4f1';
final String baseId = 'appXVEAL5jETcjmaE';

final airtableProvider = Provider<AirtableService>((ref) => AirtableService());

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
