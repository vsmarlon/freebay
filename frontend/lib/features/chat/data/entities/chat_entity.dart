import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/data/entities/last_message_info.dart';
import 'package:freebay/features/chat/data/entities/order_info.dart';

part 'chat_entity.freezed.dart';
part 'chat_entity.g.dart';

@freezed
abstract class ChatProductInfo with _$ChatProductInfo {
  const factory ChatProductInfo({
    required String id,
    required String title,
    String? imageUrl,
    @Default('') String status,
  }) = _ChatProductInfo;

  factory ChatProductInfo.fromJson(Map<String, dynamic> json) =>
      _$ChatProductInfoFromJson(json);
}

@freezed
abstract class ChatEntity with _$ChatEntity {
  const ChatEntity._();

  const factory ChatEntity({
    required String id,
    required ChatThreadType threadType,
    required UserEntity otherUser,
    @JsonKey(name: 'lastMessage') LastMessageInfo? lastMessageInfo,
    required DateTime createdAt,
    ConversationPreference? preference,
    OrderInfo? orderInfo,
    ChatProductInfo? product,
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

  OrderStatus? get orderStatusEnum {
    final status = orderStatus;
    if (status == null) return null;
    for (final value in OrderStatus.values) {
      if (value.name.toUpperCase() == status) return value;
    }
    return null;
  }

  String? get productTitle => product?.title ?? orderInfo?.productTitle;
}
