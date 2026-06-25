import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cart_checkout_entity.g.dart';

@JsonSerializable()
class CartCheckoutItemEntity extends Equatable {
  final String orderId;
  final String productId;
  final String productTitle;
  @JsonKey(defaultValue: 1)
  final int quantity;
  @JsonKey(defaultValue: 0)
  final int amount;
  @JsonKey(defaultValue: '')
  final String pixQrCode;
  @JsonKey(defaultValue: '')
  final String pixImage;
  final DateTime expiresAt;

  const CartCheckoutItemEntity({
    required this.orderId,
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.amount,
    required this.pixQrCode,
    required this.pixImage,
    required this.expiresAt,
  });

  factory CartCheckoutItemEntity.fromJson(Map<String, dynamic> json) =>
      _$CartCheckoutItemEntityFromJson(json);

  Map<String, dynamic> toJson() => _$CartCheckoutItemEntityToJson(this);

  @override
  List<Object?> get props => [
        orderId,
        productId,
        productTitle,
        quantity,
        amount,
        pixQrCode,
        pixImage,
        expiresAt,
      ];
}

@JsonSerializable()
class CartCheckoutEntity extends Equatable {
  final List<CartCheckoutItemEntity> items;
  @JsonKey(defaultValue: 0)
  final int totalOrders;
  @JsonKey(defaultValue: 0)
  final int totalAmount;

  const CartCheckoutEntity({
    required this.items,
    required this.totalOrders,
    required this.totalAmount,
  });

  factory CartCheckoutEntity.fromJson(Map<String, dynamic> json) =>
      _$CartCheckoutEntityFromJson(json);

  Map<String, dynamic> toJson() => _$CartCheckoutEntityToJson(this);

  @override
  List<Object?> get props => [items, totalOrders, totalAmount];
}
