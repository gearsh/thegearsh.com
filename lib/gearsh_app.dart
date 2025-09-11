//The Gearsh App -  lib/gearsh_app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/discover/discover_page.dart';
import 'features/profile/profile_page.dart';
import 'providers/global_providers.dart';
import 'features/auth/auth_page.dart';
import 'features/booking/booking_page.dart';
import 'features/dashboard/dashboard_page.dart';

class GearshApp extends ConsumerStatefulWidget {
  const GearshApp({super.key});

  @override
  ConsumerState<GearshApp> createState() => _GearshAppState();
}

class _GearshAppState extends ConsumerState<GearshApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _setupRouter();
  }

  void _setupRouter() {
    _router = GoRouter(
      initialLocation: '/discover',
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final isAuthenticated = auth == AuthState.authenticated; //

        if (state.uri.toString() == '/booking' && !isAuthenticated) {
          return '/auth';
        }

        if (state.uri.toString() == '/auth' && isAuthenticated) {
          return '/booking';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/discover',
          builder: (context, state) => const DiscoverPage(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthPage(),
        ),
        GoRoute(
          path: '/booking/:artistId',
          builder: (context, state) {
            final artistId = state.pathParameters['artistId']!;
            return BookingPage(artistId: artistId);
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const ArtistDashboardPage(),
        ),
        GoRoute(
          path: '/profile/:artistId',
          builder: (context, state) {
            final artistId = state.pathParameters['artistId']!;
            return ProfilePage(artistId: artistId);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gearsh',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
    );
  }
}
