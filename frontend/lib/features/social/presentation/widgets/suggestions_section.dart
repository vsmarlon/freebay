import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/eyebrow_label.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/user_search_list.dart';

class SuggestionsSection extends ConsumerWidget {
  final bool shrinkWrap;

  const SuggestionsSection({super.key, this.shrinkWrap = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suggestionsProvider);

    if (state.isLoading) {
      return _wrap(context, const ShimmerBlock(height: 72));
    }

    if (state.error != null) {
      return _wrap(
        context,
        Text(
          state.error!,
          style: const TextStyle(fontSize: 13, color: AppColors.mediumGray),
        ),
      );
    }

    if (state.users.isEmpty) return const SizedBox.shrink();

    return _wrap(
      context,
      UserSearchList(
        users: state.users,
        isLoading: false,
        shrinkWrap: shrinkWrap,
        onFollow: (userId) async {
          await ref.read(socialRepositoryProvider).followUser(userId);
          await ref.read(suggestionsProvider.notifier).loadSuggestions();
        },
        onUnfollow: (userId) async {
          await ref.read(socialRepositoryProvider).unfollowUser(userId);
          await ref.read(suggestionsProvider.notifier).loadSuggestions();
        },
      ),
    );
  }

  Widget _wrap(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: EyebrowLabel('Quem seguir'),
          ),
          Spacing.vSm,
          child,
        ],
      ),
    );
  }
}
