import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_entity.g.dart';

enum ReviewType {
  buyerReviewingSeller,
  sellerReviewingBuyer,
}

ReviewType _reviewTypeFromJson(String value) =>
    value == 'BUYER_REVIEWING_SELLER'
        ? ReviewType.buyerReviewingSeller
        : ReviewType.sellerReviewingBuyer;

String _reviewTypeToJson(ReviewType type) =>
    type == ReviewType.buyerReviewingSeller
        ? 'BUYER_REVIEWING_SELLER'
        : 'SELLER_REVIEWING_BUYER';

@JsonSerializable()
class ReviewEntity extends Equatable {
  final String id;
  final String reviewerId;
  final String reviewedId;
  final String orderId;
  @JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson)
  final ReviewType type;
  final int score;
  final String? comment;
  @JsonKey(defaultValue: [])
  final List<String> images;
  final DateTime createdAt;
  final ReviewUserInfo? reviewer;

  const ReviewEntity({
    required this.id,
    required this.reviewerId,
    required this.reviewedId,
    required this.orderId,
    required this.type,
    required this.score,
    this.comment,
    this.images = const [],
    required this.createdAt,
    this.reviewer,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> json) =>
      _$ReviewEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewEntityToJson(this);

  @override
  List<Object?> get props => [
        id,
        reviewerId,
        reviewedId,
        orderId,
        type,
        score,
        comment,
        images,
        createdAt,
        reviewer,
      ];
}

@JsonSerializable()
class ReviewUserInfo extends Equatable {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  const ReviewUserInfo({
    required this.id,
    this.displayName,
    this.avatarUrl,
  });

  String get displayNameOrDefault => displayName ?? 'Usuário';

  factory ReviewUserInfo.fromJson(Map<String, dynamic> json) =>
      _$ReviewUserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewUserInfoToJson(this);

  @override
  List<Object?> get props => [id, displayName, avatarUrl];
}

@JsonSerializable()
class ReviewListResponse {
  final List<ReviewEntity> reviews;
  final int total;
  final int limit;
  final int offset;

  const ReviewListResponse({
    required this.reviews,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewListResponseToJson(this);

  bool get hasMore => offset + reviews.length < total;
}
