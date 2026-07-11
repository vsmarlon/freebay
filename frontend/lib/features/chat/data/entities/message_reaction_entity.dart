import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_reaction_entity.freezed.dart';
part 'message_reaction_entity.g.dart';

@freezed
abstract class MessageReactionEntity with _$MessageReactionEntity {
  const factory MessageReactionEntity({
    required String emoji,
    required int count,
    required List<String> userIds,
  }) = _MessageReactionEntity;

  factory MessageReactionEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionEntityFromJson(json);
}
