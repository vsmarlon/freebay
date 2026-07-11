import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/data/entities/last_message_info.dart';
import 'package:freebay/features/chat/data/entities/order_info.dart';

part 'chat_entity.freezed.dart';
part 'chat_entity.g.dart';

ChatThreadType _threadTypeFromJson(String? value) =>
    value == 'ORDER' ? ChatThreadType.order : ChatThreadType.direct;

String _threadTypeToJson(ChatThreadType type) =>
    type == ChatThreadType.order ? 'ORDER' : 'DIRECT';

@freezed
abstract class ChatEntity with _$ChatEntity {
  const ChatEntity._();

  const factory ChatEntity({
    required String id,
    @JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson)
    required ChatThreadType threadType,
    required UserEntity otherUser,
    @JsonKey(name: 'lastMessage') LastMessageInfo? lastMessageInfo,
    required DateTime createdAt,
    ConversationPreference? preference,
    OrderInfo? orderInfo,
    @Default(0) int unreadCount,
  }) = _ChatEntity;

  factory ChatEntity.fromJson(Map<String, dynamic> json) =>
      _$ChatEntityFromJson(json);

  String get otherUserId => otherUser.id;
  String get otherName => otherUser.displayNameOrDefault;
  String? get otherAvatarUrl => otherUser.avatarUrl;
  String? get lastMessage => lastMessageInfo?.content;
  DateTime get timestamp => lastMessageInfo?.createdAt ?? createdAt;
  bool get unread => unreadCount > 0;
  bool get isArchived => preference?.isArchived ?? false;
  String? get orderStatus => orderInfo?.status;
}
