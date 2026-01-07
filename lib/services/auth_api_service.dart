import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/config/api_config.dart';
import 'package:gearsh_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth state
class AuthUser {
  final String userId;
  final String email;
  final String userType;
  final String firstName;
  final String lastName;
  final String? displayName;
  final String? profilePictureUrl;
  final bool isVerified;
  final String? artistProfileId;
  final String token;

  AuthUser({
    required this.userId,
    required this.email,
    required this.userType,
    required this.firstName,
    required this.lastName,
    this.displayName,
    this.profilePictureUrl,
    this.isVerified = false,
    this.artistProfileId,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id'],
      email: json['email'],
      userType: json['user_type'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      displayName: json['display_name'],
      profilePictureUrl: json['profile_picture_url'],
      isVerified: json['is_verified'] ?? false,
      artistProfileId: json['artist_profile']?['id'],
      token: json['token'],
    );
  }

  String get fullName => displayName ?? '$firstName $lastName';
  bool get isArtist => userType == 'artist';
}

/// Auth API service provider
final authApiServiceProvider = Provider((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AuthApiService(apiService);
});

/// Current user notifier
class CurrentUserNotifier extends Notifier<AuthUser?> {
  @override
  AuthUser? build() => null;

  void setUser(AuthUser user) => state = user;
  void clearUser() => state = null;
}

/// Current user state provider
final currentUserProvider = NotifierProvider<CurrentUserNotifier, AuthUser?>(CurrentUserNotifier.new);

/// Auth loading notifier
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool value) => state = value;
}

/// Auth loading state
final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(AuthLoadingNotifier.new);

/// Auth API service
class AuthApiService {
  final ApiService _apiService;
  static const String _tokenKey = 'gearsh_auth_token';
  static const String _userKey = 'gearsh_user_data';

  AuthApiService(this._apiService);

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String userType = 'client',
    String? phone,
    String? location,
    String? country,
  }) async {
    final response = await _apiService.post(
      ApiConfig.authRegister,
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'user_type': userType,
        'phone': phone,
        'location': location,
        'country': country,
      },
    );

    if (response.success && response.data != null) {
      final user = AuthUser.fromJson(response.data['data']);
      await _saveAuthData(user);
      _apiService.setAuthToken(user.token);
      return AuthResult.success(user);
    }

    return AuthResult.failure(response.error ?? 'Registration failed');
  }

  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.authLogin,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      final user = AuthUser.fromJson(response.data['data']);
      await _saveAuthData(user);
      _apiService.setAuthToken(user.token);
      return AuthResult.success(user);
    }

    return AuthResult.failure(response.error ?? 'Login failed');
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _apiService.clearAuthToken();
  }

  /// Check if user is logged in and restore session
  Future<AuthUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userKey);

      if (token != null && userData != null) {
        // Decode and validate token
        final payload = _decodeToken(token);
        if (payload != null && payload['exp'] > DateTime.now().millisecondsSinceEpoch) {
          _apiService.setAuthToken(token);
          // In production, you'd validate the token with the server
          // For now, we'll just restore from cached data
          return null; // Return user from cache or fetch from server
        }
      }
    } catch (e) {
      // Session restore failed, user will need to login again
    }
    return null;
  }

  /// Save auth data to local storage
  Future<void> _saveAuthData(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    // In production, encrypt sensitive data
  }

  /// Decode JWT-like token
  Map<String, dynamic>? _decodeToken(String token) {
    try {
      final decoded = utf8.decode(base64Decode(token));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return json;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Auth result wrapper
class AuthResult {
  final bool success;
  final AuthUser? user;
  final String? error;

  AuthResult._({required this.success, this.user, this.error});

  factory AuthResult.success(AuthUser user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}

