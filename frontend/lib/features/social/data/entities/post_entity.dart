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

enum PostMediaType {
  @JsonValue('IMAGE')
  image('IMAGE'),
  @JsonValue('VIDEO')
  video('VIDEO');

  const PostMediaType(this.wireValue);
  final String wireValue;
}

@freezed
abstract class PostMediaEntity with _$PostMediaEntity {
  const PostMediaEntity._();

  const factory PostMediaEntity({
    required String id,
    required String url,
    String? thumbnailUrl,
    @Default(PostMediaType.image) PostMediaType type,
    String? altText,
    String? blurHash,
    @Default(0) int order,
  }) = _PostMediaEntity;

  factory PostMediaEntity.fromJson(Map<String, dynamic> json) =>
      _$PostMediaEntityFromJson(json);

  /// Videos render their required thumbnail; images render the full asset.
  String? get previewUrl => type == PostMediaType.video ? thumbnailUrl : url;
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
  const PostEntity._();

  const factory PostEntity({
    required String id,
    required String userId,
    String? content,
    @Default(<PostMediaEntity>[]) List<PostMediaEntity> media,
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

  List<PostMediaEntity> get orderedMedia =>
      [...media]..sort((first, second) => first.order.compareTo(second.order));

  PostMediaEntity? get firstMedia => media.isEmpty ? null : orderedMedia.first;
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
