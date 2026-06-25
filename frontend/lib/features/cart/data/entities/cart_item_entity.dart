import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

part 'cart_item_entity.g.dart';

@JsonSerializable()
class CartItemEntity extends Equatable {
  final String id;
  final String productId;
  final int quantity;
  final int subtotal;
  final ProductEntity product;

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.subtotal,
    required this.product,
  });

  factory CartItemEntity.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    final seller = product['seller'] as Map?;
    final images = product['images'] as List?;

    return _$CartItemEntityFromJson({
      ...json,
      'product': {
        ...product,
        if (seller != null) 'sellerName': seller['displayName'],
        if (seller != null) 'sellerAvatar': seller['avatarUrl'],
        if (images != null && images.isNotEmpty)
          'imageUrl': (images.first as Map)['url'],
      },
    });
  }

  Map<String, dynamic> toJson() => _$CartItemEntityToJson(this);

  @override
  List<Object?> get props => [id, productId, quantity, subtotal, product];
}
