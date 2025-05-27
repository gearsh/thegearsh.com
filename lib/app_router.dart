// lib/app_router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/discover/discover_page.dart';
import 'features/profile/profile_page.dart';
import 'features/booking/booking_page.dart';
//import 'features/dashboard/dashboard_page.dart';
import 'screens/dashboard_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/discover',
    routes: [
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverPage(),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProfilePage(artistId: id);
        },
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return BookingPage(artistId: id);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
    ],
  );
});


//GoRoute(
  //path: '/profile/:id',
 // builder: (context, state) {
    