import 'package:json_annotation/json_annotation.dart';

part 'pix_payment_entity.g.dart';

@JsonSerializable()
class PixPaymentEntity {
  final String orderId;
  @JsonKey(defaultValue: '')
  final String pixQrCode;
  @JsonKey(defaultValue: '')
  final String pixImage;
  final DateTime expiresAt;

  const PixPaymentEntity({
    required this.orderId,
    required this.pixQrCode,
    required this.pixImage,
    required this.expiresAt,
  });

  factory PixPaymentEntity.fromJson(Map<String, dynamic> json) =>
      _$PixPaymentEntityFromJson(json);

  Map<String, dynamic> toJson() => _$PixPaymentEntityToJson(this);
}
