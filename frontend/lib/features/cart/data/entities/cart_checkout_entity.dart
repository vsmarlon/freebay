import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_checkout_entity.freezed.dart';
part 'cart_checkout_entity.g.dart';

class CartCheckoutRecoveryEntity {
  const CartCheckoutRecoveryEntity({
    required this.status,
    required this.paymentGroupId,
    required this.orderIds,
    required this.totalAmount,
    this.checkoutUrl,
    this.paymentIntentClientSecret,
  });

  final String status;
  final String paymentGroupId;
  final List<String> orderIds;
  final int totalAmount;
  final String? checkoutUrl;
  final String? paymentIntentClientSecret;

  factory CartCheckoutRecoveryEntity.fromJson(Map<String, dynamic> json) =>
      CartCheckoutRecoveryEntity(
        status: json['status'] as String,
        paymentGroupId: json['paymentGroupId'] as String,
        orderIds: (json['orderIds'] as List<dynamic>).cast<String>(),
        totalAmount: json['totalAmount'] as int,
        checkoutUrl: json['checkoutUrl'] as String?,
        paymentIntentClientSecret: json['paymentIntentClientSecret'] as String?,
      );
}

@freezed
abstract class CartCheckoutItemEntity with _$CartCheckoutItemEntity {
  const factory CartCheckoutItemEntity({
    required String orderId,
    required String productId,
    required String productTitle,
    @Default(1) int quantity,
    @Default(0) int amount,
  }) = _CartCheckoutItemEntity;

  factory CartCheckoutItemEntity.fromJson(Map<String, dynamic> json) =>
      _$CartCheckoutItemEntityFromJson(json);
}

@freezed
abstract class CartCheckoutEntity with _$CartCheckoutEntity {
  const factory CartCheckoutEntity({
    required String paymentGroupId,
    @Default([]) List<CartCheckoutItemEntity> items,
    @Default(0) int totalOrders,
    @Default(0) int totalAmount,
    String? checkoutUrl,
    String? paymentIntentClientSecret,
    DateTime? expiresAt,
  }) = _CartCheckoutEntity;

  factory CartCheckoutEntity.fromJson(Map<String, dynamic> json) =>
      _$CartCheckoutEntityFromJson(json);
}
