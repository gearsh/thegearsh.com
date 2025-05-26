// lib/providers/artist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/airtable_service.dart';

final artistsProvider = FutureProvider((ref) async {
  return AirtableService.fetchArtists();
});
