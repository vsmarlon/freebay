import 'package:freezed_annotation/freezed_annotation.dart';

part 'block_responses.freezed.dart';
part 'block_responses.g.dart';

@freezed
abstract class BlockListUser with _$BlockListUser {
  const factory BlockListUser({
    required String id,
    required String displayName,
    String? avatarUrl,
    required bool isVerified,
    required double reputationScore,
  }) = _BlockListUser;

  factory BlockListUser.fromJson(Map<String, dynamic> json) =>
      _$BlockListUserFromJson(json);
}

@freezed
abstract class BlockListResponse with _$BlockListResponse {
  const factory BlockListResponse({
    @Default([]) List<BlockListUser> users,
    required int limit,
    required int offset,
  }) = _BlockListResponse;

  factory BlockListResponse.fromJson(Map<String, dynamic> json) =>
      _$BlockListResponseFromJson(json);
}

@freezed
abstract class UnblockResponse with _$UnblockResponse {
  const factory UnblockResponse({required bool blocked}) = _UnblockResponse;

  factory UnblockResponse.fromJson(Map<String, dynamic> json) =>
      _$UnblockResponseFromJson(json);
}

@freezed
abstract class BlockResponse with _$BlockResponse {
  const factory BlockResponse({required bool blocked}) = _BlockResponse;

  factory BlockResponse.fromJson(Map<String, dynamic> json) =>
      _$BlockResponseFromJson(json);
}
