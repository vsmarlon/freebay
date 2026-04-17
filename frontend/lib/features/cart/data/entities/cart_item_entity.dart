import 'package:equatable/equatable.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

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
    final productMap = Map<String, dynamic>.from(json['product'] as Map);
    if (productMap['seller'] != null) {
      productMap['sellerName'] = productMap['seller']['displayName'];
      productMap['sellerAvatar'] = productMap['seller']['avatarUrl'];
    }
    final images = productMap['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final firstImage = images.first as Map;
      productMap['imageUrl'] = firstImage['url'];
    }

    return CartItemEntity(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toInt(),
      product: ProductEntity.fromJson(productMap),
    );
  }

  @override
  List<Object?> get props => [id, productId, quantity, subtotal, product];
}
