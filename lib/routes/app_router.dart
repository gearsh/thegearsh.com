import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/screens/premium_onboarding.dart';
import 'package:gearsh_app/screens/faq_page.dart';
import 'package:gearsh_app/screens/privacy_policy_page.dart';
import 'package:gearsh_app/screens/terms_of_service_page.dart';
import 'package:gearsh_app/features/error/error_page.dart';
import 'package:gearsh_app/features/signups/artists_list_page.dart';
import 'package:gearsh_app/features/profile/profile_page.dart';
import 'package:gearsh_app/features/profile/artist_view_profile_page.dart';
import 'package:gearsh_app/features/dashboard/artist_dashboard_page.dart';
import 'package:gearsh_app/features/dashboard/artist_verification_page.dart';
import 'package:gearsh_app/features/profile/help_center_page.dart';
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
import 'package:gearsh_app/features/discover/discover_page.dart';
import 'package:gearsh_app/features/discover/map_page.dart';
import '../features/discover/category_artists_page.dart';
import 'package:gearsh_app/features/gigs/gigs_page.dart';
import 'package:gearsh_app/features/cart/cart_page.dart';
import 'package:gearsh_app/features/cart/cart_checkout_page.dart';
import 'package:gearsh_app/features/cart/cart_success_page.dart';
import 'package:gearsh_app/features/admin/import_twitter_artists_page.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/widgets/swipe_back_wrapper.dart';

/// Custom page transition for smooth navigation
/// All pages are wrapped with EdgeSwipeBackWrapper for swipe-right-to-go-back
CustomTransitionPage<T> buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  TransitionType type = TransitionType.fade,
  bool enableSwipeBack = true,
}) {
  // Wrap the child with swipe back functionality
  final wrappedChild = enableSwipeBack
      ? EdgeSwipeBackWrapper(child: child)
      : child;

  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: wrappedChild,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (type) {
        case TransitionType.fade:
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        case TransitionType.slideUp:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
          );
        case TransitionType.slideRight:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        case TransitionType.scale:
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        case TransitionType.none:
          return child;
      }
    },
  );
}

/// Transition types for different navigation contexts
enum TransitionType {
  fade,
  slideUp,
  slideRight,
  scale,
  none,
}

final GoRouter router = GoRouter(
  // Start with onboarding
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
    // Onboarding & Auth - use fade transition
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const GearshPremiumOnboarding(),
        type: TransitionType.fade,
      ),
    ),
    // Auth routes - slide up for modal feel
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const SignupPage(),
        type: TransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const LoginPage(),
        type: TransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const ForgotPasswordPage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: ResetPasswordPage(
          token: state.uri.queryParameters['token'],
          email: state.uri.queryParameters['email'],
        ),
        type: TransitionType.slideRight,
      ),
    ),
    // Search - slide up
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const SearchScreen(),
        type: TransitionType.slideUp,
      ),
    ),
    // Gigs page for fans - fade for tab switching feel
    GoRoute(
      path: '/gigs',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const GigsPage(),
        type: TransitionType.fade,
      ),
    ),
    // Cart pages - slide up for modal/overlay feel
    GoRoute(
      path: '/cart',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const CartPage(),
        type: TransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/cart/checkout',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const CartCheckoutPage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/cart/success',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const CartSuccessPage(),
        type: TransitionType.scale,
      ),
    ),
    // Main App - Home/Explore page for clients - fade for instant feel
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const DiscoverPage(),
        type: TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const DiscoverPage(),
        type: TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/discover/map',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const MapPage(),
        type: TransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/artists',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const ArtistsListPage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/artist/:id',
      pageBuilder: (context, state) {
        final artistId = state.pathParameters['id']!;
        return buildPageWithTransition(
          context: context,
          state: state,
          child: ArtistViewProfilePage(artistId: artistId),
          type: TransitionType.slideRight,
        );
      },
    ),
    GoRoute(
      path: '/category/:name',
      pageBuilder: (context, state) {
        final name = state.pathParameters['name']!;
        return buildPageWithTransition(
          context: context,
          state: state,
          child: categoryArtistsPageBuilder(name),
          type: TransitionType.slideRight,
        );
      },
    ),
    GoRoute(
      path: '/profile/:id',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: ProfilePage(artistId: state.pathParameters['id']!),
        type: TransitionType.slideRight,
      ),
    ),

    // Dashboard & Management
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const ArtistDashboardPage(),
        type: TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/dashboard/verification',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const ArtistVerificationPage(),
        type: TransitionType.slideRight,
      ),
    ),
    // Admin - Import Twitter Artists
    GoRoute(
      path: '/admin/import-twitter',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const ImportTwitterArtistsPage(),
        type: TransitionType.slideUp,
      ),
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
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const ProfileSettingsPage(),
        type: TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const EditProfilePage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/my-bookings',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const MyBookingsPage(),
        type: TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/saved-artists',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const SavedArtistsPage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/help',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const HelpCenterPage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/faq',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const FAQPage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const PrivacyPolicyPage(),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/terms',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const TermsOfServicePage(),
        type: TransitionType.slideRight,
      ),
    ),

    // Booking Flow - slide right for flow progression
    GoRoute(
      path: '/booking/:id',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: BookingPage(artistId: state.pathParameters['id']!),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/booking-flow/:id',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: BookingFlowPage(
          artistId: state.pathParameters['id']!,
          artistName: state.uri.queryParameters['artistName'],
          serviceName: state.uri.queryParameters['serviceName'],
          servicePrice: double.tryParse(state.uri.queryParameters['price'] ?? ''),
          serviceId: state.uri.queryParameters['service'],
        ),
        type: TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/book/:id',
      redirect: (context, state) => '/booking-flow/${state.pathParameters['id']}',
    ),

    // Messages & Bookings screens - fade for tab-like navigation
    GoRoute(
      path: '/messages',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const MessagesPage(),
        type: TransitionType.fade,
      ),
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
