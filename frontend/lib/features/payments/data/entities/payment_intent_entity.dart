import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_intent_entity.freezed.dart';
part 'payment_intent_entity.g.dart';

@freezed
abstract class PaymentIntentEntity with _$PaymentIntentEntity {
  const factory PaymentIntentEntity({
    required String orderId,
    required String paymentIntentClientSecret,
  }) = _PaymentIntentEntity;

  factory PaymentIntentEntity.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentEntityFromJson(json);
}
