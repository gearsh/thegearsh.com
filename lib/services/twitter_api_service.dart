// Gearsh App - Twitter API Service
// Fetches followers from Twitter/X to import as artists

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Twitter API Configuration
/// Get your API keys from https://developer.twitter.com/
class TwitterConfig {
  // TODO: Replace with your Twitter API credentials
  static const String bearerToken = 'YOUR_TWITTER_BEARER_TOKEN';
  static const String apiKey = 'YOUR_API_KEY';
  static const String apiSecretKey = 'YOUR_API_SECRET_KEY';

  // Your Twitter username (without @)
  static const String gearshUsername = 'thegearsh';
}

/// Represents a Twitter user/follower
class TwitterUser {
  final String id;
  final String name;
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final String? location;
  final int followersCount;
  final int followingCount;
  final bool isVerified;

  TwitterUser({
    required this.id,
    required this.name,
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.location,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
  });

  factory TwitterUser.fromJson(Map<String, dynamic> json) {
    return TwitterUser(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      bio: json['description'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      location: json['location'] as String?,
      followersCount: json['public_metrics']?['followers_count'] ?? 0,
      followingCount: json['public_metrics']?['following_count'] ?? 0,
      isVerified: json['verified'] ?? false,
    );
  }

  /// Convert to GearshArtist-compatible format
  Map<String, dynamic> toArtistData({
    String category = 'Artist',
    List<String> subcategories = const [],
    int bookingFee = 2000,
  }) {
    return {
      'id': username.toLowerCase(),
      'name': name,
      'username': '@$username',
      'category': category,
      'subcategories': subcategories.isEmpty ? [category] : subcategories,
      'location': location ?? 'South Africa',
      'countryCode': 'ZA',
      'currencyCode': 'ZAR',
      'rating': 4.5,
      'reviewCount': 0,
      'hoursBooked': 0,
      'responseTime': '< 24 hours',
      'image': profileImageUrl ?? 'assets/images/gearsh_logo.png',
      'isVerified': isVerified,
      'isAvailable': true,
      'bio': bio ?? 'Artist on Gearsh. Book me for your next event!',
      'bookingFee': bookingFee,
      'highlights': [
        'New on Gearsh',
        if (isVerified) 'Verified on X',
        if (followersCount > 1000) '${(followersCount / 1000).toStringAsFixed(1)}K Followers',
      ],
      'services': [],
      'discography': [],
      'upcomingGigs': [],
    };
  }
}

/// Twitter API Service
class TwitterApiService {
  static const String _baseUrl = 'https://api.twitter.com/2';

  final String _bearerToken;

  TwitterApiService({String? bearerToken})
      : _bearerToken = bearerToken ?? TwitterConfig.bearerToken;

  /// Headers for authenticated requests
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_bearerToken',
    'Content-Type': 'application/json',
  };

  /// Get user ID by username
  Future<String?> getUserIdByUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/by/username/$username'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['id'] as String?;
      } else {
        debugPrint('Twitter API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user ID: $e');
      return null;
    }
  }

  /// Fetch followers for a user
  Future<List<TwitterUser>> getFollowers({
    String? userId,
    String? username,
    int maxResults = 100,
    String? paginationToken,
  }) async {
    try {
      // Get user ID if not provided
      final targetUserId = userId ?? await getUserIdByUsername(username ?? TwitterConfig.gearshUsername);

      if (targetUserId == null) {
        debugPrint('Could not find user ID');
        return [];
      }

      // Build URL with user fields
      final queryParams = {
        'max_results': maxResults.toString(),
        'user.fields': 'id,name,username,description,profile_image_url,location,public_metrics,verified',
        if (paginationToken != null) 'pagination_token': paginationToken,
      };

      final uri = Uri.parse('$_baseUrl/users/$targetUserId/followers')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = (data['data'] as List?)
            ?.map((u) => TwitterUser.fromJson(u))
            .toList() ?? [];

        debugPrint('Fetched ${users.length} followers');
        return users;
      } else {
        debugPrint('Twitter API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching followers: $e');
      return [];
    }
  }

  /// Fetch following (accounts the user follows)
  Future<List<TwitterUser>> getFollowing({
    String? userId,
    String? username,
    int maxResults = 100,
    String? paginationToken,
  }) async {
    try {
      final targetUserId = userId ?? await getUserIdByUsername(username ?? TwitterConfig.gearshUsername);

      if (targetUserId == null) {
        debugPrint('Could not find user ID');
        return [];
      }

      final queryParams = {
        'max_results': maxResults.toString(),
        'user.fields': 'id,name,username,description,profile_image_url,location,public_metrics,verified',
        if (paginationToken != null) 'pagination_token': paginationToken,
      };

      final uri = Uri.parse('$_baseUrl/users/$targetUserId/following')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = (data['data'] as List?)
            ?.map((u) => TwitterUser.fromJson(u))
            .toList() ?? [];

        debugPrint('Fetched ${users.length} following');
        return users;
      } else {
        debugPrint('Twitter API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching following: $e');
      return [];
    }
  }

  /// Search for users by query
  Future<List<TwitterUser>> searchUsers(String query, {int maxResults = 20}) async {
    try {
      // Note: User search requires elevated access
      // This is a placeholder for when you have elevated API access
      debugPrint('User search requires elevated Twitter API access');
      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }
}

/// Provider for Twitter API Service
final twitterApiService = TwitterApiService();
