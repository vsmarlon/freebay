import 'package:freezed_annotation/freezed_annotation.dart';
import 'review_user_info.dart';

export 'review_user_info.dart';
export 'review_list_response.dart';

part 'review_entity.freezed.dart';
part 'review_entity.g.dart';

enum ReviewType { buyerReviewingSeller, sellerReviewingBuyer }

ReviewType _reviewTypeFromJson(String value) =>
    value == 'BUYER_REVIEWING_SELLER'
    ? ReviewType.buyerReviewingSeller
    : ReviewType.sellerReviewingBuyer;

String _reviewTypeToJson(ReviewType type) =>
    type == ReviewType.buyerReviewingSeller
    ? 'BUYER_REVIEWING_SELLER'
    : 'SELLER_REVIEWING_BUYER';

@freezed
abstract class ReviewEntity with _$ReviewEntity {
  const factory ReviewEntity({
    required String id,
    required String reviewerId,
    required String reviewedId,
    required String orderId,
    @JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson)
    required ReviewType type,
    required int score,
    String? comment,
    @Default([]) List<String> images,
    required DateTime createdAt,
    ReviewUserInfo? reviewer,
  }) = _ReviewEntity;

  factory ReviewEntity.fromJson(Map<String, dynamic> json) =>
      _$ReviewEntityFromJson(json);
}
