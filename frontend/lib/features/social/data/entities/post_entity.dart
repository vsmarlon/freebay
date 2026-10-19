import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';

part 'post_entity.freezed.dart';
part 'post_entity.g.dart';

enum PostType {
  @JsonValue('PRODUCT')
  product('PRODUCT'),
  @JsonValue('REGULAR')
  regular('REGULAR');

  const PostType(this.wireValue);

  final String wireValue;
}

enum PostAudience {
  @JsonValue('EVERYONE')
  everyone('EVERYONE'),
  @JsonValue('CLOSE_FRIENDS')
  closeFriends('CLOSE_FRIENDS');

  const PostAudience(this.wireValue);
  final String wireValue;
}

ProductCondition _productConditionFromJson(Object? value) {
  return ProductCondition.values.firstWhere(
    (condition) => condition.wireValue == value,
    orElse: () => ProductCondition.isNew,
  );
}

String _productConditionToJson(ProductCondition condition) =>
    condition.wireValue;

@freezed
abstract class PostProductInfo with _$PostProductInfo {
  const factory PostProductInfo({
    required String id,
    required String title,
    required String description,
    @Default(0) int price,
    @JsonKey(
      name: 'condition',
      fromJson: _productConditionFromJson,
      toJson: _productConditionToJson,
    )
    @Default(ProductCondition.isNew)
    ProductCondition condition,
  }) = _PostProductInfo;

  factory PostProductInfo.fromJson(Map<String, dynamic> json) =>
      _$PostProductInfoFromJson(json);
}

@freezed
abstract class PostEntity with _$PostEntity {
  const factory PostEntity({
    required String id,
    required String userId,
    String? content,
    String? imageUrl,
    String? imageBlurHash,
    @Default(PostType.regular) PostType type,
    @Default(PostAudience.everyone) PostAudience audience,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(0) int sharesCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
    @Default(false) bool hasReposted,
    DateTime? repostedAt,
    UserEntity? repostedBy,
    required DateTime createdAt,
    required UserEntity user,
    PostProductInfo? product,
    @Default(false) bool isQuote,
    QuoteSource? quoteSource,
  }) = _PostEntity;

  factory PostEntity.fromJson(Map<String, dynamic> json) =>
      _$PostEntityFromJson(json);
}

@Freezed(unionKey: 'kind')
sealed class QuoteSource with _$QuoteSource {
  const factory QuoteSource.post({
    required String id,
    required PostEntity post,
  }) = QuotePostSource;
  const factory QuoteSource.comment({
    required String id,
    required String postId,
    required CommentEntity comment,
  }) = QuoteCommentSource;

  factory QuoteSource.fromJson(Map<String, dynamic> json) =>
      _$QuoteSourceFromJson(json);
}
