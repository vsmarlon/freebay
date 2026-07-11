import 'package:freezed_annotation/freezed_annotation.dart';

part 'pix_payment_entity.freezed.dart';
part 'pix_payment_entity.g.dart';

@freezed
abstract class PixPaymentEntity with _$PixPaymentEntity {
  const factory PixPaymentEntity({
    required String orderId,
    @Default('') String pixQrCode,
    @Default('') String pixImage,
    required DateTime expiresAt,
  }) = _PixPaymentEntity;

  factory PixPaymentEntity.fromJson(Map<String, dynamic> json) =>
      _$PixPaymentEntityFromJson(json);
}
