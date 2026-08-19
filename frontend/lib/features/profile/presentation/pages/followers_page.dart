import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/user_list_tile.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

final followersProvider = FutureProvider.family<List<FollowerEntity>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getFollowers(userId);
  return result.fold((f) => throw Exception(f.message), (list) => list);
});

class FollowersPage extends ConsumerWidget {
  final String userId;

  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followersProvider(userId));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'SEGUIDORES',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
            breadcrumbs: context.breadcrumbs,
          ),
          Expanded(
            child: followersAsync.when(
              data: (followers) {
                if (followers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'NENHUM SEGUIDOR',
                    subtitle: 'Nenhum seguidor ainda.',
                  );
                }

                final currentUserId = ref
                    .watch(authControllerProvider)
                    .value
                    ?.id;
                final sortedFollowers = List<FollowerEntity>.from(followers);
                if (currentUserId != null) {
                  final selfIndex = sortedFollowers.indexWhere(
                    (f) => f.id == currentUserId,
                  );
                  if (selfIndex > 0) {
                    final self = sortedFollowers.removeAt(selfIndex);
                    sortedFollowers.insert(0, self);
                  }
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(followersProvider(userId)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortedFollowers.length,
                    itemBuilder: (context, index) {
                      final f = sortedFollowers[index];
                      final isSelf = f.id == currentUserId;

                      return UserListTile(
                        user: UserListTileItem(
                          id: f.id,
                          displayName: f.displayName,
                          username: f.displayName,
                          avatarUrl: f.avatarUrl,
                          bio: f.bio,
                        ),
                        trailing: isSelf
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                color: context.surfaceMidColor,
                                child: Text(
                                  'VOCÊ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: context.textSecondary,
                                  ),
                                ),
                              )
                            : AppButton(
                                label: f.isFollowing ? 'SEGUINDO' : 'SEGUIR',
                                size: AppButtonSize.compact,
                                variant: f.isFollowing
                                    ? AppButtonVariant.secondary
                                    : AppButtonVariant.primary,
                                onPressed: () async {
                                  if (f.isFollowing) {
                                    await ref
                                        .read(socialRepositoryProvider)
                                        .unfollowUser(f.id);
                                  } else {
                                    await ref
                                        .read(socialRepositoryProvider)
                                        .followUser(f.id);
                                  }
                                  ref.invalidate(followersProvider(userId));
                                },
                              ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SkeletonPage(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    ShimmerBlock(height: 60),
                    SizedBox(height: 12),
                    ShimmerBlock(height: 60),
                    SizedBox(height: 12),
                    ShimmerBlock(height: 60),
                  ],
                ),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Erro ao carregar',
                      style: TextStyle(color: context.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'TENTAR NOVAMENTE',
                      size: AppButtonSize.compact,
                      onPressed: () =>
                          ref.invalidate(followersProvider(userId)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
