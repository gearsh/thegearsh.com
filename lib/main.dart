// The Gearsh App - lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/gearsh_app.dart';

void main() async {
  // Ensuring Flutter widgets are initialized before running the Gearsh app.
  WidgetsFlutterBinding.ensureInitialized();

  // Running the Gearsh app within a ProviderScope, for Riverpod.
  // All Riverpod providers will be accessible throughout the GearshApp widget tree.
  runApp(
    const ProviderScope(
      child: GearshApp(),
    ),
  );
}
