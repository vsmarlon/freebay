import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

part 'cart_item_entity.freezed.dart';
part 'cart_item_entity.g.dart';

@freezed
abstract class CartItemEntity with _$CartItemEntity {
  const factory CartItemEntity({
    required String id,
    required String productId,
    @Default(1) int quantity,
    @Default(0) int subtotal,
    required ProductEntity product,
  }) = _CartItemEntity;

  factory CartItemEntity.fromJson(Map<String, dynamic> json) =>
      _$CartItemEntityFromJson(json);
}
