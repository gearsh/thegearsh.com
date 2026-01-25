// Gearsh App - Data Layer: Artist Repository Implementation
// Implements the domain repository interface

import 'package:gearsh_app/domain/entities/artist.dart';
import 'package:gearsh_app/domain/repositories/artist_repository.dart';
import 'package:gearsh_app/data/datasources/local/artist_local_datasource.dart';

/// Artist repository implementation
///
/// Follows:
/// - Liskov Substitution: Can be used anywhere IArtistRepository is expected
/// - Dependency Inversion: Implements the domain interface
class ArtistRepositoryImpl implements IArtistRepository {
  final ArtistLocalDataSource _localDataSource;

  ArtistRepositoryImpl({
    ArtistLocalDataSource? localDataSource,
  }) : _localDataSource = localDataSource ?? ArtistLocalDataSource();

  @override
  Future<Result<List<Artist>>> getAllArtists() async {
    try {
      final artists = _localDataSource.getAllArtists();
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to load artists: $e');
    }
  }

  @override
  Future<Result<Artist>> getArtistById(String id) async {
    try {
      final artist = _localDataSource.getArtistById(id);
      if (artist != null) {
        return Result.success(artist);
      }
      return Result.failure('Artist not found');
    } catch (e) {
      return Result.failure('Failed to load artist: $e');
    }
  }

  @override
  Future<Result<Artist>> getArtistByUsername(String username) async {
    try {
      final artist = _localDataSource.getArtistByUsername(username);
      if (artist != null) {
        return Result.success(artist);
      }
      return Result.failure('Artist not found');
    } catch (e) {
      return Result.failure('Failed to load artist: $e');
    }
  }

  @override
  Future<Result<List<Artist>>> searchArtists(String query) async {
    try {
      final artists = _localDataSource.searchArtists(query);
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to search artists: $e');
    }
  }

  @override
  Future<Result<List<Artist>>> getArtistsByCategory(String category) async {
    try {
      final artists = _localDataSource.getArtistsByCategory(category);
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to load artists by category: $e');
    }
  }

  @override
  Future<Result<List<Artist>>> getArtistsByLocation(String location) async {
    try {
      final artists = _localDataSource.getArtistsByLocation(location);
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to load artists by location: $e');
    }
  }

  @override
  Future<Result<List<Artist>>> getFeaturedArtists() async {
    try {
      final artists = _localDataSource.getFeaturedArtists();
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to load featured artists: $e');
    }
  }

  @override
  Future<Result<List<Artist>>> getAvailableArtists() async {
    try {
      final artists = _localDataSource.getAvailableArtists();
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to load available artists: $e');
    }
  }

  @override
  Future<Result<List<Artist>>> getArtistsSorted({
    required ArtistSortCriteria criteria,
    bool ascending = true,
  }) async {
    try {
      final artists = _localDataSource.getArtistsSorted(
        criteria: criteria,
        ascending: ascending,
      );
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to load sorted artists: $e');
    }
  }

  @override
  Future<Result<List<Artist>>> getNearbyArtists({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    try {
      // For now, return all available artists
      // TODO: Implement actual geolocation filtering
      final artists = _localDataSource.getAvailableArtists();
      return Result.success(artists);
    } catch (e) {
      return Result.failure('Failed to load nearby artists: $e');
    }
  }
}
