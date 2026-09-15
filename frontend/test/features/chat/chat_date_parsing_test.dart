import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/last_message_info.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/shared/utils/date_utils.dart';

const _instant = '2026-09-14T05:00:00.000Z';
final _utc = DateTime.utc(2026, 9, 14, 5);

Map<String, dynamic> _user() => {'id': 'user-2'};

Map<String, dynamic> _message({Map<String, dynamic>? replyTo}) => {
  'id': 'message-1',
  'conversationId': 'conversation-1',
  'senderId': 'user-1',
  'createdAt': _instant,
  'deletedAt': _instant,
  'readAt': null,
  'deliveredAt': _instant,
  'replyTo': replyTo,
};

void main() {
  test('keeps message and nested reply instants; display localizes', () {
    final message = MessageEntity.fromJson(_message(replyTo: _message()));

    expect(message.createdAt, _utc);
    expect(message.deletedAt, _utc);
    expect(message.deliveredAt, _utc);
    expect(message.readAt, isNull);
    expect(message.replyTo?.createdAt, message.createdAt);
    expect(
      formatMessageTime(message.createdAt),
      formatMessageTime(_utc.toLocal()),
    );
  });

  test('keeps chat and nested last message instants', () {
    final chat = ChatEntity.fromJson({
      'id': 'conversation-1',
      'threadType': 'DIRECT',
      'otherUser': _user(),
      'createdAt': _instant,
      'lastMessage': {'content': 'Olá', 'createdAt': _instant},
    });

    expect(chat.createdAt, _utc);
    expect(chat.lastMessageInfo, isA<LastMessageInfo>());
    expect(chat.lastMessageInfo?.createdAt, _utc);
    expect(chat.timestamp, _utc);
  });
}
