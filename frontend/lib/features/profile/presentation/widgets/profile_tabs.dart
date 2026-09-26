import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';

class ProfileTabs extends ConsumerWidget {
  const ProfileTabs({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(profileTimelineProvider(user.id));
    final ownProfile = ref.watch(authControllerProvider).value?.id == user.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'PUBLICAÇÕES',
            style: AppTypography.brutalistTag.copyWith(
              color: context.textSecondary,
            ),
          ),
        ),
        if (timeline.entries.isEmpty && timeline.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerBlock(height: 160),
          )
        else if (timeline.entries.isEmpty && timeline.error == null)
          EmptyState(
            icon: Icons.article_outlined,
            title: 'NENHUMA PUBLICAÇÃO',
            subtitle: 'Posts e reposts aparecerão aqui.',
            action: ownProfile
                ? AppButton(
                    label: 'Criar post',
                    onPressed: () => context.push(AppRoutes.createPost),
                  )
                : null,
          )
        else ...[
          for (final entry in timeline.entries)
            FeedPostItem(
              key: ValueKey(entry.repostId ?? entry.post.id),
              post: entry.toPostEntity(),
            ),
          if (timeline.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerBlock(height: 120),
            ),
        ],
        if (timeline.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Tentar novamente',
              onPressed: () => ref
                  .read(profileTimelineProvider(user.id).notifier)
                  .loadMore(),
            ),
          ),
      ],
    );
  }
}
