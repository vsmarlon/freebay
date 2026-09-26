import 'package:freezed_annotation/freezed_annotation.dart';

enum MessageType {
  @JsonValue('TEXT')
  text('TEXT'),
  @JsonValue('IMAGE')
  image('IMAGE'),
  @JsonValue('AUDIO')
  audio('AUDIO'),
  @JsonValue('VIDEO')
  video('VIDEO'),
  @JsonValue('GIF')
  gif('GIF'),
  @JsonValue('LOCATION')
  location('LOCATION'),
  @JsonValue('PRODUCT_CARD')
  productCard('PRODUCT_CARD'),
  // OFFER is not a Prisma MessageType, but existing UI callers still use it.
  unknown('OFFER');

  const MessageType(this.wireValue);

  final String wireValue;
}

MessageType messageTypeFromJson(Object? value) {
  return MessageType.values.firstWhere(
    (type) => type.wireValue == value,
    orElse: () => MessageType.unknown,
  );
}

String messageTypeToJson(MessageType type) => type.wireValue;
