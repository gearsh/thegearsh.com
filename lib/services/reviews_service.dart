// Gearsh App - Reviews Service
// Handles review creation and fetching

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ReviewsService {
  static const String _baseUrl = 'https://thegearsh-com.pages.dev/api';

  /// Submit a review for a booking
  Future<ReviewResult> submitReview({
    required String bookingId,
    required String reviewerId,
    required String artistId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'reviewer_id': reviewerId,
          'artist_id': artistId,
          'rating': rating,
          'comment': comment,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ReviewResult.success(reviewId: data['data']['review_id']);
      } else {
        final error = jsonDecode(response.body);
        return ReviewResult.failure(error['error'] ?? 'Failed to submit review');
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return ReviewResult.failure('Network error. Please try again.');
    }
  }

  /// Get reviews for an artist
  Future<List<Review>> getArtistReviews(String artistId, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reviews?artist_id=$artistId&limit=$limit'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List?)
            ?.map((r) => Review.fromJson(r))
            .toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  /// Get average rating for an artist
  Future<double> getArtistAverageRating(String artistId) async {
    try {
      final reviews = await getArtistReviews(artistId);
      if (reviews.isEmpty) return 0.0;

      final total = reviews.fold<double>(0, (sum, r) => sum + r.rating);
      return total / reviews.length;
    } catch (e) {
      return 0.0;
    }
  }
}

/// Review result wrapper
class ReviewResult {
  final bool success;
  final String? reviewId;
  final String? error;

  ReviewResult._({
    required this.success,
    this.reviewId,
    this.error,
  });

  factory ReviewResult.success({required String reviewId}) {
    return ReviewResult._(success: true, reviewId: reviewId);
  }

  factory ReviewResult.failure(String error) {
    return ReviewResult._(success: false, error: error);
  }
}

/// Review model
class Review {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String artistId;
  final double rating;
  final String? comment;
  final String? reviewerName;
  final String? reviewerImage;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.artistId,
    required this.rating,
    this.comment,
    this.reviewerName,
    this.reviewerImage,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      reviewerId: json['reviewer_id'] ?? '',
      artistId: json['artist_id'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'],
      reviewerName: json['reviewer_name'],
      reviewerImage: json['reviewer_image'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
