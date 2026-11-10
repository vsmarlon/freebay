import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/profile/presentation/controllers/states/user_posts_state.dart';
import 'package:freebay/features/social/social.dart';
import 'package:freebay/shared/services/storage_service.dart';

part 'profile_controller.g.dart';

@riverpod
class UserPosts extends _$UserPosts {
  @override
  UserPostsState build(String userId) {
    Future.microtask(loadMore);
    return const UserPostsState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    final repository = ref.read(socialRepositoryProvider);
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    final result = await repository.getPostsByUser(
      userId,
      cursor: state.cursor,
      limit: 15,
      cancelToken: cancelToken,
    );
    if (!ref.mounted) return;

    result.fold((failure) => state = state.copyWith(isLoading: false), (page) {
      final postsById = <String, PostEntity>{
        for (final post in state.posts) post.id: post,
      };
      for (final post in page.items) {
        postsById[post.id] = post;
      }
      reconcileSocialPosts(ref, page.items);
      state = state.copyWith(
        posts: postsById.values.toList(),
        isLoading: false,
        hasMore: page.hasMore,
        cursor: page.nextCursor,
      );
    });
  }
}

// Providers
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// Provides user profile details
final profileFutureProvider = FutureProvider.autoDispose
    .family<UserEntity, String>((ref, userId) async {
      ref.watch(authControllerProvider);
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      final result = await ref
          .read(profileRepositoryProvider)
          .getProfile(userId, cancelToken: cancelToken);

      return result.fold((failure) => throw failure, (user) => user);
    });

class ProfileFirstPaint {
  const ProfileFirstPaint({
    required this.user,
    required this.isStale,
    this.error,
  });

  final UserEntity user;
  final bool isStale;
  final String? error;
}

final profileFirstPaintProvider = StreamProvider.autoDispose
    .family<ProfileFirstPaint, String>((ref, userId) async* {
      final auth = ref.watch(authControllerProvider);
      final ownerId = auth.asData?.value?.id;
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      final isOwnProfile =
          ownerId != null && (userId == 'me' || userId == ownerId);
      ProfileFirstPaint? stale;
      if (isOwnProfile) {
        final cache = await StorageService.readCachedJson(
          userId: ownerId,
          key: 'profile.header.v1',
        );
        if (ref.mounted &&
            ownerId == ref.read(authControllerProvider).asData?.value?.id) {
          final profile = _cachedPublicProfile(cache, ownerId);
          if (profile != null) {
            stale = ProfileFirstPaint(user: profile, isStale: true);
            yield stale;
          }
        }
      }

      final result = await ref
          .read(profileRepositoryProvider)
          .getProfile(userId, cancelToken: cancelToken);
      if (!ref.mounted ||
          ownerId != ref.read(authControllerProvider).asData?.value?.id) {
        return;
      }
      final fresh = result.fold<ProfileFirstPaint?>(
        (failure) {
          if (stale == null) throw failure;
          return ProfileFirstPaint(
            user: stale.user,
            isStale: true,
            error: failure.message,
          );
        },
        (user) {
          if (isOwnProfile) {
            unawaited(
              StorageService.writeCachedJson(
                userId: ownerId,
                key: 'profile.header.v1',
                json: _publicProfileJson(user),
              ),
            );
          }
          return ProfileFirstPaint(user: user, isStale: false);
        },
      );
      if (fresh != null) yield fresh;
    });

Map<String, Object?> _publicProfileJson(UserEntity user) => {
  'profileVersion': 1,
  'id': user.id,
  'displayName': user.displayName,
  'username': user.username,
  'avatarUrl': _safeCachedImageUrl(user.avatarUrl),
  'bannerUrl': _safeCachedImageUrl(user.bannerUrl),
  'bio': user.bio,
  'city': user.city,
  'state': user.state,
  'isVerified': user.isVerified,
  'reputationScore': user.reputationScore,
  'totalReviews': user.totalReviews,
  'salesCount': user.salesCount,
  'purchasesCount': user.purchasesCount,
  'followersCount': user.followersCount,
  'followingCount': user.followingCount,
  'postsCount': user.postsCount,
  'productsCount': user.productsCount,
};

String? _safeCachedImageUrl(String? url) {
  final normalized = url?.toLowerCase();
  return normalized != null &&
          (normalized.contains('/private/') ||
              normalized.contains('/signed/') ||
              normalized.contains('signature=') ||
              normalized.contains('token='))
      ? null
      : url;
}

UserEntity? _cachedPublicProfile(Map<String, Object?>? cache, String ownerId) {
  if (cache?['profileVersion'] != 1 || cache?['id'] != ownerId) return null;
  return UserEntity.fromJson(Map<String, dynamic>.from(cache!));
}

final profileStatsProvider = FutureProvider<UserStatsEntity>((ref) async {
  ref.watch(authControllerProvider);
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getProfileStats();

  return result.fold((failure) => throw failure, (stats) => stats);
});
