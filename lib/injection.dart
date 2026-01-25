// Gearsh App - Dependency Injection
// Centralized service locator for clean architecture
// Uses Riverpod for dependency injection

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Domain Layer
import 'domain/repositories/artist_repository.dart';
import 'domain/usecases/artist_usecases.dart';

// Data Layer
import 'data/repositories/artist_repository_impl.dart';
import 'data/datasources/local/artist_local_datasource.dart';

// ============================================================================
// DATA SOURCES
// ============================================================================

/// Artist local data source provider
final artistLocalDataSourceProvider = Provider<ArtistLocalDataSource>((ref) {
  return ArtistLocalDataSource();
});

// ============================================================================
// REPOSITORIES
// ============================================================================

/// Artist repository provider
/// Returns the abstract interface, hiding implementation details
final artistRepositoryProvider = Provider<IArtistRepository>((ref) {
  final localDataSource = ref.watch(artistLocalDataSourceProvider);
  return ArtistRepositoryImpl(localDataSource: localDataSource);
});

// ============================================================================
// USE CASES
// ============================================================================

/// Get all artists use case provider
final getAllArtistsUseCaseProvider = Provider<GetAllArtistsUseCase>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return GetAllArtistsUseCase(repository);
});

/// Get artist by ID use case provider
final getArtistByIdUseCaseProvider = Provider<GetArtistByIdUseCase>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return GetArtistByIdUseCase(repository);
});

/// Get artist by username use case provider
final getArtistByUsernameUseCaseProvider = Provider<GetArtistByUsernameUseCase>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return GetArtistByUsernameUseCase(repository);
});

/// Search artists use case provider
final searchArtistsUseCaseProvider = Provider<SearchArtistsUseCase>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return SearchArtistsUseCase(repository);
});

/// Get artists by category use case provider
final getArtistsByCategoryUseCaseProvider = Provider<GetArtistsByCategoryUseCase>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return GetArtistsByCategoryUseCase(repository);
});

/// Get featured artists use case provider
final getFeaturedArtistsUseCaseProvider = Provider<GetFeaturedArtistsUseCase>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return GetFeaturedArtistsUseCase(repository);
});

/// Get available artists use case provider
final getAvailableArtistsUseCaseProvider = Provider<GetAvailableArtistsUseCase>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return GetAvailableArtistsUseCase(repository);
});

// ============================================================================
// STATE PROVIDERS (for UI)
// ============================================================================

/// All artists state provider
final allArtistsProvider = FutureProvider((ref) async {
  final useCase = ref.watch(getAllArtistsUseCaseProvider);
  final result = await useCase.call(const NoParams());
  if (result.isSuccess && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Failed to load artists');
});

/// Artist by ID state provider
final artistByIdProvider = FutureProvider.family((ref, String id) async {
  final useCase = ref.watch(getArtistByIdUseCaseProvider);
  final result = await useCase.call(id);
  if (result.isSuccess && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Artist not found');
});

/// Artists by category state provider
final artistsByCategoryProvider = FutureProvider.family((ref, String category) async {
  final useCase = ref.watch(getArtistsByCategoryUseCaseProvider);
  final result = await useCase.call(category);
  if (result.isSuccess && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Failed to load artists');
});

/// Search results state provider
final artistSearchProvider = FutureProvider.family((ref, String query) async {
  final useCase = ref.watch(searchArtistsUseCaseProvider);
  final result = await useCase.call(query);
  if (result.isSuccess && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Search failed');
});

/// Featured artists state provider
final featuredArtistsProvider = FutureProvider((ref) async {
  final useCase = ref.watch(getFeaturedArtistsUseCaseProvider);
  final result = await useCase.call(const NoParams());
  if (result.isSuccess && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Failed to load featured artists');
});

/// Available artists state provider
final availableArtistsProvider = FutureProvider((ref) async {
  final useCase = ref.watch(getAvailableArtistsUseCaseProvider);
  final result = await useCase.call(const NoParams());
  if (result.isSuccess && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Failed to load available artists');
});
