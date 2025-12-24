import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  final Function(String)? onOpenChat;
  final Function(String)? onViewProfile;

  const MessagesScreen({
    super.key,
    this.onOpenChat,
    this.onViewProfile,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? _selectedConversationId;
  final TextEditingController _messageController = TextEditingController();

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  // Mock conversations data
  static const List<Map<String, dynamic>> _conversations = [
    {
      'id': 'conv1',
      'artistId': '1',
      'artistName': 'A-Reece',
      'artistImage': 'assets/images/artists/a-reece.png',
      'lastMessage': "Sounds great! I'll be there at 6 PM",
      'timestamp': '2m ago',
      'unread': 2,
      'online': true,
    },
    {
      'id': 'conv2',
      'artistId': '2',
      'artistName': 'Nasty C',
      'artistImage': 'assets/images/artists/nasty c.png',
      'lastMessage': 'I can provide extra sound equipment',
      'timestamp': '1h ago',
      'unread': 0,
      'online': false,
    },
    {
      'id': 'conv3',
      'artistId': '3',
      'artistName': 'Emtee',
      'artistImage': 'assets/images/artists/emtee.webp',
      'lastMessage': 'Thanks! Looking forward to working with you',
      'timestamp': '3h ago',
      'unread': 0,
      'online': true,
    },
  ];

  // Mock chat messages
  static const List<Map<String, dynamic>> _chatMessages = [
    {
      'id': 'm1',
      'sender': 'them',
      'text': 'Hi! Thanks for booking me for your event',
      'timestamp': '10:30 AM',
    },
    {
      'id': 'm2',
      'sender': 'me',
      'text': 'Excited to have you! What equipment do you need?',
      'timestamp': '10:32 AM',
    },
    {
      'id': 'm3',
      'sender': 'them',
      'text': "I'll bring my full setup. Just need access to power outlets and a stage",
      'timestamp': '10:35 AM',
    },
    {
      'id': 'm4',
      'sender': 'me',
      'text': 'Perfect! We have everything ready',
      'timestamp': '10:37 AM',
    },
    {
      'id': 'm5',
      'sender': 'them',
      'text': "Sounds great! I'll be there at 6 PM",
      'timestamp': '10:40 AM',
    },
  ];

  Map<String, dynamic>? get _activeConversation {
    if (_selectedConversationId == null) return null;
    try {
      return _conversations.firstWhere((c) => c['id'] == _selectedConversationId);
    } catch (e) {
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
    if (_activeConversation != null) {
      return _buildChatView();
    }
    return _buildConversationsList();
  }

  Widget _buildConversationsList() {
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
            itemCount: _conversations.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: _sky500.withAlpha(25),
            ),
            itemBuilder: (context, index) {
              final conv = _conversations[index];
              return _buildConversationItem(conv);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conv) {
    final hasUnread = (conv['unread'] as int) > 0;
    final isOnline = conv['online'] as bool? ?? false;

    return GestureDetector(
      onTap: () => setState(() => _selectedConversationId = conv['id']),
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
                    child: Image.asset(
                      conv['artistImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _slate900,
                        child: const Icon(Icons.person, color: _sky400, size: 28),
                      ),
                    ),
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
                          '${conv['unread']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Online indicator
                if (isOnline && !hasUnread)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                        border: Border.all(color: _slate950, width: 2),
                      ),
                    ),
                  ),
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
                      Text(
                        conv['artistName'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        conv['timestamp'],
                        style: TextStyle(
                          color: hasUnread ? _sky400 : _slate400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conv['lastMessage'],
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

  Widget _buildChatView() {
    final conv = _activeConversation!;
    final padding = MediaQuery.of(context).padding;

    return Column(
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
                      widget.onViewProfile!(conv['artistId']);
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
                          child: Image.asset(
                            conv['artistImage'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _slate900,
                              child: const Icon(Icons.person, color: _sky400, size: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conv['artistName'],
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
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
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
              Container(
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
            ],
          ),
        ),
      ],
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

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender'] == 'me';

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
                    msg['text'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg['timestamp'],
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
}

