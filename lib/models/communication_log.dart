// Gearsh Communication Log Model
// Booking-scoped communication with full audit trail

import 'package:flutter/foundation.dart';

/// Communication thread tied to a specific booking
@immutable
class BookingCommunicationThread {
  final String id;
  final String bookingId;
  final List<String> participantIds;
  final List<CommunicationMessage> messages;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final bool isArchived;
  final ThreadMetrics metrics;

  const BookingCommunicationThread({
    required this.id,
    required this.bookingId,
    required this.participantIds,
    this.messages = const [],
    required this.createdAt,
    this.lastMessageAt,
    this.isArchived = false,
    this.metrics = const ThreadMetrics(),
  });

  BookingCommunicationThread copyWith({
    String? id,
    String? bookingId,
    List<String>? participantIds,
    List<CommunicationMessage>? messages,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isArchived,
    ThreadMetrics? metrics,
  }) {
    return BookingCommunicationThread(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      participantIds: participantIds ?? this.participantIds,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isArchived: isArchived ?? this.isArchived,
      metrics: metrics ?? this.metrics,
    );
  }

  /// Add a new message to the thread
  BookingCommunicationThread addMessage(CommunicationMessage message) {
    return copyWith(
      messages: [...messages, message],
      lastMessageAt: message.sentAt,
      metrics: metrics.copyWith(
        totalMessages: metrics.totalMessages + 1,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'participantIds': participantIds,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'isArchived': isArchived,
    'metrics': metrics.toJson(),
  };

  factory BookingCommunicationThread.fromJson(Map<String, dynamic> json) {
    return BookingCommunicationThread(
      id: json['id'],
      bookingId: json['bookingId'],
      participantIds: List<String>.from(json['participantIds']),
      messages: (json['messages'] as List?)?.map((m) => CommunicationMessage.fromJson(m)).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : null,
      isArchived: json['isArchived'] ?? false,
      metrics: json['metrics'] != null ? ThreadMetrics.fromJson(json['metrics']) : const ThreadMetrics(),
    );
  }
}

/// Individual message in the communication thread
@immutable
class CommunicationMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderRole; // 'artist', 'client', 'manager', 'system'
  final String senderName;
  final DateTime sentAt;
  final String content;
  final MessageType type;
  final List<MessageAttachment> attachments;
  final List<MessageReadReceipt> readReceipts;
  final bool isSystemMessage;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted; // Marked but content preserved in audit

  const CommunicationMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.sentAt,
    required this.content,
    this.type = MessageType.text,
    this.attachments = const [],
    this.readReceipts = const [],
    this.isSystemMessage = false,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
  });

  /// Check if message has been read by a specific user
  bool isReadBy(String userId) {
    return readReceipts.any((r) => r.userId == userId);
  }

  /// Get all users who have read the message
  List<String> get readByUserIds => readReceipts.map((r) => r.userId).toList();

  CommunicationMessage copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? senderRole,
    String? senderName,
    DateTime? sentAt,
    String? content,
    MessageType? type,
    List<MessageAttachment>? attachments,
    List<MessageReadReceipt>? readReceipts,
    bool? isSystemMessage,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
  }) {
    return CommunicationMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      sentAt: sentAt ?? this.sentAt,
      content: content ?? this.content,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      readReceipts: readReceipts ?? this.readReceipts,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'threadId': threadId,
    'senderId': senderId,
    'senderRole': senderRole,
    'senderName': senderName,
    'sentAt': sentAt.toIso8601String(),
    'content': content,
    'type': type.name,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'readReceipts': readReceipts.map((r) => r.toJson()).toList(),
    'isSystemMessage': isSystemMessage,
    'isEdited': isEdited,
    'editedAt': editedAt?.toIso8601String(),
    'isDeleted': isDeleted,
  };

  factory CommunicationMessage.fromJson(Map<String, dynamic> json) {
    return CommunicationMessage(
      id: json['id'],
      threadId: json['threadId'],
      senderId: json['senderId'],
      senderRole: json['senderRole'],
      senderName: json['senderName'],
      sentAt: DateTime.parse(json['sentAt']),
      content: json['content'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      attachments: (json['attachments'] as List?)?.map((a) => MessageAttachment.fromJson(a)).toList() ?? [],
      readReceipts: (json['readReceipts'] as List?)?.map((r) => MessageReadReceipt.fromJson(r)).toList() ?? [],
      isSystemMessage: json['isSystemMessage'] ?? false,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  /// Create a system message
  factory CommunicationMessage.system({
    required String id,
    required String threadId,
    required String content,
    MessageType type = MessageType.systemNotification,
  }) {
    return CommunicationMessage(
      id: id,
      threadId: threadId,
      senderId: 'system',
      senderRole: 'system',
      senderName: 'Gearsh',
      sentAt: DateTime.now(),
      content: content,
      type: type,
      isSystemMessage: true,
    );
  }
}

/// Message attachment
@immutable
class MessageAttachment {
  final String id;
  final String url;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final AttachmentType type;

  const MessageAttachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'type': type.name,
  };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      url: json['url'],
      fileName: json['fileName'],
      mimeType: json['mimeType'],
      sizeBytes: json['sizeBytes'],
      type: AttachmentType.values.firstWhere((e) => e.name == json['type']),
    );
  }
}

/// Read receipt for a message
@immutable
class MessageReadReceipt {
  final String userId;
  final String userName;
  final DateTime readAt;

  const MessageReadReceipt({
    required this.userId,
    required this.userName,
    required this.readAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'readAt': readAt.toIso8601String(),
  };

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      userId: json['userId'],
      userName: json['userName'],
      readAt: DateTime.parse(json['readAt']),
    );
  }
}

/// Thread metrics for audit purposes
@immutable
class ThreadMetrics {
  final int totalMessages;
  final int artistMessages;
  final int clientMessages;
  final int systemMessages;
  final Duration? averageResponseTime;
  final Duration? longestSilencePeriod;
  final DateTime? longestSilenceStart;
  final DateTime? longestSilenceEnd;

  const ThreadMetrics({
    this.totalMessages = 0,
    this.artistMessages = 0,
    this.clientMessages = 0,
    this.systemMessages = 0,
    this.averageResponseTime,
    this.longestSilencePeriod,
    this.longestSilenceStart,
    this.longestSilenceEnd,
  });

  ThreadMetrics copyWith({
    int? totalMessages,
    int? artistMessages,
    int? clientMessages,
    int? systemMessages,
    Duration? averageResponseTime,
    Duration? longestSilencePeriod,
    DateTime? longestSilenceStart,
    DateTime? longestSilenceEnd,
  }) {
    return ThreadMetrics(
      totalMessages: totalMessages ?? this.totalMessages,
      artistMessages: artistMessages ?? this.artistMessages,
      clientMessages: clientMessages ?? this.clientMessages,
      systemMessages: systemMessages ?? this.systemMessages,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      longestSilencePeriod: longestSilencePeriod ?? this.longestSilencePeriod,
      longestSilenceStart: longestSilenceStart ?? this.longestSilenceStart,
      longestSilenceEnd: longestSilenceEnd ?? this.longestSilenceEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalMessages': totalMessages,
    'artistMessages': artistMessages,
    'clientMessages': clientMessages,
    'systemMessages': systemMessages,
    'averageResponseTimeMs': averageResponseTime?.inMilliseconds,
    'longestSilencePeriodMs': longestSilencePeriod?.inMilliseconds,
    'longestSilenceStart': longestSilenceStart?.toIso8601String(),
    'longestSilenceEnd': longestSilenceEnd?.toIso8601String(),
  };

  factory ThreadMetrics.fromJson(Map<String, dynamic> json) {
    return ThreadMetrics(
      totalMessages: json['totalMessages'] ?? 0,
      artistMessages: json['artistMessages'] ?? 0,
      clientMessages: json['clientMessages'] ?? 0,
      systemMessages: json['systemMessages'] ?? 0,
      averageResponseTime: json['averageResponseTimeMs'] != null
          ? Duration(milliseconds: json['averageResponseTimeMs'])
          : null,
      longestSilencePeriod: json['longestSilencePeriodMs'] != null
          ? Duration(milliseconds: json['longestSilencePeriodMs'])
          : null,
      longestSilenceStart: json['longestSilenceStart'] != null
          ? DateTime.parse(json['longestSilenceStart'])
          : null,
      longestSilenceEnd: json['longestSilenceEnd'] != null
          ? DateTime.parse(json['longestSilenceEnd'])
          : null,
    );
  }
}

/// Message types
enum MessageType {
  text,
  image,
  document,
  voice,
  location,
  agreementUpdate,
  statusUpdate,
  paymentUpdate,
  systemNotification,
  riderUpdate,
}

/// Attachment types
enum AttachmentType {
  image,
  document,
  audio,
  video,
  other,
}

/// Silence period for audit logging (no communication detected)
@immutable
class SilencePeriod {
  final String threadId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration? duration;
  final String? endedBy; // User ID who broke the silence
  final bool wasNotified; // Whether a reminder was sent

  const SilencePeriod({
    required this.threadId,
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.endedBy,
    this.wasNotified = false,
  });

  Map<String, dynamic> toJson() => {
    'threadId': threadId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'durationMs': duration?.inMilliseconds,
    'endedBy': endedBy,
    'wasNotified': wasNotified,
  };
}

