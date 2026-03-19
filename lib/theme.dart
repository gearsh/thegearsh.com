import 'package:flutter/material.dart';

// ── Gearsh Design System ──────────────────────────────────
// Palette: slate-950 bg, sky/cyan accents, Syne headings
const Color primaryColor = Color(0xFF0EA5E9);     // sky-500
const Color lightBlueAccent = Color(0xFF38BDF8);   // sky-400
const Color darkBackgroundColor = Color(0xFF020617); // slate-950
const Color cardBackgroundColor = Color(0xFF111827); // gray-900
const Color secondaryTextColor = Color(0xFFE2E8F0); // slate-200
const Color surfaceColor = Color(0xFF0F172A);        // slate-900
const Color borderColor = Color(0x12FFFFFF);

final appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: darkBackgroundColor,
  fontFamily: 'DM Sans',
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: lightBlueAccent,
    surface: cardBackgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF020617),
    elevation: 0,
    centerTitle: false,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: 'Syne',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.3,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Syne', fontSize: 36,
      fontWeight: FontWeight.w800, color: Colors.white,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Syne', fontSize: 32,
      fontWeight: FontWeight.w800, color: Colors.white,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Syne', fontSize: 28,
      fontWeight: FontWeight.w700, color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Syne', fontSize: 24,
      fontWeight: FontWeight.w700, color: Colors.white,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Syne', fontSize: 20,
      fontWeight: FontWeight.w700, color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: secondaryTextColor,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)), // slate-400
    bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
    bodySmall: TextStyle(fontSize: 12, color: Color(0xFF64748B)), // slate-500
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: lightBlueAccent,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(color: Colors.white.withAlpha(38)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E293B).withAlpha(128), // slate-800
    hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 14),
    labelStyle: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
    floatingLabelStyle: const TextStyle(
      color: lightBlueAccent, fontWeight: FontWeight.w500,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primaryColor.withAlpha(51), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red.withAlpha(128), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  cardTheme: CardThemeData(
    color: cardBackgroundColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: borderColor),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: borderColor,
    thickness: 1,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: lightBlueAccent,
    unselectedLabelColor: Colors.white.withAlpha(90),
    indicatorColor: primaryColor,
    labelStyle: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w400,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0F172A),
    selectedItemColor: lightBlueAccent,
    unselectedItemColor: Color(0xFF64748B),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF0F172A),
    selectedColor: primaryColor.withAlpha(38),
    labelStyle: const TextStyle(fontSize: 13, color: Colors.white),
    secondaryLabelStyle: const TextStyle(fontSize: 13, color: Colors.white),
    side: BorderSide(color: Colors.white.withAlpha(25)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: primaryColor,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF0F172A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF0F172A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
);
