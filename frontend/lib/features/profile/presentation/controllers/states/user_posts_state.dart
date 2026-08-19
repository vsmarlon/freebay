import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

part 'user_posts_state.freezed.dart';
part 'user_posts_state.g.dart';

@freezed
abstract class UserPostsState with _$UserPostsState {
  const factory UserPostsState({
    @Default([]) List<PostEntity> posts,
    @Default(false) bool isLoading,
    String? cursor,
    @Default(true) bool hasMore,
  }) = _UserPostsState;

  factory UserPostsState.fromJson(Map<String, dynamic> json) =>
      _$UserPostsStateFromJson(json);
}
