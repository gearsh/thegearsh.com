import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;

/// Service for handling Google and Apple Sign-In
class SocialAuthService {
  // Google Sign-In instance
  // Add your Web Client ID from Google Cloud Console
  static const String _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // For web, you need to provide the client ID
    clientId: kIsWeb ? _webClientId : null,
  );

  // API base URL
  static const String _apiBaseUrl = 'https://thegearsh-com.pages.dev/api';

  /// Sign in with Google
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return SocialAuthResult.cancelled();
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create user data from Google account
      final userData = SocialUserData(
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first ?? '',
        lastName: googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        photoUrl: googleUser.photoUrl,
        providerId: googleUser.id,
        provider: 'google',
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Register/login with backend
      final result = await _authenticateWithBackend(userData);

      return result;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return SocialAuthResult.error('Failed to sign in with Google: ${e.toString()}');
    }
  }

  /// Sign in with Apple
  Future<SocialAuthResult> signInWithApple() async {
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        webAuthenticationOptions: kIsWeb
            ? WebAuthenticationOptions(
                clientId: 'com.gearsh.app.web', // Your Service ID from Apple Developer
                redirectUri: Uri.parse('https://thegearsh-com.pages.dev/api/auth/apple-callback'),
              )
            : null,
      );

      // Apple only returns name on first sign-in, so we need to handle this
      final firstName = credential.givenName ?? '';
      final lastName = credential.familyName ?? '';

      // Create user data from Apple credential
      final userData = SocialUserData(
        email: credential.email ?? '',
        firstName: firstName,
        lastName: lastName,
        photoUrl: null,
        providerId: credential.userIdentifier ?? '',
        provider: 'apple',
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Register/login with backend
      final result = await _authenticateWithBackend(userData);

      return result;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return SocialAuthResult.cancelled();
      }
      debugPrint('Apple Sign-In authorization error: ${e.message}');
      return SocialAuthResult.error('Apple Sign-In failed: ${e.message}');
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      return SocialAuthResult.error('Failed to sign in with Apple: ${e.toString()}');
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Authenticate with backend API
  Future<SocialAuthResult> _authenticateWithBackend(SocialUserData userData) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/social-auth'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': userData.email,
          'first_name': userData.firstName,
          'last_name': userData.lastName,
          'photo_url': userData.photoUrl,
          'provider': userData.provider,
          'provider_id': userData.providerId,
          'id_token': userData.idToken,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return SocialAuthResult.success(
          userData: userData,
          isNewUser: body['is_new_user'] ?? false,
        );
      } else {
        final body = jsonDecode(response.body);
        return SocialAuthResult.error(body['error'] ?? 'Authentication failed');
      }
    } catch (e) {
      debugPrint('Backend auth error: $e');
      // If backend fails, still allow login with social data
      // You might want to handle this differently based on your requirements
      return SocialAuthResult.success(
        userData: userData,
        isNewUser: true,
      );
    }
  }

  /// Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Result of social authentication
class SocialAuthResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final SocialUserData? userData;
  final bool isNewUser;

  SocialAuthResult._({
    required this.success,
    this.cancelled = false,
    this.error,
    this.userData,
    this.isNewUser = false,
  });

  factory SocialAuthResult.success({
    required SocialUserData userData,
    bool isNewUser = false,
  }) {
    return SocialAuthResult._(
      success: true,
      userData: userData,
      isNewUser: isNewUser,
    );
  }

  factory SocialAuthResult.error(String message) {
    return SocialAuthResult._(
      success: false,
      error: message,
    );
  }

  factory SocialAuthResult.cancelled() {
    return SocialAuthResult._(
      success: false,
      cancelled: true,
    );
  }
}

/// User data from social sign-in
class SocialUserData {
  final String email;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String providerId;
  final String provider;
  final String? idToken;
  final String? accessToken;

  SocialUserData({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.providerId,
    required this.provider,
    this.idToken,
    this.accessToken,
  });

  String get fullName => '$firstName $lastName'.trim();
}

