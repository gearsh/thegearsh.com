import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration for Gearsh app
class ApiConfig {
  // Production API (custom domain)
  static const String baseUrl = 'https://thegearsh.com/api';

  // Fallback Pages URL
  static const String pagesDevUrl = 'https://thegearsh-com.pages.dev/api';

  // Development URL (for local testing)
  // Android emulator uses 10.0.2.2 to access host machine
  static String get devBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8788/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8788/api';
      }
    } catch (_) {}
    return 'http://localhost:8788/api';
  }

  // Use development mode
  static const bool isDevelopment = false;

  static String get apiBaseUrl => isDevelopment ? devBaseUrl : baseUrl;

  // API Endpoints
  static const String artists = '/artists';
  static const String search = '/search';
  static const String bookings = '/bookings';
  static const String reviews = '/reviews';
  static const String signup = '/signup';
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String users = '/users';
  static const String health = '/health';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

