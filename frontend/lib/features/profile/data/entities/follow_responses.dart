import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_responses.freezed.dart';
part 'follow_responses.g.dart';

@freezed
abstract class FollowResponse with _$FollowResponse {
  const factory FollowResponse({
    required bool following,
    required int followersCount,
    required int followingCount,
  }) = _FollowResponse;

  factory FollowResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowResponseFromJson(json);
}

@freezed
abstract class FollowStatusResponse with _$FollowStatusResponse {
  const factory FollowStatusResponse({
    required bool isFollowing,
    required int followersCount,
    required int followingCount,
  }) = _FollowStatusResponse;

  factory FollowStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowStatusResponseFromJson(json);
}

@freezed
abstract class FollowListUser with _$FollowListUser {
  const factory FollowListUser({
    required String id,
    required String displayName,
    String? avatarUrl,
    required bool isVerified,
    required double reputationScore,
  }) = _FollowListUser;

  factory FollowListUser.fromJson(Map<String, dynamic> json) =>
      _$FollowListUserFromJson(json);
}

@freezed
abstract class FollowListResponse with _$FollowListResponse {
  const factory FollowListResponse({
    @Default([]) List<FollowListUser> users,
    required int total,
    required int limit,
    required int offset,
  }) = _FollowListResponse;

  factory FollowListResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowListResponseFromJson(json);
}
