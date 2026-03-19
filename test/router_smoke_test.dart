import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearsh_app/routes/app_router.dart' show router;
import 'package:gearsh_app/services/user_role_service.dart';

void main() {
  // The global router starts at /onboarding. Pages like OnboardingPage and
  // LoginPage use repeating AnimationControllers, so pumpAndSettle() will
  // never complete.  Use pump(duration) for those pages instead.

  setUp(() {
    // Give the service a guest role so the redirect guard allows /artists
    userRoleService.setGuestRole(UserRole.client);
  });

  tearDown(() {
    userRoleService.logout();
  });

  testWidgets('router resolves /login', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/login');
    // LoginPage has a repeating glow animation — use pump with a duration
    await tester.pump(const Duration(milliseconds: 500));

    // LoginPage contains large "Login" text inside a ShaderMask
    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('router resolves /artists', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/artists');
    // ArtistsListPage has no repeating animations, but the page transition
    // may still be running — pump a fixed duration to be safe.
    await tester.pump(const Duration(milliseconds: 500));

    // ArtistsListPage uses a CustomAppBar with title 'Artists'
    expect(find.text('Artists'), findsOneWidget);
  });
}
