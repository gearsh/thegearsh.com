// The Gearsh App - lib/providers/artist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';

final artistListProvider = FutureProvider<List<Artist>>((ref) async {
  // TODO: Replace with D1 database fetch logic
  return [];
});

final artistByIdProvider =
    FutureProvider.family<Artist, String>((ref, id) async {
  // TODO: Replace with D1 database fetch logic
  return Artist(
    id: id,
    name: '',
    genre: '',
    image: '',
    bio: '',
    category: '',
    hoursWorked: 0,
  );
});
