import 'package:freezed_annotation/freezed_annotation.dart';
import 'message_reaction_entity.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

@freezed
abstract class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    required String conversationId,
    required String senderId,
    String? clientMessageId,
    String? content,
    @Default('TEXT') String type,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
    String? replyToId,
    MessageEntity? replyTo,
    @Default([]) List<MessageReactionEntity> reactions,
    DateTime? deletedAt,
    DateTime? readAt,
    DateTime? deliveredAt,
    @Default(false) bool viewOnce,
    required DateTime createdAt,
  }) = _MessageEntity;

  const MessageEntity._();

  factory MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);

  String get previewText {
    final body = content ?? '';
    if (body.isNotEmpty) return body;
    switch (type.toUpperCase()) {
      case 'IMAGE':
      case 'GIF':
        return 'Imagem';
      case 'VIDEO':
        return 'Vídeo';
      case 'LOCATION':
        return 'Localização';
      case 'PRODUCT_CARD':
        return 'Produto';
      default:
        return 'Mensagem';
    }
  }
}
