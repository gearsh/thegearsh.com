import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      debugShowCheckedModeBanner: false,
      // Disable text scaling to keep consistent UI across devices
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Scroll behavior for web
      scrollBehavior: kIsWeb
          ? const MaterialScrollBehavior().copyWith(
              scrollbars: false,
              physics: const BouncingScrollPhysics(),
            )
          : null,
    );
  }
}
