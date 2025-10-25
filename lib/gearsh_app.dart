import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'theme.dart';

class GearshApp extends ConsumerWidget {
  const GearshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Gearsh',
      routerConfig: router,
      theme: appTheme,
    );
  }
}
