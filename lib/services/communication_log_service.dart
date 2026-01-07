// Gearsh Communication Log Service
// Booking-scoped communication with audit trail

import 'package:flutter/foundation.dart';
import '../models/communication_log.dart';

/// Service for managing booking-scoped communication threads
class CommunicationLogService {
  static final CommunicationLogService _instance = CommunicationLogService._internal();
  factory CommunicationLogService() => _instance;
  CommunicationLogService._internal();

  // In-memory storage (replace with API calls in production)
  final Map<String, BookingCommunicationThread> _threads = {};
  final Map<String, List<SilencePeriod>> _silencePeriods = {};

  // Silence threshold (hours of no communication to flag)
  static const int silenceThresholdHours = 24;

  /// Create a communication thread for a booking
  Future<BookingCommunicationThread> createThread({
    required String bookingId,
    required List<String> participantIds,
  }) async {
    final thread = BookingCommunicationThread(
      id: _generateId(),
      bookingId: bookingId,
      participantIds: participantIds,
      createdAt: DateTime.now(),
    );

    _threads[thread.id] = thread;
    debugPrint('[CommunicationService] Created thread for booking $bookingId');

    // Add system message
    await sendSystemMessage(
      threadId: thread.id,
      content: 'Communication thread created for this booking. All messages are logged and time-stamped.',
    );

    return thread;
  }

  /// Send a message in a thread
  Future<CommunicationMessage?> sendMessage({
    required String threadId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    List<MessageAttachment> attachments = const [],
  }) async {
    final thread = _threads[threadId];
    if (thread == null) return null;

    // Check for silence period end
    await _checkSilenceEnd(threadId, senderId);

    final message = CommunicationMessage(
      id: _generateId(),
      threadId: threadId,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      sentAt: DateTime.now(),
      content: content,
      type: type,
      attachments: attachments,
    );

    // Update thread metrics
    final updatedMetrics = thread.metrics.copyWith(
      totalMessages: thread.metrics.totalMessages + 1,
      artistMessages: senderRole == 'artist'
          ? thread.metrics.artistMessages + 1
          : thread.metrics.artistMessages,
      clientMessages: senderRole == 'client'
          ? thread.metrics.clientMessages + 1
          : thread.metrics.clientMessages,
    );

    final updated = thread.copyWith(
      messages: [...thread.messages, message],
      lastMessageAt: message.sentAt,
      metrics: updatedMetrics,
    );

    _threads[threadId] = updated;
    debugPrint('[CommunicationService] Message sent in thread $threadId');
    return message;
  }

  /// Send a system notification message
  Future<CommunicationMessage?> sendSystemMessage({
    required String threadId,
    required String content,
    MessageType type = MessageType.systemNotification,
  }) async {
    final thread = _threads[threadId];
    if (thread == null) return null;

    final message = CommunicationMessage.system(
      id: _generateId(),
      threadId: threadId,
      content: content,
      type: type,
    );

    final updatedMetrics = thread.metrics.copyWith(
      totalMessages: thread.metrics.totalMessages + 1,
      systemMessages: thread.metrics.systemMessages + 1,
    );

    final updated = thread.copyWith(
      messages: [...thread.messages, message],
      lastMessageAt: message.sentAt,
      metrics: updatedMetrics,
    );

    _threads[threadId] = updated;
    return message;
  }

  /// Mark a message as read
  Future<CommunicationMessage?> markMessageRead({
    required String threadId,
    required String messageId,
    required String userId,
    required String userName,
  }) async {
    final thread = _threads[threadId];
    if (thread == null) return null;

    final updatedMessages = thread.messages.map((m) {
      if (m.id == messageId && !m.isReadBy(userId)) {
        final receipt = MessageReadReceipt(
          userId: userId,
          userName: userName,
          readAt: DateTime.now(),
        );
        return m.copyWith(readReceipts: [...m.readReceipts, receipt]);
      }
      return m;
    }).toList();

    final updated = thread.copyWith(messages: updatedMessages);
    _threads[threadId] = updated;

    return updatedMessages.firstWhere((m) => m.id == messageId);
  }

  /// Mark all messages as read for a user
  Future<void> markAllRead({
    required String threadId,
    required String userId,
    required String userName,
  }) async {
    final thread = _threads[threadId];
    if (thread == null) return;

    final updatedMessages = thread.messages.map((m) {
      if (!m.isReadBy(userId) && m.senderId != userId) {
        final receipt = MessageReadReceipt(
          userId: userId,
          userName: userName,
          readAt: DateTime.now(),
        );
        return m.copyWith(readReceipts: [...m.readReceipts, receipt]);
      }
      return m;
    }).toList();

    final updated = thread.copyWith(messages: updatedMessages);
    _threads[threadId] = updated;
  }

  /// Get thread by ID
  Future<BookingCommunicationThread?> getThread(String threadId) async {
    return _threads[threadId];
  }

  /// Get thread for a booking
  Future<BookingCommunicationThread?> getThreadForBooking(String bookingId) async {
    try {
      return _threads.values.firstWhere((t) => t.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  /// Get all messages in a thread
  List<CommunicationMessage> getMessages(String threadId) {
    return _threads[threadId]?.messages ?? [];
  }

  /// Get unread message count for a user
  int getUnreadCount(String threadId, String userId) {
    final thread = _threads[threadId];
    if (thread == null) return 0;

    return thread.messages
        .where((m) => m.senderId != userId && !m.isReadBy(userId))
        .length;
  }

  /// Check for silence periods and log them
  Future<void> checkForSilence(String threadId) async {
    final thread = _threads[threadId];
    if (thread == null || thread.lastMessageAt == null) return;

    final hoursSinceLastMessage = DateTime.now()
        .difference(thread.lastMessageAt!)
        .inHours;

    if (hoursSinceLastMessage >= silenceThresholdHours) {
      // Check if we already have an active silence period
      final existingPeriods = _silencePeriods[threadId] ?? [];
      final hasActivePeriod = existingPeriods.any((p) => p.endedAt == null);

      if (!hasActivePeriod) {
        final silencePeriod = SilencePeriod(
          threadId: threadId,
          startedAt: thread.lastMessageAt!,
        );
        _silencePeriods[threadId] = [...existingPeriods, silencePeriod];
        debugPrint('[CommunicationService] Silence period logged for thread $threadId');
      }
    }
  }

  /// End silence period when a message is sent
  Future<void> _checkSilenceEnd(String threadId, String endedBy) async {
    final existingPeriods = _silencePeriods[threadId] ?? [];
    final activePeriodIndex = existingPeriods.indexWhere((p) => p.endedAt == null);

    if (activePeriodIndex != -1) {
      final activePeriod = existingPeriods[activePeriodIndex];
      final now = DateTime.now();

      existingPeriods[activePeriodIndex] = SilencePeriod(
        threadId: threadId,
        startedAt: activePeriod.startedAt,
        endedAt: now,
        duration: now.difference(activePeriod.startedAt),
        endedBy: endedBy,
        wasNotified: activePeriod.wasNotified,
      );

      _silencePeriods[threadId] = existingPeriods;
      debugPrint('[CommunicationService] Silence period ended for thread $threadId');
    }
  }

  /// Get silence periods for a thread (for audit)
  List<SilencePeriod> getSilencePeriods(String threadId) {
    return _silencePeriods[threadId] ?? [];
  }

  /// Get thread metrics for audit
  ThreadMetrics? getThreadMetrics(String threadId) {
    return _threads[threadId]?.metrics;
  }

  /// Calculate response time statistics
  Future<Duration?> calculateAverageResponseTime(String threadId) async {
    final thread = _threads[threadId];
    if (thread == null || thread.messages.length < 2) return null;

    final responseTimes = <Duration>[];
    CommunicationMessage? lastMessage;

    for (final message in thread.messages) {
      if (message.isSystemMessage) continue;

      if (lastMessage != null && message.senderRole != lastMessage.senderRole) {
        responseTimes.add(message.sentAt.difference(lastMessage.sentAt));
      }
      lastMessage = message;
    }

    if (responseTimes.isEmpty) return null;

    final totalMs = responseTimes.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ responseTimes.length);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Singleton instance
final communicationLogService = CommunicationLogService();

