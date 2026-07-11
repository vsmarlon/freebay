import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/product/data/entities/product_image_entity.dart';

part 'product_entity.freezed.dart';
part 'product_entity.g.dart';

@freezed
abstract class ProductEntity with _$ProductEntity {
  const ProductEntity._();

  const factory ProductEntity({
    required String id,
    required String title,
    required String description,
    required int price,
    required String condition,
    required String status,
    required String sellerId,
    String? postId,
    UserEntity? seller,
    List<ProductImageEntity>? images,
    @Default(1) int quantity,
    @Default(0) int soldCount,
  }) = _ProductEntity;

  factory ProductEntity.fromJson(Map<String, dynamic> json) =>
      _$ProductEntityFromJson(json);

  String? get sellerName => seller?.displayName;
  String? get sellerAvatar => seller?.avatarUrl;
  String? get imageUrl =>
      (images != null && images!.isNotEmpty) ? images!.first.url : null;
}
