import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF00BFFF);
const Color lightBlueAccent = Colors.lightBlueAccent;
const Color darkBackgroundColor = Color(0xFF111111);
const Color cardBackgroundColor = Color(0xFF212121);
const Color secondaryTextColor = Color(0xFFEEEEEE);

final appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: darkBackgroundColor,
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: lightBlueAccent,
    // background: darkBackgroundColor, // `background` is deprecated in favor of `surface`/`onSurface`.
    // scaffoldBackgroundColor is already set above to `darkBackgroundColor`.
    surface: cardBackgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor),
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
    displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: secondaryTextColor),
    bodyLarge: TextStyle(fontSize: 18, color: Colors.grey),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: const StadiumBorder(),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: const StadiumBorder(),
      side: BorderSide(color: Colors.grey[700]!),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF222222),
    hintStyle: TextStyle(color: primaryColor),
    labelStyle: TextStyle(color: primaryColor),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 1),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    color: cardBackgroundColor,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
);
