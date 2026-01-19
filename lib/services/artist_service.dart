// Gearsh App - Artist Service
// Handles artist data fetching and management

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/artist.dart';
import '../data/gearsh_artists.dart' as gearsh_data;

class ArtistService {
  static const String _baseUrl = 'https://thegearsh-com.pages.dev/api';

  /// Fetch artists from API with optional filters
  Future<List<Artist>> fetchArtists({
    String? search,
    String? category,
    String? location,
    double? minRating,
    double? maxPrice,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        if (search != null && search.isNotEmpty) 'q': search,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (minRating != null) 'min_rating': minRating.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final uri = Uri.parse('$_baseUrl/artists').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final artists = (data['data'] as List?)
            ?.map((a) => Artist.fromJson(a))
            .toList() ?? [];
        return artists;
      }

      // Fallback to local data
      return _getLocalArtists(search: search, category: category);
    } catch (e) {
      debugPrint('Error fetching artists from API: $e');
      // Fallback to local data
      return _getLocalArtists(search: search, category: category);
    }
  }

  /// Get artist by ID
  Future<Artist?> getArtistById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/artists/$id'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Artist.fromJson(data['data']);
        }
      }

      // Fallback to local data
      return _getLocalArtistById(id);
    } catch (e) {
      debugPrint('Error fetching artist by ID: $e');
      return _getLocalArtistById(id);
    }
  }

  /// Get trending artists
  Future<List<Artist>> getTrendingArtists({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/artists?trending=true&limit=$limit'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List?)
            ?.map((a) => Artist.fromJson(a))
            .toList() ?? [];
      }

      return _getLocalArtists().take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching trending artists: $e');
      return _getLocalArtists().take(limit).toList();
    }
  }

  /// Get artists by category
  Future<List<Artist>> getArtistsByCategory(String category) async {
    return fetchArtists(category: category);
  }

  /// Local fallback - get artists from gearsh_artists.dart
  List<Artist> _getLocalArtists({String? search, String? category}) {
    var artists = gearsh_data.gearshArtists.map((ga) => Artist(
      id: ga.id,
      name: ga.name,
      genre: ga.subcategories.isNotEmpty ? ga.subcategories.first : ga.category,
      bio: ga.bio,
      image: ga.image,
      category: ga.category,
      baseRate: ga.bookingFee.toDouble(),
      location: ga.location,
      isVerified: ga.isVerified,
    )).toList();

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      artists = artists.where((a) =>
        a.name.toLowerCase().contains(searchLower) ||
        (a.category?.toLowerCase().contains(searchLower) ?? false)
      ).toList();
    }

    if (category != null && category.isNotEmpty) {
      artists = artists.where((a) =>
        a.category?.toLowerCase() == category.toLowerCase()
      ).toList();
    }

    return artists;
  }

  /// Local fallback - get artist by ID
  Artist? _getLocalArtistById(String id) {
    final ga = gearsh_data.getArtistById(id);
    if (ga != null) {
      return Artist(
        id: ga.id,
        name: ga.name,
        genre: ga.subcategories.isNotEmpty ? ga.subcategories.first : ga.category,
        bio: ga.bio,
        image: ga.image,
        category: ga.category,
        baseRate: ga.bookingFee.toDouble(),
        location: ga.location,
        isVerified: ga.isVerified,
      );
    }
    return null;
  }
}
