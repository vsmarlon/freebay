import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_entity.freezed.dart';
part 'notification_entity.g.dart';

@freezed
abstract class NotificationEntity with _$NotificationEntity {
  const NotificationEntity._();

  const factory NotificationEntity({
    required String id,
    required String type,
    required String title,
    required String body,
    @JsonKey() Map<String, dynamic>? data,
    required bool read,
    required DateTime createdAt,
  }) = _NotificationEntity;

  factory NotificationEntity.fromJson(Map<String, dynamic> json) =>
      _$NotificationEntityFromJson(json);

  String? get orderId => data?['orderId'] as String?;
  String? get senderId => data?['senderId'] as String?;
  String? get conversationId => data?['conversationId'] as String?;
  String? get userId => data?['userId'] as String?;
}
