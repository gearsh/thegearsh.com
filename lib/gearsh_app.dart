//The Gearsh App -  lib/gearsh_app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/screens2/waitlist_form.dart';
import 'package:go_router/go_router.dart';

import 'features/discover/discover_page.dart';
import 'features/profile/profile_page.dart';
import 'providers/global_providers.dart';
import 'features/auth/auth_page.dart';
import 'features/booking/booking_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'screens2/landing_page.dart';
import 'screens/web/story_page.dart';
import 'features/profile/signup_page.dart';
import 'features/profile/login_page.dart';

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
      initialLocation: '/landing',
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
          path: '/landing',
          builder: (context, state) => const LandingPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupPage(),
        ),
        GoRoute(
          path: '/story',
          builder: (context, state) => const StoryPage(),
        ),
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
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
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
