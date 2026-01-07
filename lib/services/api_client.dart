/// Gearsh API Client
/// Production-grade HTTP client with retry logic, interceptors, and error handling

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:gearsh_app/config/api_config.dart';
import 'package:gearsh_app/services/error_handling.dart';

/// Provider for the API client
final apiClientProvider = Provider((ref) => GearshApiClient());

/// Request configuration
class RequestConfig {
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final bool requiresAuth;

  const RequestConfig({
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.requiresAuth = false,
  });

  static const RequestConfig standard = RequestConfig();
  static const RequestConfig noRetry = RequestConfig(maxRetries: 0);
  static const RequestConfig authenticated = RequestConfig(requiresAuth: true);
  static const RequestConfig longRunning = RequestConfig(
    timeout: Duration(seconds: 60),
    maxRetries: 2,
  );
}

/// API Response wrapper with strong typing
class ApiResult<T> {
  final bool isSuccess;
  final T? data;
  final GearshException? error;
  final int? statusCode;
  final Map<String, String>? headers;

  const ApiResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
    this.headers,
  });

  factory ApiResult.success(T data, {int? statusCode, Map<String, String>? headers}) {
    return ApiResult._(
      isSuccess: true,
      data: data,
      statusCode: statusCode,
      headers: headers,
    );
  }

  factory ApiResult.failure(GearshException error, {int? statusCode}) {
    return ApiResult._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }

  /// Execute callback if success
  void whenSuccess(void Function(T data) callback) {
    if (isSuccess && data != null) {
      callback(data!);
    }
  }

  /// Execute callback if failure
  void whenFailure(void Function(GearshException error) callback) {
    if (!isSuccess && error != null) {
      callback(error!);
    }
  }

  /// Map the result
  ApiResult<R> map<R>(R Function(T) mapper) {
    if (isSuccess && data != null) {
      return ApiResult.success(mapper(data!), statusCode: statusCode, headers: headers);
    }
    return ApiResult.failure(error ?? const GearshException(message: 'Unknown error'), statusCode: statusCode);
  }

  /// Get data or throw
  T getOrThrow() {
    if (isSuccess && data != null) return data!;
    throw error ?? const GearshException(message: 'Unknown error');
  }

  /// Get data or default
  T getOrElse(T defaultValue) {
    return isSuccess && data != null ? data as T : defaultValue;
  }
}

/// Production-grade API client for Gearsh
class GearshApiClient {
  final http.Client _client = http.Client();
  final String _baseUrl = ApiConfig.apiBaseUrl;

  String? _authToken;
  String? _refreshToken;

  // Request interceptors
  final List<RequestInterceptor> _requestInterceptors = [];
  // Response interceptors
  final List<ResponseInterceptor> _responseInterceptors = [];

  // Pending requests for deduplication
  final Map<String, Future<http.Response>> _pendingRequests = {};

  /// Set authentication tokens
  void setTokens({required String authToken, String? refreshToken}) {
    _authToken = authToken;
    _refreshToken = refreshToken;
  }

  /// Clear authentication tokens
  void clearTokens() {
    _authToken = null;
    _refreshToken = null;
  }

  /// Check if authenticated
  bool get isAuthenticated => _authToken != null;

  /// Add request interceptor
  void addRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  /// Add response interceptor
  void addResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  /// Build headers
  Map<String, String> _buildHeaders({bool requiresAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Version': '1.0.0',
      'X-Platform': defaultTargetPlatform.name,
    };

    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Execute request with retry logic
  Future<ApiResult<T>> _executeWithRetry<T>({
    required Future<http.Response> Function() request,
    required T Function(dynamic) parser,
    required RequestConfig config,
    required String requestKey,
  }) async {
    int attempts = 0;
    GearshException? lastError;

    while (attempts <= config.maxRetries) {
      try {
        // Check for pending duplicate request
        if (_pendingRequests.containsKey(requestKey)) {
          final response = await _pendingRequests[requestKey]!;
          return _handleResponse(response, parser);
        }

        // Execute request with timeout
        final responseFuture = request().timeout(config.timeout);
        _pendingRequests[requestKey] = responseFuture;

        final response = await responseFuture;
        _pendingRequests.remove(requestKey);

        // Run response interceptors
        for (final interceptor in _responseInterceptors) {
          await interceptor.onResponse(response);
        }

        return _handleResponse(response, parser);
      } on TimeoutException catch (e) {
        _pendingRequests.remove(requestKey);
        lastError = TimeoutException(originalError: e);
      } catch (e) {
        _pendingRequests.remove(requestKey);
        lastError = ErrorHandler.fromException(e);
      }

      // Check if should retry
      if (attempts < config.maxRetries && (lastError?.isRetryable ?? false)) {
        attempts++;
        final delay = config.retryDelay * attempts; // Exponential backoff
        if (kDebugMode) {
          debugPrint('🔄 Retry attempt $attempts after ${delay.inSeconds}s');
        }
        await Future.delayed(delay);
      } else {
        break;
      }
    }

    ErrorHandler.logError(lastError!);
    return ApiResult.failure(lastError);
  }

  /// Handle HTTP response
  ApiResult<T> _handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    try {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final headers = response.headers;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body?['data'] ?? body;
        return ApiResult.success(
          parser(data),
          statusCode: response.statusCode,
          headers: headers,
        );
      } else {
        final error = ErrorHandler.fromHttpResponse(response.statusCode, body);
        ErrorHandler.logError(error);
        return ApiResult.failure(error, statusCode: response.statusCode);
      }
    } catch (e) {
      final error = ErrorHandler.fromException(e);
      ErrorHandler.logError(error);
      return ApiResult.failure(error);
    }
  }

  /// GET request
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? parser,
    RequestConfig config = RequestConfig.standard,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    final requestKey = 'GET:$uri';

    // Run request interceptors
    for (final interceptor in _requestInterceptors) {
      await interceptor.onRequest('GET', uri.toString(), null);
    }

    return _executeWithRetry(
      request: () => _client.get(uri, headers: _buildHeaders(requiresAuth: config.requiresAuth)),
      parser: parser ?? (data) => data as T,
      config: config,
      requestKey: requestKey,
    );
  }

  /// POST request
  Future<ApiResult<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    RequestConfig config = RequestConfig.standard,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestKey = 'POST:$uri:${body.hashCode}';

    // Run request interceptors
    for (final interceptor in _requestInterceptors) {
      await interceptor.onRequest('POST', uri.toString(), body);
    }

    return _executeWithRetry(
      request: () => _client.post(
        uri,
        headers: _buildHeaders(requiresAuth: config.requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      parser: parser ?? (data) => data as T,
      config: config,
      requestKey: requestKey,
    );
  }

  /// PUT request
  Future<ApiResult<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    RequestConfig config = RequestConfig.standard,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestKey = 'PUT:$uri:${body.hashCode}';

    return _executeWithRetry(
      request: () => _client.put(
        uri,
        headers: _buildHeaders(requiresAuth: config.requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      parser: parser ?? (data) => data as T,
      config: config,
      requestKey: requestKey,
    );
  }

  /// PATCH request
  Future<ApiResult<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    RequestConfig config = RequestConfig.standard,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestKey = 'PATCH:$uri:${body.hashCode}';

    return _executeWithRetry(
      request: () => _client.patch(
        uri,
        headers: _buildHeaders(requiresAuth: config.requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      parser: parser ?? (data) => data as T,
      config: config,
      requestKey: requestKey,
    );
  }

  /// DELETE request
  Future<ApiResult<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? parser,
    RequestConfig config = RequestConfig.standard,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestKey = 'DELETE:$uri';

    return _executeWithRetry(
      request: () => _client.delete(
        uri,
        headers: _buildHeaders(requiresAuth: config.requiresAuth),
      ),
      parser: parser ?? (data) => data as T,
      config: config,
      requestKey: requestKey,
    );
  }

  /// Dispose client
  void dispose() {
    _client.close();
    _pendingRequests.clear();
  }
}

/// Request interceptor interface
abstract class RequestInterceptor {
  Future<void> onRequest(String method, String url, dynamic body);
}

/// Response interceptor interface
abstract class ResponseInterceptor {
  Future<void> onResponse(http.Response response);
}

/// Logging interceptor for debugging
class LoggingInterceptor implements RequestInterceptor, ResponseInterceptor {
  @override
  Future<void> onRequest(String method, String url, dynamic body) async {
    if (kDebugMode) {
      debugPrint('─' * 50);
      debugPrint('📤 REQUEST: $method $url');
      if (body != null) {
        debugPrint('Body: ${jsonEncode(body)}');
      }
    }
  }

  @override
  Future<void> onResponse(http.Response response) async {
    if (kDebugMode) {
      debugPrint('📥 RESPONSE: ${response.statusCode}');
      if (response.body.length < 1000) {
        debugPrint('Body: ${response.body}');
      } else {
        debugPrint('Body: [${response.body.length} bytes]');
      }
      debugPrint('─' * 50);
    }
  }
}

/// Auth token refresh interceptor
class AuthInterceptor implements ResponseInterceptor {
  final Future<void> Function() onUnauthorized;

  AuthInterceptor({required this.onUnauthorized});

  @override
  Future<void> onResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await onUnauthorized();
    }
  }
}

