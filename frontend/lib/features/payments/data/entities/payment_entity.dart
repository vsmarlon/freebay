import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_entity.freezed.dart';
part 'payment_entity.g.dart';

@freezed
abstract class PaymentEntity with _$PaymentEntity {
  const factory PaymentEntity({
    required String orderId,
    required String stripeSessionId,
    required String checkoutUrl,
    required DateTime expiresAt,
  }) = _PaymentEntity;

  factory PaymentEntity.fromJson(Map<String, dynamic> json) =>
      _$PaymentEntityFromJson(json);
}
