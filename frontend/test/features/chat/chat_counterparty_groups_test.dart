import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/presentation/pages/chat_counterparty_groups.dart';

ChatEntity _chat(String id, String counterpart, {int unread = 0}) => ChatEntity(
  id: id,
  threadType: ChatThreadType.direct,
  otherUser: UserEntity(id: counterpart, displayName: counterpart),
  createdAt: DateTime.utc(2026),
  unreadCount: unread,
);

void main() {
  test('groups counterpart identity without merging product conversations', () {
    final chats = [
      _chat('product-a', 'seller-a', unread: 1),
      _chat('product-b', 'seller-a'),
      _chat('product-c', 'seller-b'),
    ];

    final groups = groupChatsByCounterparty(chats);

    expect(groups.keys, ['seller-a', 'seller-b']);
    expect(groups['seller-a']!.map((chat) => chat.id), [
      'product-a',
      'product-b',
    ]);
    expect(groups['seller-a']!.first.unreadCount, 1);
    expect(groups['seller-b']!.single.id, 'product-c');
  });
}
