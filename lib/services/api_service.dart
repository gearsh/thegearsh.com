import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/config/api_config.dart';

/// Provider for the API service
final apiServiceProvider = Provider((ref) => ApiService());

/// Base API service for making HTTP requests
class ApiService {
  final String baseUrl = ApiConfig.apiBaseUrl;
  String? _authToken;

  /// Set the auth token for authenticated requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear the auth token on logout
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get default headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// GET request
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers)
          .timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// POST request
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// PUT request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(uri, headers: _headers)
          .timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(body);
      } else {
        final error = body['error'] ?? 'Unknown error';
        return ApiResponse.error(error, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }
}

/// API response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(success: true, data: data, statusCode: 200);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse._(success: false, error: error, statusCode: statusCode);
  }

  /// Get data field from response
  T? getData<T>() {
    if (success && data != null && data['data'] != null) {
      return data['data'] as T;
    }
    return null;
  }

  /// Get list data from response
  List<T> getListData<T>(T Function(Map<String, dynamic>) fromJson) {
    if (success && data != null && data['data'] != null) {
      return (data['data'] as List).map((item) => fromJson(item)).toList();
    }
    return [];
  }
}

