/// Gearsh Authentication API Service
/// Complete auth management with Firebase + Backend sync

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gearsh_app/services/api_client.dart';
import 'package:gearsh_app/services/error_handling.dart';

/// Provider for auth API service
final authApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApiService(apiClient);
});

/// User model
class GearshUser {
  final String id;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'client', 'artist', 'fan', 'admin'
  final bool isVerified;
  final bool isEmailVerified;
  final String? provider; // 'email', 'google', 'apple'
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  const GearshUser({
    required this.id,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.displayName,
    this.photoUrl,
    required this.role,
    this.isVerified = false,
    this.isEmailVerified = false,
    this.provider,
    required this.createdAt,
    this.lastLoginAt,
    this.metadata,
  });

  String get fullName {
    if (firstName != null || lastName != null) {
      return [firstName, lastName].where((n) => n != null && n.isNotEmpty).join(' ');
    }
    return displayName ?? username ?? email.split('@').first;
  }

  factory GearshUser.fromJson(Map<String, dynamic> json) {
    return GearshUser(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      role: json['role'] as String? ?? 'client',
      isVerified: json['is_verified'] as bool? ?? false,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      provider: json['provider'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  factory GearshUser.fromFirebaseUser(User firebaseUser, {String role = 'client'}) {
    return GearshUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      role: role,
      isEmailVerified: firebaseUser.emailVerified,
      provider: firebaseUser.providerData.isNotEmpty
          ? firebaseUser.providerData.first.providerId
          : 'email',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role': role,
      'is_verified': isVerified,
      'is_email_verified': isEmailVerified,
      'provider': provider,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  GearshUser copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? displayName,
    String? photoUrl,
    String? role,
    bool? isVerified,
    bool? isEmailVerified,
    String? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return GearshUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final GearshUser? user;
  final String? token;
  final String? refreshToken;
  final bool isNewUser;
  final GearshException? error;

  const AuthResult._({
    required this.success,
    this.user,
    this.token,
    this.refreshToken,
    this.isNewUser = false,
    this.error,
  });

  factory AuthResult.success({
    required GearshUser user,
    String? token,
    String? refreshToken,
    bool isNewUser = false,
  }) {
    return AuthResult._(
      success: true,
      user: user,
      token: token,
      refreshToken: refreshToken,
      isNewUser: isNewUser,
    );
  }

  factory AuthResult.failure(GearshException error) {
    return AuthResult._(success: false, error: error);
  }

  factory AuthResult.cancelled() {
    return AuthResult._(
      success: false,
      error: const GearshException(message: 'Authentication cancelled', code: 'cancelled'),
    );
  }
}

/// Sign up request
class SignUpRequest {
  final String email;
  final String password;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String role;

  const SignUpRequest({
    required this.email,
    required this.password,
    this.username,
    this.firstName,
    this.lastName,
    this.role = 'client',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (username != null) 'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      'role': role,
    };
  }
}

/// Authentication API Service
class AuthApiService {
  final GearshApiClient _apiClient;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthApiService(this._apiClient);

  /// Get current Firebase user
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail(SignUpRequest request) async {
    try {
      // Create Firebase account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      if (credential.user == null) {
        return AuthResult.failure(
          const AuthException(message: 'Failed to create account'),
        );
      }

      // Update display name
      if (request.firstName != null || request.lastName != null) {
        final displayName = [request.firstName, request.lastName]
            .where((n) => n != null && n.isNotEmpty)
            .join(' ');
        if (displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }
      }

      // Sync with backend
      final backendResult = await _syncUserToBackend(
        firebaseUser: credential.user!,
        username: request.username,
        firstName: request.firstName,
        lastName: request.lastName,
        role: request.role,
        isNewUser: true,
      );

      if (!backendResult.isSuccess) {
        // Backend sync failed but Firebase account created
        // Log error but don't fail the signup
        ErrorHandler.logError(backendResult.error!);
      }

      // Get ID token
      final token = await credential.user!.getIdToken();

      final user = GearshUser.fromFirebaseUser(
        credential.user!,
        role: request.role,
      ).copyWith(
        username: request.username,
        firstName: request.firstName,
        lastName: request.lastName,
      );

      // Set token in API client
      _apiClient.setTokens(authToken: token ?? '');

      return AuthResult.success(
        user: user,
        token: token,
        isNewUser: true,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(ErrorHandler.fromException(e));
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure(AuthException.invalidCredentials());
      }

      // Sync with backend
      await _syncUserToBackend(
        firebaseUser: credential.user!,
        isNewUser: false,
      );

      // Get ID token
      final token = await credential.user!.getIdToken();

      // Fetch user details from backend
      final userResult = await _fetchUserFromBackend(credential.user!.uid);

      final user = userResult.isSuccess && userResult.data != null
          ? userResult.data!
          : GearshUser.fromFirebaseUser(credential.user!);

      // Set token in API client
      _apiClient.setTokens(authToken: token ?? '');

      return AuthResult.success(
        user: user,
        token: token,
        isNewUser: false,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(ErrorHandler.fromException(e));
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return AuthResult.failure(
          const AuthException(message: 'Google sign-in failed'),
        );
      }

      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Sync with backend
      await _syncUserToBackend(
        firebaseUser: userCredential.user!,
        provider: 'google',
        providerId: googleUser.id,
        isNewUser: isNewUser,
      );

      // Get ID token
      final token = await userCredential.user!.getIdToken();

      // Fetch user details from backend
      final userResult = await _fetchUserFromBackend(userCredential.user!.uid);

      final user = userResult.isSuccess && userResult.data != null
          ? userResult.data!
          : GearshUser.fromFirebaseUser(userCredential.user!);

      // Set token in API client
      _apiClient.setTokens(authToken: token ?? '');

      return AuthResult.success(
        user: user,
        token: token,
        isNewUser: isNewUser,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return AuthResult.failure(ErrorHandler.fromException(e));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _firebaseAuth.signOut();
    _apiClient.clearTokens();
  }

  /// Send password reset email
  Future<ApiResult<void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return ApiResult.success(null);
    } on FirebaseAuthException catch (e) {
      return ApiResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return ApiResult.failure(ErrorHandler.fromException(e));
    }
  }

  /// Update user profile
  Future<ApiResult<GearshUser>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return ApiResult.failure(AuthException.unauthorized());
      }

      // Update Firebase profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update backend
      return _apiClient.patch<GearshUser>(
        '/users/${user.uid}',
        body: {
          if (displayName != null) 'display_name': displayName,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (username != null) 'username': username,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
        parser: (data) => GearshUser.fromJson(data as Map<String, dynamic>),
        config: RequestConfig.authenticated,
      );
    } catch (e) {
      return ApiResult.failure(ErrorHandler.fromException(e));
    }
  }

  /// Refresh auth token
  Future<String?> refreshToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken(true);
      if (token != null) {
        _apiClient.setTokens(authToken: token);
      }
      return token;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return null;
    }
  }

  /// Delete account
  Future<ApiResult<void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return ApiResult.failure(AuthException.unauthorized());
      }

      // Delete from backend first
      final backendResult = await _apiClient.delete<void>(
        '/users/${user.uid}',
        config: RequestConfig.authenticated,
      );

      if (!backendResult.isSuccess) {
        return backendResult;
      }

      // Delete Firebase account
      await user.delete();
      _apiClient.clearTokens();

      return ApiResult.success(null);
    } on FirebaseAuthException catch (e) {
      return ApiResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return ApiResult.failure(ErrorHandler.fromException(e));
    }
  }

  /// Sync user to backend
  Future<ApiResult<void>> _syncUserToBackend({
    required User firebaseUser,
    String? username,
    String? firstName,
    String? lastName,
    String? role,
    String? provider,
    String? providerId,
    bool isNewUser = false,
  }) async {
    final endpoint = isNewUser ? '/auth/register' : '/auth/sync';

    return _apiClient.post<void>(
      endpoint,
      body: {
        'firebase_uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'display_name': firebaseUser.displayName,
        'photo_url': firebaseUser.photoURL,
        if (username != null) 'username': username,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (role != null) 'role': role,
        if (provider != null) 'provider': provider,
        if (providerId != null) 'provider_id': providerId,
      },
      parser: (_) {},
      config: RequestConfig.noRetry,
    );
  }

  /// Fetch user from backend
  Future<ApiResult<GearshUser>> _fetchUserFromBackend(String userId) async {
    return _apiClient.get<GearshUser>(
      '/users/$userId',
      parser: (data) => GearshUser.fromJson(data as Map<String, dynamic>),
      config: RequestConfig.authenticated,
    );
  }

  /// Map Firebase error to GearshException
  AuthException _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException.invalidCredentials();
      case 'email-already-in-use':
        return AuthException.emailInUse();
      case 'weak-password':
        return AuthException.weakPassword();
      case 'invalid-email':
        return const AuthException(
          message: 'Invalid email address',
          code: 'invalid_email',
          statusCode: 400,
        );
      case 'user-disabled':
        return const AuthException(
          message: 'This account has been disabled',
          code: 'user_disabled',
          statusCode: 403,
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Too many attempts. Please try again later',
          code: 'too_many_requests',
          statusCode: 429,
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'Network error. Please check your connection',
          code: 'network_error',
        );
      default:
        return AuthException(
          message: e.message ?? 'Authentication failed',
          code: e.code,
        );
    }
  }
}

