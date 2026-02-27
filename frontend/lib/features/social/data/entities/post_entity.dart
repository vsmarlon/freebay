import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_entity.g.dart';

@JsonSerializable()
class PostEntity extends Equatable {
  final String id;
  final String userId;
  final String? content;
  final String? imageUrl;
  final String type;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final DateTime createdAt;
  final UserEntity user;
  final ProductInfo? product;

  const PostEntity({
    required this.id,
    required this.userId,
    this.content,
    this.imageUrl,
    this.type = 'REGULAR',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.user,
    this.product,
  });

  factory PostEntity.fromJson(Map<String, dynamic> json) =>
      _$PostEntityFromJson(json);
  Map<String, dynamic> toJson() => _$PostEntityToJson(this);

  PostEntity copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    String? type,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    DateTime? createdAt,
    UserEntity? user,
    ProductInfo? product,
  }) {
    return PostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      product: product ?? this.product,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        content,
        imageUrl,
        type,
        likesCount,
        commentsCount,
        sharesCount,
        isLiked,
        createdAt,
        product,
      ];
}

@JsonSerializable()
class ProductInfo extends Equatable {
  final String id;
  final String title;
  final String description;
  final int price;
  final String condition;

  const ProductInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) =>
      _$ProductInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductInfoToJson(this);

  @override
  List<Object?> get props => [id, title, description, price, condition];
}

@JsonSerializable()
class UserEntity extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final double reputationScore;
  final int totalReviews;

  const UserEntity({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
    this.reputationScore = 0,
    this.totalReviews = 0,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
  Map<String, dynamic> toJson() => _$UserEntityToJson(this);

  @override
  List<Object?> get props =>
      [id, displayName, avatarUrl, isVerified, reputationScore, totalReviews];
}
