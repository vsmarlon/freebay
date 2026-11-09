import 'package:flutter/material.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/pages/blocked_users_page.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_header.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileFutureProvider(userId));
    final profileName = profileAsync.value?.displayNameOrDefault;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            ShellScrollHeader(
              child: PageHeader(
                text: profileName ?? l10n(context).navProfile,
                leading: BrutalistIconButton(
                  icon: Icons.arrow_back,
                  semanticLabel: l10n(context).commonBack,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            Expanded(
              child: profileAsync.when(
                data: (profileUser) => ProfileRefresh(
                  onRefresh: () => _refreshProfile(ref),
                  child: _buildProfileContent(context, ref, profileUser),
                ),
                loading: () => const Center(
                  child: ShimmerScope(
                    child: ShimmerBlock(width: 60, height: 60),
                  ),
                ),
                error: (error, _) => EmptyState.error(
                  message: l10n(context).profileLoadFailed,
                  onRetry: () => ref.invalidate(profileFutureProvider(userId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProfile(WidgetRef ref) async {
    ref.invalidate(profileFutureProvider(userId));
    await Future.wait([
      ref
          .read(profileFutureProvider(userId).future)
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      refreshProfileTimelines(ref, userId),
    ]);
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.value;
    final isOwnProfile = currentUser != null && currentUser.id == user.id;
    final followStatusAsync = !isOwnProfile
        ? ref.watch(followStatusProvider(user.id))
        : const AsyncValue<FollowStatusResponse?>.data(null);

    return ProfileTabs(
      user: user,
      headerSlivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                followStatusAsync.when(
                  data: (status) => ProfileHeader(
                    user: user,
                    followersCount:
                        status?.followersCount ?? user.followersCount,
                    followingCount:
                        status?.followingCount ?? user.followingCount,
                  ),
                  loading: () => ProfileHeader(
                    user: user,
                    followersCount: user.followersCount,
                    followingCount: user.followingCount,
                  ),
                  error: (_, _) => ProfileHeader(
                    user: user,
                    followersCount: user.followersCount,
                    followingCount: user.followingCount,
                  ),
                ),
                Spacing.vLg,
                if (!isOwnProfile && currentUser != null)
                  followStatusAsync.when(
                    data: (status) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: (status?.isFollowing ?? false)
                              ? l10n(context).profileUnfollow
                              : l10n(context).profileFollow,
                          variant: (status?.isFollowing ?? false)
                              ? AppButtonVariant.ghost
                              : AppButtonVariant.primary,
                          onPressed: () async {
                            await ref
                                .read(followStateProvider.notifier)
                                .toggleFollow(
                                  user.id,
                                  fallbackFollowersCount: user.followersCount,
                                  fallbackFollowingCount: user.followingCount,
                                );
                          },
                        ),
                      ),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ShimmerScope(child: ShimmerBlock(height: 48)),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  )
                else if (!isOwnProfile)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFollowPrompt(context),
                  ),
                if (!isOwnProfile && currentUser != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: l10n(context).chatNewConversation,
                          variant: AppButtonVariant.secondary,
                          icon: Icons.chat_bubble_outline,
                          onPressed: () => _messageUser(context, ref),
                        ),
                      ),
                      Spacing.hSm,
                      Expanded(
                        child: AppButton(
                          label: l10n(context).chatBlockUser,
                          variant: AppButtonVariant.danger,
                          icon: Icons.block,
                          onPressed: () => _blockUser(context, ref, user),
                        ),
                      ),
                    ],
                  ),
                  Spacing.vMd,
                  AppButton(
                    label: l10n(context).profileReportUser,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _reportUser(context, user.id),
                  ),
                  Spacing.vMd,
                ],
                if (user.reputationScore > 0)
                  Center(
                    child: GestureDetector(
                      onTap: () => context.push(
                        '${AppRoutes.userReviewsPath(user.id)}?name=${Uri.encodeComponent(user.displayNameOrDefault)}',
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          border: Border.all(
                            color: AppColors.onSurface.withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            Spacing.hSm,
                            Text(
                              '${user.reputationScore.toStringAsFixed(1)} · ${l10n(context).profileReviewCount(user.totalReviews)}',
                              style: TextStyle(
                                fontFamily: AppTypography.headlineFontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            Spacing.hXs,
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        l10n(context).profileNoReviews,
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }

  Future<void> _messageUser(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(chatRepositoryProvider)
        .startDirectConversation(userId);
    if (!context.mounted) return;
    final conversationId = result.rightOrNull;
    if (conversationId == null) {
      AppSnackbar.handleFailure(context, result.leftOrNull);
      return;
    }
    context.push(AppRoutes.chatPath(conversationId));
  }

  Future<void> _blockUser(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) async {
    await showBrutalistSheet(
      context: context,
      title: l10n(context).chatBlockTitle,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n(
                sheetContext,
              ).chatBlockConfirmation(user.displayNameOrDefault),
              style: TextStyle(color: sheetContext.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: Text(
                l10n(sheetContext).chatConfirmBlock,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final result = await ref
                    .read(blockServiceProvider)
                    .block(user.id);
                if (!context.mounted) return;
                result.fold(
                  (failure) => AppSnackbar.handleFailure(context, failure),
                  (_) {
                    ref.invalidate(blockedUsersProvider);
                    ref.invalidate(profileFutureProvider(user.id));
                    AppSnackbar.success(context, l10n(context).chatUserBlocked);
                    if (context.canPop()) context.pop();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(BuildContext context, String userId) async {
    final strings = l10n(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(strings.profileReportUser),
        children: [
          for (final (value, label) in [
            ('SPAM', strings.profileReportSpam),
            ('FRAUD', strings.profileReportFraud),
            ('HARASSMENT', strings.profileReportHarassment),
            ('FAKE_ACCOUNT', strings.profileReportFakeAccount),
            ('IMPERSONATING', strings.profileReportImpersonation),
            ('NUDITY', strings.profileReportNudity),
            ('BLACKMAIL', strings.profileReportBlackmail),
            ('FALSE_ADVERTISING', strings.profileReportFalseAdvertising),
            ('OTHER', strings.profileReportOther),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Text(label),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;

    final result = await ProfileRepository().reportUser(userId, reason: reason);
    if (!context.mounted) return;
    result.fold(
      (failure) => AppSnackbar.handleFailure(context, failure),
      (_) => AppSnackbar.success(context, strings.profileReportSubmitted),
    );
  }

  Widget _buildFollowPrompt(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n(context).profileLoginToFollow,
          style: TextStyle(color: context.textSecondary),
        ),
        Spacing.vMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => context.push(loginPathFrom(context)),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryContainer),
                ),
                child: Center(
                  child: Text(
                    l10n(context).authLogin,
                    style: const TextStyle(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: l10n(context).authSignUp,
              onPressed: () => context.push(AppRoutes.register),
            ),
          ],
        ),
      ],
    );
  }
}
