// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gearsh_app/core/di/service_providers.dart';
import 'package:gearsh_app/firebase_options.dart';
import 'package:gearsh_app/gearsh_app.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:gearsh_app/crashlytics_stub.dart';
import 'package:gearsh_app/providers/user_role_provider.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final sharedPreferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
    await container.read(appBootstrapProvider.future);
    bindUserRoleNotifier(container.read(userRoleProvider.notifier));
    userRoleService.syncFromState(container.read(userRoleProvider));
    container.listen(userRoleProvider, (_, next) {
      userRoleService.syncFromState(next);
    });

    if (!kIsWeb) {
      try {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      } catch (e) {
        debugPrint('Crashlytics initialization failed: $e');
      }
    }

    usePathUrlStrategy();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF020617),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const GearshApp(),
      ),
    );
  }, (error, stack) {
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (e) {
        debugPrint('Failed to record error: $e');
      }
    }
  });
}
