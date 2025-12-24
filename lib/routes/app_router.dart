import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/screens/landing_page.dart';
import 'package:gearsh_app/screens/onboarding_page.dart';
import 'package:gearsh_app/features/error/error_page.dart';
import 'package:gearsh_app/features/signups/artists_list_page.dart';
import 'package:gearsh_app/features/profile/profile_page.dart';
import 'package:gearsh_app/features/profile/artist_view_profile_page.dart';
import 'package:gearsh_app/features/dashboard/artist_dashboard_page.dart';
import 'package:gearsh_app/features/profile/profile_settings_page.dart';
import 'package:gearsh_app/features/profile/edit_profile_page.dart';
import 'package:gearsh_app/features/bookings/my_bookings_page.dart';
import 'package:gearsh_app/features/bookings/saved_artists_page.dart';
import 'package:gearsh_app/features/booking/booking_page.dart';
import 'package:gearsh_app/features/booking/booking_flow_page.dart';
import 'package:gearsh_app/features/messages/messages_page.dart';
import 'package:gearsh_app/features/search/presentation/screens/search_screen.dart';
import 'package:gearsh_app/features/profile/signup_page.dart';
import 'package:gearsh_app/features/profile/login_page.dart';
import 'package:gearsh_app/features/profile/forgot_password_page.dart';
import 'package:gearsh_app/features/profile/reset_password_page.dart';
import 'package:gearsh_app/services/user_role_service.dart';

final GoRouter router = GoRouter(
  // Both web and mobile start at onboarding
  initialLocation: '/onboarding',
  errorBuilder: (context, state) => ErrorPage(error: state.error),
  // Redirect based on user state
  redirect: (context, state) {
    final hasSelectedRole = userRoleService.hasSelectedRole;
    final isOnboarding = state.matchedLocation == '/onboarding';
    final isAuthRoute = state.matchedLocation == '/login' ||
                        state.matchedLocation == '/signup' ||
                        state.matchedLocation == '/forgot-password' ||
                        state.matchedLocation.startsWith('/reset-password');
    final isHomeOrDashboard = state.matchedLocation == '/' ||
                               state.matchedLocation == '/dashboard' ||
                               state.matchedLocation == '/home';

    // If user has selected a role and tries to go to onboarding, redirect to appropriate page
    if (hasSelectedRole && isOnboarding) {
      return userRoleService.isArtist ? '/dashboard' : '/home';
    }

    // Allow navigation to home/dashboard if role is selected
    if (hasSelectedRole && isHomeOrDashboard) {
      return null; // Allow navigation
    }

    // Allow auth routes always
    if (isAuthRoute) {
      return null;
    }

    // If user hasn't selected a role and tries to access protected routes, redirect to onboarding
    if (!hasSelectedRole && !isOnboarding) {
      return '/onboarding';
    }

    return null;
  },
  routes: [
    // Onboarding & Auth
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    // Auth routes
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordPage(
        token: state.uri.queryParameters['token'],
        email: state.uri.queryParameters['email'],
      ),
    ),
    // Search
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    // Main App - Home/Explore page for clients
    GoRoute(
      path: '/home',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/artists',
      builder: (context, state) => const ArtistsListPage(),
    ),
    GoRoute(
      path: '/artist/:id',
      builder: (context, state) {
        final artistId = state.pathParameters['id']!;
        return ArtistViewProfilePage(artistId: artistId);
      },
    ),
    GoRoute(
      path: '/profile/:id',
      builder: (context, state) => ProfilePage(artistId: state.pathParameters['id']!),
    ),

    // Dashboard & Management
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const ArtistDashboardPage(),
    ),
    GoRoute(
      path: '/manager',
      redirect: (context, state) => '/dashboard',
    ),
    GoRoute(
      path: '/profile',
      redirect: (context, state) => '/profile-settings',
    ),
    GoRoute(
      path: '/profile-settings',
      builder: (context, state) => const ProfileSettingsPage(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/my-bookings',
      builder: (context, state) => const MyBookingsPage(),
    ),
    GoRoute(
      path: '/saved-artists',
      builder: (context, state) => const SavedArtistsPage(),
    ),

    // Booking Flow
    GoRoute(
      path: '/booking/:id',
      builder: (context, state) => BookingPage(artistId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/booking-flow/:id',
      builder: (context, state) => BookingFlowPage(
        artistId: state.pathParameters['id']!,
        artistName: state.uri.queryParameters['artistName'],
        serviceName: state.uri.queryParameters['serviceName'],
        servicePrice: double.tryParse(state.uri.queryParameters['price'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/book/:id',
      redirect: (context, state) => '/booking-flow/${state.pathParameters['id']}',
    ),

    // Messages & Bookings screens
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesPage(),
    ),
    GoRoute(
      path: '/bookings',
      redirect: (context, state) => '/',
    ),
    GoRoute(
      path: '/settings',
      redirect: (context, state) => '/profile-settings',
    ),
  ],
);

