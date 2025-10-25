import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearsh_app/routes/app_router.dart' show router;

void main() {
  testWidgets('router resolves /login and /artists', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // Navigate to login
    router.go('/login');
    await tester.pumpAndSettle();

    // LoginPage contains large "Login" text inside a ShaderMask
    expect(find.text('Login'), findsWidgets);

    // Navigate to artists
    router.go('/artists');
    await tester.pumpAndSettle();

    // ArtistsListPage uses a CustomAppBar with title 'Artists'
    expect(find.text('Artists'), findsOneWidget);
  });
}

