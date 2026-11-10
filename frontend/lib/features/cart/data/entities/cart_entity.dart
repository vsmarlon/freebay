import 'package:freezed_annotation/freezed_annotation.dart';
import 'cart_item_entity.dart';

part 'cart_entity.freezed.dart';
part 'cart_entity.g.dart';

@freezed
abstract class CartEntity with _$CartEntity {
  const factory CartEntity({
    @Default([]) List<CartItemEntity> items,
    @Default(0) int totalItems,
    @Default(0) int totalPrice,
  }) = _CartEntity;

  factory CartEntity.fromJson(Map<String, dynamic> json) =>
      _$CartEntityFromJson(json);
}
