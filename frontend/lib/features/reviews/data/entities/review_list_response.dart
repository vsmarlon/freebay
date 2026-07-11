import 'package:freezed_annotation/freezed_annotation.dart';
import 'review_entity.dart';

part 'review_list_response.freezed.dart';
part 'review_list_response.g.dart';

@freezed
abstract class ReviewListResponse with _$ReviewListResponse {
  const ReviewListResponse._();

  const factory ReviewListResponse({
    required List<ReviewEntity> reviews,
    required int total,
    required int limit,
    required int offset,
  }) = _ReviewListResponse;

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewListResponseFromJson(json);

  bool get hasMore => offset + reviews.length < total;
}
