import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/user_role.dart';
import 'package:gearsh_app/routes/app_router.dart' show router;
import 'package:gearsh_app/services/user_role_service.dart';

void main() {
  setUp(() {
    userRoleService.setGuestRole(UserRole.client);
  });

  tearDown(() {
    userRoleService.logout();
  });

  testWidgets('router resolves /login', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/login');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('router resolves /artists', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/artists');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Artists'), findsOneWidget);
  });
}
