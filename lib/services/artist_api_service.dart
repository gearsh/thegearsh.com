import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/config/api_config.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/services/api_service.dart';

/// Provider for the artist API service
final artistApiServiceProvider = Provider((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ArtistApiService(apiService);
});

/// Provider for fetching artists from the API
final apiArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final artistApiService = ref.read(artistApiServiceProvider);
  return artistApiService.getArtists();
});

/// Provider for fetching a single artist
final apiArtistByIdProvider = FutureProvider.family<Artist?, String>((ref, artistId) async {
  final artistApiService = ref.read(artistApiServiceProvider);
  return artistApiService.getArtistById(artistId);
});

/// Artist API service
class ArtistApiService {
  final ApiService _apiService;

  ArtistApiService(this._apiService);

  /// Get all artists with optional filters
  Future<List<Artist>> getArtists({
    String? category,
    double? minRating,
    bool? verified,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (verified == true) queryParams['verified'] = 'true';

    final response = await _apiService.get(
      ApiConfig.artists,
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Artist.fromApiJson(json)).toList();
    }

    return [];
  }

  /// Get a single artist by ID
  Future<Artist?> getArtistById(String artistId) async {
    final response = await _apiService.get('${ApiConfig.artists}/$artistId');

    if (response.success && response.data != null) {
      return Artist.fromApiJson(response.data['data']);
    }

    return null;
  }

  /// Search artists
  Future<List<Artist>> searchArtists({
    required String query,
    List<String>? categories,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    bool? verified,
    String sortBy = 'relevance',
    int limit = 50,
    int offset = 0,
  }) async {
    final body = {
      'query': query,
      'categories': categories ?? [],
      'minRating': minRating ?? 0,
      'minPrice': minPrice ?? 0,
      if (maxPrice != null) 'maxPrice': maxPrice,
      'verified': verified ?? false,
      'sortBy': sortBy,
      'limit': limit,
      'offset': offset,
    };

    final response = await _apiService.post(ApiConfig.search, body: body);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Artist.fromApiJson(json)).toList();
    }

    return [];
  }
}

