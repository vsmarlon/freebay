import 'package:freezed_annotation/freezed_annotation.dart';

part 'crypto_payment_entity.freezed.dart';
part 'crypto_payment_entity.g.dart';

@freezed
abstract class CryptoPaymentEntity with _$CryptoPaymentEntity {
  const factory CryptoPaymentEntity({
    required String orderId,
    @Default('XMR') String currency,
    required String address,
    String? paymentId,
    required String uriQrCode,
    required String amountAtomic,
    required String amountHuman,
    required DateTime expiresAt,
  }) = _CryptoPaymentEntity;

  factory CryptoPaymentEntity.fromJson(Map<String, dynamic> json) =>
      _$CryptoPaymentEntityFromJson(json);
}
