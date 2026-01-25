// Gearsh App - Domain Layer: Use Cases
// Each use case has a single responsibility
// Follows Single Responsibility Principle

import '../entities/artist.dart';
import '../repositories/artist_repository.dart';

/// Base use case interface
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// No parameters marker
class NoParams {
  const NoParams();
}

// ============================================================================
// ARTIST USE CASES
// ============================================================================

/// Get all artists use case
class GetAllArtistsUseCase implements UseCase<List<Artist>, NoParams> {
  final IArtistRepository repository;

  GetAllArtistsUseCase(this.repository);

  @override
  Future<Result<List<Artist>>> call(NoParams params) {
    return repository.getAllArtists();
  }
}

/// Get artist by ID use case
class GetArtistByIdUseCase implements UseCase<Artist, String> {
  final IArtistRepository repository;

  GetArtistByIdUseCase(this.repository);

  @override
  Future<Result<Artist>> call(String id) {
    return repository.getArtistById(id);
  }
}

/// Get artist by username use case
class GetArtistByUsernameUseCase implements UseCase<Artist, String> {
  final IArtistRepository repository;

  GetArtistByUsernameUseCase(this.repository);

  @override
  Future<Result<Artist>> call(String username) {
    return repository.getArtistByUsername(username);
  }
}

/// Search artists use case
class SearchArtistsUseCase implements UseCase<List<Artist>, String> {
  final IArtistRepository repository;

  SearchArtistsUseCase(this.repository);

  @override
  Future<Result<List<Artist>>> call(String query) {
    return repository.searchArtists(query);
  }
}

/// Get artists by category use case
class GetArtistsByCategoryUseCase implements UseCase<List<Artist>, String> {
  final IArtistRepository repository;

  GetArtistsByCategoryUseCase(this.repository);

  @override
  Future<Result<List<Artist>>> call(String category) {
    return repository.getArtistsByCategory(category);
  }
}

/// Get featured artists use case
class GetFeaturedArtistsUseCase implements UseCase<List<Artist>, NoParams> {
  final IArtistRepository repository;

  GetFeaturedArtistsUseCase(this.repository);

  @override
  Future<Result<List<Artist>>> call(NoParams params) {
    return repository.getFeaturedArtists();
  }
}

/// Get available artists use case
class GetAvailableArtistsUseCase implements UseCase<List<Artist>, NoParams> {
  final IArtistRepository repository;

  GetAvailableArtistsUseCase(this.repository);

  @override
  Future<Result<List<Artist>>> call(NoParams params) {
    return repository.getAvailableArtists();
  }
}

/// Parameters for nearby artists
class NearbyArtistsParams {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const NearbyArtistsParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50,
  });
}

/// Get nearby artists use case
class GetNearbyArtistsUseCase implements UseCase<List<Artist>, NearbyArtistsParams> {
  final IArtistRepository repository;

  GetNearbyArtistsUseCase(this.repository);

  @override
  Future<Result<List<Artist>>> call(NearbyArtistsParams params) {
    return repository.getNearbyArtists(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusKm: params.radiusKm,
    );
  }
}

/// Parameters for sorted artists
class SortedArtistsParams {
  final ArtistSortCriteria criteria;
  final bool ascending;

  const SortedArtistsParams({
    required this.criteria,
    this.ascending = true,
  });
}

/// Get sorted artists use case
class GetSortedArtistsUseCase implements UseCase<List<Artist>, SortedArtistsParams> {
  final IArtistRepository repository;

  GetSortedArtistsUseCase(this.repository);

  @override
  Future<Result<List<Artist>>> call(SortedArtistsParams params) {
    return repository.getArtistsSorted(
      criteria: params.criteria,
      ascending: params.ascending,
    );
  }
}
