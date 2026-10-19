import 'package:freebay/features/chat/data/entities/chat_entity.dart';

Map<String, List<ChatEntity>> groupChatsByCounterparty(
  Iterable<ChatEntity> chats,
) {
  final groups = <String, List<ChatEntity>>{};
  for (final chat in chats) {
    groups.putIfAbsent(chat.otherUserId, () => []).add(chat);
  }
  return groups;
}
