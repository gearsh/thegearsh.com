import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gearsh_app/config/api_config.dart';
import 'package:gearsh_app/core/contracts/i_messages_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageConversation {
  final String bookingId;
  final String artistName;
  final String? artistImage;
  final String lastMessage;
  final String timestamp;
  final int unread;

  MessageConversation({
    required this.bookingId,
    required this.artistName,
    this.artistImage,
    required this.lastMessage,
    required this.timestamp,
    this.unread = 0,
  });

  factory MessageConversation.fromJson(Map<String, dynamic> json) {
    return MessageConversation(
      bookingId: json['booking_id'] ?? json['id'] ?? '',
      artistName: json['artist_name'] ?? 'Artist',
      artistImage: json['artist_image'],
      lastMessage: json['last_message'] ?? '',
      timestamp: json['timestamp'] ?? '',
      unread: (json['unread'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      sender: json['sender'] ?? 'them',
      text: json['text'] ?? json['content'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class MessagesService implements IMessagesRepository {
  static const _tokenKey = 'gearsh_auth_token';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<MessageConversation>> fetchConversations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/conversations'),
        headers: await _headers(),
      ).timeout(ApiConfig.connectionTimeout);
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? [];
      return list.map((e) => MessageConversation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ChatMessage>> fetchMessages(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/conversations/$bookingId/messages'),
        headers: await _headers(),
      ).timeout(ApiConfig.connectionTimeout);
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? [];
      return list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<ChatMessage?> sendMessage(String bookingId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/conversations/$bookingId/messages'),
        headers: await _headers(),
        body: jsonEncode({'content': content}),
      ).timeout(ApiConfig.connectionTimeout);
      if (response.statusCode != 201 && response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is Map<String, dynamic>) return ChatMessage.fromJson(data);
      return null;
    } catch (_) {
      return null;
    }
  }
}
