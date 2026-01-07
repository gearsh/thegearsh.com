// The Gearsh App - lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gearsh_app/firebase_options.dart';
import 'package:gearsh_app/gearsh_app.dart';
import 'package:gearsh_app/services/global_config_service.dart';

// Import Crashlytics conditionally
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'dart:async'; // Web fallback

void main() async {
  await runZonedGuarded(() async {
    // Ensuring Flutter widgets are initialized before running the Gearsh app.
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize global configuration (region, currency, etc.)
    await globalConfigService.init();

    // Initialize Crashlytics (not on web)
    if (!kIsWeb) {
      try {
        // Pass all uncaught "fatal" errors from the framework to Crashlytics
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };

        // Enable Crashlytics data collection (disabled for debug)
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      } catch (e) {
        debugPrint('Crashlytics initialization failed: $e');
      }
    }

    // Use path URL strategy for web (removes # from URLs)
    usePathUrlStrategy();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF020617),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Running the Gearsh app within a ProviderScope, for Riverpod.
    runApp(
      const ProviderScope(
        child: GearshApp(),
      ),
    );
  }, (error, stack) {
    // Pass all uncaught asynchronous errors to Crashlytics
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (e) {
        debugPrint('Failed to record error: $e');
      }
    }
  });
}
