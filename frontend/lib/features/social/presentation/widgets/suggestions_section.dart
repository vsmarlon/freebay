import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';

class SuggestionsSection extends ConsumerWidget {
  final bool asSliver;

  const SuggestionsSection({super.key, this.asSliver = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suggestionsProvider);

    if (state.isLoading) {
      return _wrapWidget(const ShimmerBlock(height: 72));
    }

    if (state.error != null) {
      return _wrapWidget(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            state.error!,
            style: const TextStyle(fontSize: 13, color: AppColors.mediumGray),
          ),
        ),
      );
    }

    if (state.users.isEmpty) {
      return asSliver
          ? const SliverToBoxAdapter(child: SizedBox.shrink())
          : const SizedBox.shrink();
    }

    return _wrapWidget(
      SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(left: 16, right: 16),
          itemCount: state.users.length + 1, // +1 for "Ver mais"
          itemBuilder: (ctx, i) {
            if (i == state.users.length) {
              return _buildSeeMoreCard(context, ref, state.isLoading);
            }
            return _CompactSuggestionCard(
              user: state.users[i],
              onFollow: (userId) async {
                await ref.read(socialRepositoryProvider).followUser(userId);
              },
              onUnfollow: (userId) async {
                await ref.read(socialRepositoryProvider).unfollowUser(userId);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeeMoreCard(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => ref.read(suggestionsProvider.notifier).fetchMore(),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryContainer,
                  ),
                )
              else ...[
                const Icon(
                  Icons.arrow_forward,
                  size: 24,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(height: 4),
                const Text(
                  'VER MAIS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrapWidget(Widget child) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: EyebrowLabel('Quem seguir'),
        ),
        Spacing.vSm,
        child,
      ],
    );

    if (asSliver) {
      return SliverPadding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        sliver: SliverToBoxAdapter(child: column),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: column,
    );
  }
}

class _CompactSuggestionCard extends ConsumerStatefulWidget {
  final UserSearchEntity user;
  final Function(String userId) onFollow;
  final Function(String userId) onUnfollow;

  const _CompactSuggestionCard({
    required this.user,
    required this.onFollow,
    required this.onUnfollow,
  });

  @override
  ConsumerState<_CompactSuggestionCard> createState() =>
      _CompactSuggestionCardState();
}

class _CompactSuggestionCardState
    extends ConsumerState<_CompactSuggestionCard> {
  bool _isLoading = false;
  bool? _isFollowingOverride;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).value;
    final isOwnCard = currentUser != null && currentUser.id == widget.user.id;
    final followStatus = ref.watch(followStatusProvider(widget.user.id));
    final isFollowing =
        _isFollowingOverride ?? (followStatus.value?.isFollowing ?? false);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => context.push('/user/${widget.user.id}'),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  image: widget.user.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.user.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: context.surfaceMidColor,
                ),
                child: widget.user.avatarUrl == null
                    ? Center(
                        child: Text(
                          widget.user.displayName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              // Display name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  widget.user.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Follow button
              if (!isOwnCard)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: followStatus.isLoading && _isFollowingOverride == null
                      ? const ShimmerBlock(width: 80, height: 32)
                      : AppButton(
                          label: isFollowing ? 'Seguindo' : 'Seguir',
                          variant: isFollowing
                              ? AppButtonVariant.ghost
                              : AppButtonVariant.primary,
                          size: AppButtonSize.compact,
                          isLoading: _isLoading,
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            if (isFollowing) {
                              await widget.onUnfollow(widget.user.id);
                            } else {
                              await widget.onFollow(widget.user.id);
                            }
                            ref.invalidate(
                              followStatusProvider(widget.user.id),
                            );
                            setState(() {
                              _isFollowingOverride = !isFollowing;
                              _isLoading = false;
                            });
                          },
                        ),
                ),
              if (isOwnCard) const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
