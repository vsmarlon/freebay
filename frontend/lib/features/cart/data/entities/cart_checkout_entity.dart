import 'package:equatable/equatable.dart';

class CartCheckoutItemEntity extends Equatable {
  final String orderId;
  final String productId;
  final String productTitle;
  final int quantity;
  final int amount;
  final String pixQrCode;
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

  factory CartCheckoutItemEntity.fromJson(Map<String, dynamic> json) {
    return CartCheckoutItemEntity(
      orderId: json['orderId'] as String,
      productId: json['productId'] as String,
      productTitle: json['productTitle'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      pixQrCode: json['pixQrCode'] as String? ?? '',
      pixImage: json['pixImage'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

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

class CartCheckoutEntity extends Equatable {
  final List<CartCheckoutItemEntity> items;
  final int totalOrders;
  final int totalAmount;

  const CartCheckoutEntity({
    required this.items,
    required this.totalOrders,
    required this.totalAmount,
  });

  factory CartCheckoutEntity.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    return CartCheckoutEntity(
      items: itemsJson
          .map((item) =>
              CartCheckoutItemEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, totalOrders, totalAmount];
}
