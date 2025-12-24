// The Gearsh App - lib/services/firebase_auth_service.dart
// Hybrid Authentication: Firebase Auth + Cloudflare D1 backend

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Firebase Authentication Service for Gearsh
/// Uses Firebase for auth, syncs with Cloudflare D1 backend
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static const String _apiBaseUrl = 'https://thegearsh-com.pages.dev/api';

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign in with email and password
  Future<FirebaseAuthResult> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Sync with Cloudflare backend
        await _syncUserWithBackend(credential.user!);

        return FirebaseAuthResult.success(
          user: credential.user!,
          isNewUser: false,
        );
      }

      return FirebaseAuthResult.error('Sign in failed');
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return FirebaseAuthResult.error('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  Future<FirebaseAuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name if provided
        if (firstName != null || lastName != null) {
          final displayName = [firstName, lastName].where((n) => n != null && n.isNotEmpty).join(' ');
          if (displayName.isNotEmpty) {
            await credential.user!.updateDisplayName(displayName);
          }
        }

        // Create user in Cloudflare D1 backend
        await _createUserInBackend(
          credential.user!,
          username: username,
          firstName: firstName,
          lastName: lastName,
        );

        return FirebaseAuthResult.success(
          user: credential.user!,
          isNewUser: true,
        );
      }

      return FirebaseAuthResult.error('Sign up failed');
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return FirebaseAuthResult.error('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in with Google
  Future<FirebaseAuthResult> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return FirebaseAuthResult.cancelled();
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // Sync with Cloudflare backend
        if (isNewUser) {
          await _createUserInBackend(
            userCredential.user!,
            provider: 'google',
            providerId: googleUser.id,
          );
        } else {
          await _syncUserWithBackend(userCredential.user!);
        }

        return FirebaseAuthResult.success(
          user: userCredential.user!,
          isNewUser: isNewUser,
        );
      }

      return FirebaseAuthResult.error('Google Sign-In failed');
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return FirebaseAuthResult.error('Failed to sign in with Google: ${e.toString()}');
    }
  }

  /// Sign in with Apple (iOS/macOS/Web)
  Future<FirebaseAuthResult> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await _firebaseAuth.signInWithPopup(appleProvider);
      } else {
        userCredential = await _firebaseAuth.signInWithProvider(appleProvider);
      }

      if (userCredential.user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // Sync with Cloudflare backend
        if (isNewUser) {
          await _createUserInBackend(
            userCredential.user!,
            provider: 'apple',
            providerId: userCredential.user!.uid,
          );
        } else {
          await _syncUserWithBackend(userCredential.user!);
        }

        return FirebaseAuthResult.success(
          user: userCredential.user!,
          isNewUser: isNewUser,
        );
      }

      return FirebaseAuthResult.error('Apple Sign-In failed');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'popup-closed-by-user') {
        return FirebaseAuthResult.cancelled();
      }
      return FirebaseAuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      return FirebaseAuthResult.error('Failed to sign in with Apple: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  /// Create user in Cloudflare D1 backend
  Future<void> _createUserInBackend(
    User user, {
    String? username,
    String? firstName,
    String? lastName,
    String? provider,
    String? providerId,
  }) async {
    try {
      // Parse display name if not provided
      final nameParts = (user.displayName ?? '').split(' ');
      final fName = firstName ?? (nameParts.isNotEmpty ? nameParts.first : '');
      final lName = lastName ?? (nameParts.length > 1 ? nameParts.skip(1).join(' ') : '');

      // Get Firebase ID token for backend verification
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/firebase-sync'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'firebase_uid': user.uid,
          'email': user.email,
          'username': username ?? user.email?.split('@').first,
          'first_name': fName,
          'last_name': lName,
          'photo_url': user.photoURL,
          'provider': provider ?? 'email',
          'provider_id': providerId,
          'is_new_user': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Backend sync failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to create user in backend: $e');
      // Don't throw - auth succeeded, backend sync can be retried
    }
  }

  /// Sync existing user with Cloudflare D1 backend
  Future<void> _syncUserWithBackend(User user) async {
    try {
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/firebase-sync'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'firebase_uid': user.uid,
          'email': user.email,
          'photo_url': user.photoURL,
          'is_new_user': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Backend sync failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to sync user with backend: $e');
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again';
      default:
        return 'Authentication error: $code';
    }
  }
}

/// Result of Firebase authentication
class FirebaseAuthResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final User? user;
  final bool isNewUser;

  FirebaseAuthResult._({
    required this.success,
    this.cancelled = false,
    this.error,
    this.user,
    this.isNewUser = false,
  });

  factory FirebaseAuthResult.success({
    required User user,
    bool isNewUser = false,
  }) {
    return FirebaseAuthResult._(
      success: true,
      user: user,
      isNewUser: isNewUser,
    );
  }

  factory FirebaseAuthResult.error(String message) {
    return FirebaseAuthResult._(
      success: false,
      error: message,
    );
  }

  factory FirebaseAuthResult.cancelled() {
    return FirebaseAuthResult._(
      success: false,
      cancelled: true,
    );
  }
}

