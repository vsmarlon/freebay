import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

part 'social_provider_states.freezed.dart';

@freezed
abstract class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<PostEntity> posts,
    @Default(false) bool isLoading,
    @Default(true) bool hasMore,
    String? cursor,
    String? error,
  }) = _FeedState;
}

@freezed
abstract class LikesState with _$LikesState {
  const factory LikesState({
    @Default({}) Map<String, bool> likedOverrides,
    @Default({}) Map<String, int> countOverrides,
  }) = _LikesState;
}

extension LikesStateX on LikesState {
  bool? getLikedOverride(String postId) => likedOverrides[postId];
  int? getCountOverride(String postId) => countOverrides[postId];
}

@freezed
abstract class SavesState with _$SavesState {
  const factory SavesState({@Default({}) Map<String, bool> savedOverrides}) =
      _SavesState;
}

extension SavesStateX on SavesState {
  bool? getSavedOverride(String postId) => savedOverrides[postId];
}

@freezed
abstract class RepostsState with _$RepostsState {
  const factory RepostsState({
    @Default({}) Map<String, bool> repostedOverrides,
    @Default({}) Map<String, int> countOverrides,
  }) = _RepostsState;
}

extension RepostsStateX on RepostsState {
  bool? getRepostedOverride(String postId) => repostedOverrides[postId];
  int? getCountOverride(String postId) => countOverrides[postId];
}

@freezed
abstract class CommentLikesState with _$CommentLikesState {
  const factory CommentLikesState({
    @Default({}) Map<String, bool> likedOverrides,
    @Default({}) Map<String, int> countOverrides,
  }) = _CommentLikesState;
}

extension CommentLikesStateX on CommentLikesState {
  bool? getLikedOverride(String commentId) => likedOverrides[commentId];
  int? getCountOverride(String commentId) => countOverrides[commentId];
}
