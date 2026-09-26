import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_entity.freezed.dart';
part 'notification_entity.g.dart';

enum NotificationType {
  order('ORDER'),
  follow('FOLLOW'),
  message('MESSAGE'),
  dispute('DISPUTE'),
  payment('PAYMENT'),
  mention('MENTION'),
  unknown('UNKNOWN');

  const NotificationType(this.wireValue);

  final String wireValue;

  static NotificationType fromWire(String? value) => values.firstWhere(
    (type) => type.wireValue == value,
    orElse: () => NotificationType.unknown,
  );
}

class NotificationTypeConverter
    implements JsonConverter<NotificationType, String> {
  const NotificationTypeConverter();

  @override
  NotificationType fromJson(String value) => NotificationType.fromWire(value);

  @override
  String toJson(NotificationType type) => type.wireValue;
}

@freezed
abstract class NotificationEntity with _$NotificationEntity {
  const NotificationEntity._();

  const factory NotificationEntity({
    required String id,
    @NotificationTypeConverter() required NotificationType type,
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
