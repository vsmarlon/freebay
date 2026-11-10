import 'package:freezed_annotation/freezed_annotation.dart';
import 'message_reaction_entity.dart';
import 'message_type.dart';

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
    @JsonKey(fromJson: messageTypeFromJson, toJson: messageTypeToJson)
    @Default(MessageType.text)
    MessageType type,
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
      _$MessageEntityFromJson(_normalizeOffer(json));

  static bool isOfferMetadata(Map<String, dynamic>? metadata) =>
      metadata != null && metadata['offerPrice'] is num;

  bool get isOffer => isOfferMetadata(metadata);

  String get previewText {
    final body = content ?? '';
    if (body.isNotEmpty) return body;
    switch (type) {
      case MessageType.image:
      case MessageType.gif:
        return 'Imagem';
      case MessageType.video:
        return 'Vídeo';
      case MessageType.audio:
        final ms = metadata?['durationMs'];
        if (ms is int && ms > 0) {
          final totalSec = ms ~/ 1000;
          return 'Áudio ${totalSec ~/ 60}:${(totalSec % 60).toString().padLeft(2, '0')}';
        }
        return 'Áudio';
      case MessageType.location:
        return 'Localização';
      case MessageType.productCard:
        return 'Produto';
      default:
        return 'Mensagem';
    }
  }
}

// Backend has no OFFER MessageType; offers ride a TEXT envelope with structured
// metadata. Normalize at the mapping boundary so every inbound path (REST,
// socket, confirmSent) carries the offer shape.
Map<String, dynamic> _normalizeOffer(Map<String, dynamic> json) {
  final rawMetadata = json['metadata'];
  final isOffer =
      rawMetadata is Map &&
      (rawMetadata['offerPrice'] is num ||
          (rawMetadata['status'] is String && rawMetadata['title'] is String));
  return isOffer ? {...json, 'type': 'OFFER'} : json;
}
