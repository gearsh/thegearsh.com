import 'package:go_router/go_router.dart';
import 'package:gearsh_app/features/discover/discover_page.dart';
import 'package:gearsh_app/features/profile/profile_page.dart';
import 'package:gearsh_app/features/dashboard/dashboard_page.dart';
import 'package:gearsh_app/features/booking/booking_page.dart';
import 'package:gearsh_app/screens2/landing_page.dart';
import 'package:gearsh_app/features/error/error_page.dart';
import 'package:gearsh_app/features/profile/login_page.dart';
import 'package:gearsh_app/features/profile/signup_page.dart';
import 'package:gearsh_app/features/signups/artists_list_page.dart';

final router = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => ErrorPage(error: state.error),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/discover',
      builder: (context, state) => const DiscoverPage(),
    ),
    // Signup/Login routes required by the topnav and some pages
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/profile/:id',
      builder: (context, state) => ProfilePage(artistId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const ArtistDashboardPage(),
    ),
    // Manager alias so the topnav "Manager" button works
    GoRoute(
      path: '/manager',
      builder: (context, state) => const ArtistDashboardPage(),
    ),
    GoRoute(
      path: '/booking/:id',
      builder: (context, state) => BookingPage(artistId: state.pathParameters['id']!),
    ),
    // Artists listing route used by the app and referenced elsewhere
    GoRoute(
      path: '/artists',
      builder: (context, state) => const ArtistsListPage(),
    ),
  ],
);
