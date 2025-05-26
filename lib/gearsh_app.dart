// lib/gearsh_app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/app_router.dart'; // Your GoRouter config
// Optional: custom theme file

class GearshApp extends ConsumerWidget {
  const GearshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider); // Assuming you use a Riverpod GoRouter provider

    return MaterialApp.router(
      title: 'Gearsh - Turn Art Into Power',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: Colors.black,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Segoe UI',
        ),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}