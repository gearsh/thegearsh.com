import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/core/di/service_providers.dart';
import 'package:gearsh_app/core/queries/linked_queries.dart';
import 'package:gearsh_app/services/messages_service.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final Function(String)? onOpenChat;
  final Function(String)? onViewProfile;

  const MessagesScreen({
    super.key,
    this.onOpenChat,
    this.onViewProfile,
  });

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String? _selectedConversationId;
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  void _openConversation(String bookingId) {
    setState(() => _selectedConversationId = bookingId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final bookingId = _selectedConversationId;
    if (text.isEmpty || bookingId == null || _sending) return;

    setState(() => _sending = true);
    final repo = ref.read(messagesRepositoryProvider);
    final sent = await repo.sendMessage(bookingId, text);
    if (sent != null && mounted) {
      invalidateChatQueries(ref, bookingId);
      _messageController.clear();
    }
    if (mounted) setState(() => _sending = false);
  }

  MessageConversation? _activeConversation(List<MessageConversation> conversations) {
    if (_selectedConversationId == null) return null;
    try {
      return conversations.firstWhere((c) => c.bookingId == _selectedConversationId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsLinkedQueryProvider);

    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(conversationsLinkedQueryProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (conversations) {
        final active = _activeConversation(conversations);
        if (active != null && _selectedConversationId != null) {
          return _buildChatView(active, _selectedConversationId!);
        }
        return _buildConversationsList(conversations);
      },
    );
  }

  Widget _buildConversationsList(List<MessageConversation> conversations) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: _slate950.withAlpha(242),
            border: Border(
              bottom: BorderSide(color: _sky500.withAlpha(51)),
            ),
          ),
          child: const Row(
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Conversations list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: _sky500.withAlpha(25),
            ),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _buildConversationItem(conv);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConversationItem(MessageConversation conv) {
    final hasUnread = conv.unread > 0;

    return GestureDetector(
      onTap: () => _openConversation(conv.bookingId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _sky500.withAlpha(77), width: 2),
                  ),
                  child: ClipOval(
                    child: _avatarImage(conv.artistImage, 28),
                  ),
                ),
                // Unread badge
                if (hasUnread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_sky500, _cyan500],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: _slate950, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _sky500.withAlpha(204),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${conv.unread}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Online indicator removed for API-driven list
              ],
            ),
            const SizedBox(width: 14),

            // Message details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.artistName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conv.timestamp,
                        style: TextStyle(
                          color: hasUnread ? _sky400 : _slate400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conv.lastMessage,
                    style: TextStyle(
                      color: hasUnread ? Colors.white.withAlpha(204) : _slate400,
                      fontSize: 14,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(MessageConversation conv, String bookingId) {
    final messagesAsync = ref.watch(chatMessagesLinkedQueryProvider(bookingId));
    final padding = MediaQuery.of(context).padding;

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(chatMessagesLinkedQueryProvider(bookingId)),
          child: const Text('Retry'),
        ),
      ),
      data: (chatMessages) => Column(
      children: [
        // Chat Header
        Container(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: _slate950.withAlpha(242),
            border: Border(
              bottom: BorderSide(color: _sky500.withAlpha(51)),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => setState(() => _selectedConversationId = null),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _slate900.withAlpha(128),
                    shape: BoxShape.circle,
                    border: Border.all(color: _sky500.withAlpha(77)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Artist info
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.onViewProfile != null) {
                      widget.onViewProfile!(conv.bookingId);
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _sky500.withAlpha(77), width: 2),
                        ),
                        child: ClipOval(
                          child: _avatarImage(conv.artistImage, 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conv.artistName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Active now',
                            style: TextStyle(
                              color: _slate400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              _buildChatHeaderButton(Icons.phone_outlined),
              const SizedBox(width: 8),
              _buildChatHeaderButton(Icons.videocam_outlined),
              const SizedBox(width: 8),
              _buildChatHeaderButton(Icons.more_vert_rounded),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              final msg = chatMessages[index];
              return _buildMessageBubble(msg);
            },
          ),
        ),

        // Message Input
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + padding.bottom,
          ),
          decoration: BoxDecoration(
            color: _slate950.withAlpha(242),
            border: Border(
              top: BorderSide(color: _sky500.withAlpha(51)),
            ),
          ),
          child: Row(
            children: [
              // Attachment button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _slate900.withAlpha(128),
                  shape: BoxShape.circle,
                  border: Border.all(color: _sky500.withAlpha(77)),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: _sky400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _slate900.withAlpha(128),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _sky500.withAlpha(77)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: _slate500, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Send button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_sky500, _cyan500],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(102),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildChatHeaderButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _slate900.withAlpha(128),
        shape: BoxShape.circle,
        border: Border.all(color: _sky500.withAlpha(77)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.sender == 'me';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_sky500, _cyan500],
                          )
                        : null,
                    color: isMe ? null : _slate900.withAlpha(153),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe ? null : Border.all(color: _sky500.withAlpha(51)),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.timestamp,
                  style: const TextStyle(
                    color: _slate500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarImage(String? source, double iconSize) {
    if (source != null && (source.startsWith('http') || source.startsWith('/'))) {
      return Image.network(
        source.startsWith('/') ? 'https://thegearsh.com$source' : source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: _slate900,
          child: Icon(Icons.person, color: _sky400, size: iconSize),
        ),
      );
    }
    return Container(
      color: _slate900,
      child: Icon(Icons.person, color: _sky400, size: iconSize),
    );
  }
}

