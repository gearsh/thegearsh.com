// The Gearsh App - lib/providers/artist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../services/airtable_service.dart';

final artistListProvider = FutureProvider<List<Artist>>((ref) async {
  final airtableService = AirtableService();
  final artists = await airtableService.fetchArtists();
  airtableService.dispose();
  return artists;
});

final artistByIdProvider =
    FutureProvider.family<Artist, String>((ref, id) async {
  final airtableService = AirtableService();
  final artist = await airtableService.fetchArtistById(id);
  airtableService.dispose();
  return artist;
});
