import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_image_entity.freezed.dart';
part 'product_image_entity.g.dart';

@freezed
abstract class ProductImageEntity with _$ProductImageEntity {
  const factory ProductImageEntity({
    required String id,
    required String url,
    String? blurHash,
    @Default(0) int order,
    required String productId,
  }) = _ProductImageEntity;

  factory ProductImageEntity.fromJson(Map<String, dynamic> json) =>
      _$ProductImageEntityFromJson(json);
}
