import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/widgets/custom_app_bar.dart';

void main() {
  testWidgets('CustomAppBar preferredSize accounts for bottom height', (WidgetTester tester) async {
    // Minimal router so GoRouter.of(context) calls inside CustomAppBar succeed
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('home'))),
      ],
    );

    final bottom = PreferredSize(preferredSize: const Size.fromHeight(48), child: Container());
    final appBar = CustomAppBar(title: 'Test', bottom: bottom);

    // The preferredSize getter should include kToolbarHeight + bottom height
    expect(appBar.preferredSize.height, equals(kToolbarHeight + 48));

    // Also ensure the widget builds inside a router-scoped MaterialApp
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Build a Scaffold that uses the CustomAppBar so we exercise the AppBar build method
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => Scaffold(appBar: CustomAppBar(title: '', bottom: bottom), body: const SizedBox.shrink()),
    ));
    await tester.pumpAndSettle();

    // Sanity: AppBar is present
    expect(find.byType(CustomAppBar), findsOneWidget);
  });
}

