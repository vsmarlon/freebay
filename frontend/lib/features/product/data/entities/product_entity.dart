import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_entity.g.dart';

@JsonSerializable()
class ProductEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final int price;
  final String condition;
  final String status;
  final String sellerId;
  final String? postId;

  @JsonKey(name: 'sellerName')
  final String? sellerName;

  @JsonKey(name: 'sellerAvatar')
  final String? sellerAvatar;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.status,
    required this.sellerId,
    this.postId,
    this.sellerName,
    this.sellerAvatar,
  });

  factory ProductEntity.fromJson(Map<String, dynamic> json) =>
      _$ProductEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ProductEntityToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        price,
        condition,
        status,
        sellerId,
        postId,
        sellerName,
        sellerAvatar,
      ];
}
