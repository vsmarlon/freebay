import 'package:freezed_annotation/freezed_annotation.dart';
import 'og_metadata_entity.dart';
import 'message_reaction_entity.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

OgMetadataEntity? _ogFromJson(Map<String, dynamic>? json) =>
    json == null ? null : OgMetadataEntity.fromJson(json);

Map<String, dynamic>? _ogToJson(OgMetadataEntity? e) => e?.toJson();

@freezed
abstract class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    required String conversationId,
    required String senderId,
    String? content,
    @Default('TEXT') String type,
    String? attachmentUrl,
    @JsonKey(fromJson: _ogFromJson, toJson: _ogToJson)
    OgMetadataEntity? metadata,
    String? replyToId,
    MessageEntity? replyTo,
    @Default([]) List<MessageReactionEntity> reactions,
    DateTime? deletedAt,
    DateTime? readAt,
    DateTime? deliveredAt,
    required DateTime createdAt,
  }) = _MessageEntity;

  const MessageEntity._();

  factory MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);

  /// One-line label used wherever a message is shown as a reply preview.
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
