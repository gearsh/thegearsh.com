// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/screens/dashboard_page.dart';
import 'package:go_router/go_router.dart';
import 'features/discover/discover_page.dart';
import 'features/profile/profile_page.dart';
import 'features/booking/booking_page.dart';
//import 'features/dashboard/dashboard_page.dart';

void main() {
  runApp(const ProviderScope(child: GearshApp()));
}

class GearshApp extends StatelessWidget {
  const GearshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: Colors.black,
        ),
        useMaterial3: true,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Segoe UI'),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DiscoverPage()),
    GoRoute(path: '/profile/:id', builder: (context, state) {
      final id = state.pathParameters['id'];
      return ProfilePage(artistId: id ?? '');
    }),
    GoRoute(path: '/booking/:id', builder: (context, state) {
      final id = state.pathParameters['id'];
      return BookingPage(artistId: id ?? '');
    }),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
  ],
);
