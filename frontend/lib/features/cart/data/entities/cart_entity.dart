import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/cart/data/entities/cart_item_entity.dart';

part 'cart_entity.freezed.dart';
part 'cart_entity.g.dart';

@freezed
abstract class CartEntity with _$CartEntity {
  const factory CartEntity({
    required List<CartItemEntity> items,
    required int totalItems,
    required int totalPrice,
  }) = _CartEntity;

  factory CartEntity.fromJson(Map<String, dynamic> json) =>
      _$CartEntityFromJson(json);
}
