// lib/providers/artist_provider.dart

//import 'package:flutter_riverpod/flutter_riverpod.dart';
//import '../services/airtable_service.dart';

//final artistsProvider = FutureProvider((ref) async {
//return AirtableService.fetchArtists();
//});

// lib/providers/artist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/airtable_service.dart';

final artistProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final airtableService = AirtableService();
  return await airtableService.fetchArtists();
});

final artistByIdProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final service = AirtableService();
  return service.fetchArtistById(id);
});
