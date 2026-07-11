import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_checkout_entity.freezed.dart';
part 'cart_checkout_entity.g.dart';

@freezed
abstract class CartCheckoutItemEntity with _$CartCheckoutItemEntity {
  const factory CartCheckoutItemEntity({
    required String orderId,
    required String productId,
    required String productTitle,
    @Default(1) int quantity,
    @Default(0) int amount,
    @Default('') String pixQrCode,
    @Default('') String pixImage,
    required DateTime expiresAt,
  }) = _CartCheckoutItemEntity;

  factory CartCheckoutItemEntity.fromJson(Map<String, dynamic> json) =>
      _$CartCheckoutItemEntityFromJson(json);
}

@freezed
abstract class CartCheckoutEntity with _$CartCheckoutEntity {
  const factory CartCheckoutEntity({
    required List<CartCheckoutItemEntity> items,
    @Default(0) int totalOrders,
    @Default(0) int totalAmount,
  }) = _CartCheckoutEntity;

  factory CartCheckoutEntity.fromJson(Map<String, dynamic> json) =>
      _$CartCheckoutEntityFromJson(json);
}
