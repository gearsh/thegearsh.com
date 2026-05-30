import 'package:gearsh_app/services/messages_service.dart';

abstract class IMessagesRepository {
  Future<List<MessageConversation>> fetchConversations();
  Future<List<ChatMessage>> fetchMessages(String bookingId);
  Future<ChatMessage?> sendMessage(String bookingId, String text);
}
