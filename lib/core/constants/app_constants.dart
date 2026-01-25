// Gearsh App - Core: App Constants
// Centralized constants for the application

/// App-wide configuration constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  /// App name
  static const String appName = 'Gearsh';

  /// App version
  static const String appVersion = '1.0.0';

  /// Mastery system constants
  static const int masteryMaxHours = 10000;
  static const int masteryNewcomerMax = 99;
  static const int masteryRisingMin = 100;
  static const int masteryRisingMax = 499;
  static const int masteryEstablishedMin = 500;
  static const int masteryEstablishedMax = 1999;
  static const int masteryProfessionalMin = 2000;
  static const int masteryProfessionalMax = 4999;
  static const int masteryExpertMin = 5000;
  static const int masteryExpertMax = 7499;
  static const int masteryMasterMin = 7500;
  static const int masteryMasterMax = 9999;
  static const int masteryLegendMin = 10000;

  /// Default values
  static const String defaultCurrency = 'ZAR';
  static const String defaultCountry = 'ZA';
  static const double defaultServiceFeePercent = 10.0;

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Cache durations (in seconds)
  static const int cacheDurationShort = 300; // 5 minutes
  static const int cacheDurationMedium = 1800; // 30 minutes
  static const int cacheDurationLong = 86400; // 24 hours

  /// Timeouts (in seconds)
  static const int apiTimeout = 30;
  static const int uploadTimeout = 120;

  /// Image sizes
  static const int thumbnailSize = 150;
  static const int profileImageSize = 400;
  static const int coverImageSize = 1200;

  /// Validation limits
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;
  static const int maxServiceDescriptionLength = 1000;
}

/// API endpoints
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.gearsh.com';
  static const String v1 = '/v1';

  // Auth
  static const String login = '$v1/auth/login';
  static const String register = '$v1/auth/register';
  static const String logout = '$v1/auth/logout';
  static const String refreshToken = '$v1/auth/refresh';
  static const String forgotPassword = '$v1/auth/forgot-password';
  static const String resetPassword = '$v1/auth/reset-password';

  // Artists
  static const String artists = '$v1/artists';
  static String artist(String id) => '$v1/artists/$id';
  static const String featuredArtists = '$v1/artists/featured';
  static const String searchArtists = '$v1/artists/search';

  // Bookings
  static const String bookings = '$v1/bookings';
  static String booking(String id) => '$v1/bookings/$id';

  // Users
  static const String users = '$v1/users';
  static String user(String id) => '$v1/users/$id';
  static const String profile = '$v1/users/me';
}

/// Route paths for navigation
class RoutePaths {
  RoutePaths._();

  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String profileSettings = '/profile-settings';
  static const String editProfile = '/edit-profile';
  static const String discover = '/discover';
  static const String search = '/search';
  static const String messages = '/messages';
  static const String bookings = '/bookings';
  static const String cart = '/cart';
  static const String gigs = '/gigs';
  static String artist(String id) => '/artist/$id';
  static String bookingFlow(String artistId) => '/booking-flow/$artistId';
  static String category(String name) => '/category/$name';
}

/// Storage keys for local storage
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String hasOnboarded = 'has_onboarded';
  static const String selectedCurrency = 'selected_currency';
  static const String selectedLanguage = 'selected_language';
  static const String themeMode = 'theme_mode';
  static const String cachedArtists = 'cached_artists';
  static const String savedArtists = 'saved_artists';
  static const String recentSearches = 'recent_searches';
}
