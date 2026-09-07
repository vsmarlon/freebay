import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

final followingProvider = FutureProvider.family<List<FollowerEntity>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getFollowing(userId);
  return result.fold((f) => throw Exception(f.message), (list) => list);
});

class FollowingPage extends ConsumerWidget {
  final String userId;

  const FollowingPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProvider(userId));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'SEGUINDO',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            breadcrumbs: context.breadcrumbs,
          ),
          Expanded(
            child: followingAsync.when(
              data: (following) => following.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'NENHUMA CONEXÃO',
                      subtitle: 'Não está seguindo ninguém ainda.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(followingProvider(userId)),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: following.length,
                        itemBuilder: (context, index) {
                          final f = following[index];
                          return UserListTile(
                            user: UserListTileItem(
                              id: f.id,
                              displayName: f.displayName,
                              username: f.displayName,
                              avatarUrl: f.avatarUrl,
                              bio: f.bio,
                            ),
                            trailing: AppButton(
                              label: 'DEIXAR DE SEGUIR',
                              size: AppButtonSize.compact,
                              onPressed: () async {
                                await ref
                                    .read(socialRepositoryProvider)
                                    .unfollowUser(f.id);
                                ref.invalidate(followingProvider(userId));
                              },
                            ),
                          );
                        },
                      ),
                    ),
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
              error: (err, _) => EmptyState.error(
                message: 'Erro ao carregar',
                onRetry: () => ref.invalidate(followingProvider(userId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
