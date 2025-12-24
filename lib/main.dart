// The Gearsh App - lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gearsh_app/firebase_options.dart';
import 'package:gearsh_app/gearsh_app.dart';

void main() async {
  // Ensuring Flutter widgets are initialized before running the Gearsh app.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  // All Riverpod providers will be accessible throughout the GearshApp widget tree.
  runApp(
    const ProviderScope(
      child: GearshApp(),
    ),
  );
}
