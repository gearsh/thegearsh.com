// Gearsh Backend Error Handling
// Centralized error types and handling for consistent error management

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Base exception for all Gearsh API errors
class GearshException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic originalError;

  const GearshException({
    required this.message,
    this.code,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'GearshException: $message (code: $code, status: $statusCode)';

  /// User-friendly error message
  String get userMessage {
    switch (code) {
      case 'network_error':
        return 'Please check your internet connection and try again.';
      case 'timeout':
        return 'The request took too long. Please try again.';
      case 'unauthorized':
        return 'Your session has expired. Please sign in again.';
      case 'forbidden':
        return 'You don\'t have permission to perform this action.';
      case 'not_found':
        return 'The requested resource was not found.';
      case 'validation_error':
        return message;
      case 'server_error':
        return 'Something went wrong on our end. Please try again later.';
      case 'rate_limited':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return message.isNotEmpty ? message : 'An unexpected error occurred.';
    }
  }

  /// Whether error is retryable
  bool get isRetryable {
    if (statusCode == null) return true; // Network errors are retryable
    if (statusCode! >= 500) return true; // Server errors
    if (code == 'timeout') return true;
    if (code == 'network_error') return true;
    return false;
  }
}

/// Network-related errors
class NetworkException extends GearshException {
  const NetworkException({
    super.message = 'Network error occurred',
    super.originalError,
  }) : super(
    code: 'network_error',
  );
}

/// Timeout errors
class TimeoutException extends GearshException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.originalError,
  }) : super(
    code: 'timeout',
  );
}

/// Authentication errors
class AuthException extends GearshException {
  const AuthException({
    required super.message,
    String? code,
    super.statusCode,
    super.originalError,
  }) : super(
    code: code ?? 'auth_error',
  );

  factory AuthException.unauthorized() => const AuthException(
    message: 'Unauthorized',
    code: 'unauthorized',
    statusCode: 401,
  );

  factory AuthException.forbidden() => const AuthException(
    message: 'Forbidden',
    code: 'forbidden',
    statusCode: 403,
  );

  factory AuthException.invalidCredentials() => const AuthException(
    message: 'Invalid email or password',
    code: 'invalid_credentials',
    statusCode: 401,
  );

  factory AuthException.emailInUse() => const AuthException(
    message: 'This email is already registered',
    code: 'email_in_use',
    statusCode: 409,
  );

  factory AuthException.weakPassword() => const AuthException(
    message: 'Password is too weak',
    code: 'weak_password',
    statusCode: 400,
  );

  factory AuthException.sessionExpired() => const AuthException(
    message: 'Your session has expired',
    code: 'session_expired',
    statusCode: 401,
  );
}

/// Validation errors
class ValidationException extends GearshException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors,
    super.originalError,
  }) : super(
    code: 'validation_error',
    statusCode: 400,
  );

  String? getFieldError(String field) => fieldErrors?[field];
}

/// Server errors
class ServerException extends GearshException {
  const ServerException({
    super.message = 'Server error occurred',
    int? statusCode,
    super.originalError,
  }) : super(
    code: 'server_error',
    statusCode: statusCode ?? 500,
  );
}

/// Rate limiting errors
class RateLimitException extends GearshException {
  final Duration? retryAfter;

  const RateLimitException({
    super.message = 'Too many requests',
    this.retryAfter,
    super.originalError,
  }) : super(
    code: 'rate_limited',
    statusCode: 429,
  );
}

/// Not found errors
class NotFoundException extends GearshException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.originalError,
  }) : super(
    code: 'not_found',
    statusCode: 404,
  );
}

/// Error handler utility
class ErrorHandler {
  /// Parse HTTP status code and response into appropriate exception
  static GearshException fromHttpResponse(int statusCode, dynamic body) {
    String message = 'An error occurred';
    String? code;
    Map<String, String>? fieldErrors;

    if (body is Map) {
      message = body['error']?.toString() ??
                body['message']?.toString() ??
                message;
      code = body['code']?.toString();

      if (body['errors'] is Map) {
        fieldErrors = Map<String, String>.from(
          (body['errors'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
        );
      }
    }

    switch (statusCode) {
      case 400:
        if (fieldErrors != null) {
          return ValidationException(message: message, fieldErrors: fieldErrors);
        }
        return ValidationException(message: message);
      case 401:
        return AuthException.unauthorized();
      case 403:
        return AuthException.forbidden();
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ValidationException(message: message);
      case 422:
        return ValidationException(message: message, fieldErrors: fieldErrors);
      case 429:
        return RateLimitException(message: message);
      case >= 500:
        return ServerException(message: message, statusCode: statusCode);
      default:
        return GearshException(message: message, code: code, statusCode: statusCode);
    }
  }

  /// Parse exception into GearshException
  static GearshException fromException(dynamic error) {
    if (error is GearshException) return error;

    if (error is SocketException) {
      return const NetworkException(message: 'No internet connection');
    }

    if (error is AsyncTimeoutException || error.toString().contains('TimeoutException')) {
      return const TimeoutException();
    }

    if (error is FormatException) {
      return const ServerException(message: 'Invalid response from server');
    }

    return GearshException(
      message: error.toString(),
      code: 'unknown',
      originalError: error,
    );
  }

  /// Log error for debugging
  static void logError(GearshException error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('─' * 50);
      debugPrint('🔴 GEARSH ERROR');
      debugPrint('Message: ${error.message}');
      debugPrint('Code: ${error.code}');
      debugPrint('Status: ${error.statusCode}');
      if (error.originalError != null) {
        debugPrint('Original: ${error.originalError}');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace:');
        debugPrint(stackTrace.toString());
      }
      debugPrint('─' * 50);
    }
  }
}

/// Async timeout exception alias
class AsyncTimeoutException implements Exception {
  final String message;
  AsyncTimeoutException([this.message = 'Async operation timed out']);
  @override
  String toString() => message;
}

