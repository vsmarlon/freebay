import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/cart/data/entities/cart_item_entity.dart';

part 'cart_entity.g.dart';

@JsonSerializable()
class CartEntity extends Equatable {
  final List<CartItemEntity> items;
  final int totalItems;
  final int totalPrice;

  const CartEntity({
    required this.items,
    required this.totalItems,
    required this.totalPrice,
  });

  factory CartEntity.fromJson(Map<String, dynamic> json) =>
      _$CartEntityFromJson(json);

  Map<String, dynamic> toJson() => _$CartEntityToJson(this);

  @override
  List<Object?> get props => [items, totalItems, totalPrice];
}
