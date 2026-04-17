import 'package:equatable/equatable.dart';
import 'package:freebay/features/cart/data/entities/cart_item_entity.dart';

class CartEntity extends Equatable {
  final List<CartItemEntity> items;
  final int totalItems;
  final int totalPrice;

  const CartEntity({
    required this.items,
    required this.totalItems,
    required this.totalPrice,
  });

  factory CartEntity.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? [];
    return CartEntity(
      items: itemsJson
          .map((item) => CartItemEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, totalItems, totalPrice];
}
