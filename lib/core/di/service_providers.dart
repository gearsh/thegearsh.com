import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/core/contracts/i_auth_repository.dart';
import 'package:gearsh_app/core/contracts/i_booking_repository.dart';
import 'package:gearsh_app/core/contracts/i_config_repository.dart';
import 'package:gearsh_app/repos/auth_repository.dart';
import 'package:gearsh_app/services/api_service.dart';
import 'package:gearsh_app/services/auth_api_service.dart';
import 'package:gearsh_app/services/auth_service.dart';
import 'package:gearsh_app/services/booking_service.dart';
import 'package:gearsh_app/services/firebase_auth_service.dart';
import 'package:gearsh_app/core/contracts/i_dashboard_repository.dart';
import 'package:gearsh_app/core/contracts/i_messages_repository.dart';
import 'package:gearsh_app/services/dashboard_service.dart';
import 'package:gearsh_app/services/global_config_service.dart';
import 'package:gearsh_app/services/messages_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dependency injection root — register implementations once, consume via [Ref].
///
/// SOLID mapping:
/// - **S**ingle responsibility: each provider owns one service/repository.
/// - **O**pen/closed: swap implementations with [ProviderScope] overrides in tests.
/// - **L**iskov: repositories honor their interface contracts.
/// - **I**nterface segregation: narrow `I*` contracts per domain.
/// - **D**ependency inversion: UI/state depends on abstractions, not concrete HTTP classes.

/// SharedPreferences — override in [main] after async init.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthApiService(apiService);
});

final authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => AuthRepository(ref.watch(authServiceProvider)),
);

final bookingRepositoryProvider = Provider<IBookingRepository>(
  (ref) => BookingService(),
);

/// Backward-compatible alias.
final bookingServiceProvider = bookingRepositoryProvider;

final configRepositoryProvider = Provider<IConfigRepository>(
  (ref) => globalConfigService,
);

final messagesRepositoryProvider = Provider<IMessagesRepository>(
  (ref) => MessagesService(),
);

final dashboardRepositoryProvider = Provider<IDashboardRepository>(
  (ref) => DashboardService(),
);

/// Bumps when login/logout completes so linked queries refetch together.
class SessionRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final sessionRevisionProvider =
    NotifierProvider<SessionRevisionNotifier, int>(SessionRevisionNotifier.new);

/// App startup: config init + session preload hook for linked queries.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final config = ref.read(configRepositoryProvider);
  await config.init();
  ref.read(sessionRevisionProvider.notifier).bump();
});
