import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/bug_report/presentation/widgets/bug_report_sheet.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_settings_sheet.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/social/presentation/widgets/feed_drawer_footer.dart';
import 'package:freebay/features/social/presentation/widgets/feed_drawer_sections.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class FeedDrawer extends ConsumerWidget {
  const FeedDrawer({super.key});

  void _afterDrawer(
    BuildContext drawerContext,
    void Function(BuildContext rootContext, GoRouter router) action,
  ) {
    final navigator = Navigator.of(drawerContext, rootNavigator: true);
    final router = GoRouter.of(drawerContext);
    final scaffold = Scaffold.maybeOf(drawerContext);
    if (scaffold?.isDrawerOpen ?? false) scaffold!.closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) action(navigator.context, router);
    });
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    AppDialog.show(
      context: navigator.context,
      icon: Icons.logout,
      iconColor: AppColors.error,
      title: l10n(navigator.context).feedLogOutTitle,
      subtitle: l10n(navigator.context).feedLogOutBody,
      dismissText: l10n(navigator.context).commonCancel,
      okText: l10n(navigator.context).authLogout,
      isError: true,
      onOk: () async {
        if (ref.read(authControllerProvider).isLoading) return;
        Scaffold.maybeOf(context)?.closeDrawer();
        await ref.read(authControllerProvider.notifier).logout();
        if (navigator.mounted) router.go(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final user = ref.watch(authControllerProvider).value;
    final stats = ref.watch(profileStatsProvider).value;
    void action(String route) {
      _afterDrawer(context, (_, router) {
        if (route == AppRoutes.wallet) {
          router.go(route);
        } else {
          router.push(route);
        }
      });
    }

    return RepaintBoundary(
      child: Drawer(
        elevation: 0,
        width: MediaQuery.sizeOf(context).width * 0.78,
        backgroundColor: Colors.transparent,
        child: AppBackground(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.primaryContainer.withAlpha(120),
                  width: 2,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        RepaintBoundary(
                          child: FeedDrawerHeader(
                            name:
                                user?.displayName ?? strings.commonUnknownUser,
                            avatarUrl: user?.avatarUrl,
                            isVerified: user?.isVerified ?? false,
                            onTap: () => _afterDrawer(
                              context,
                              (_, router) => router.go(AppRoutes.profile),
                            ),
                          ),
                        ),
                        RepaintBoundary(
                          child: FeedDrawerStats(
                            followers:
                                stats?.followersCount ??
                                user?.followersCount ??
                                0,
                            following:
                                stats?.followingCount ??
                                user?.followingCount ??
                                0,
                            sales: stats?.salesCount ?? user?.salesCount ?? 0,
                            reputation: user?.reputationScore ?? 0,
                            onFollowers: () =>
                                action(AppRoutes.followersWith(user?.id ?? '')),
                            onFollowing: () =>
                                action(AppRoutes.followingWith(user?.id ?? '')),
                          ),
                        ),
                        if (user?.bio?.isNotEmpty ?? false)
                          FeedDrawerBio(bio: user!.bio!),
                        _menu(context, action),
                      ],
                    ),
                  ),
                  RepaintBoundary(
                    child: FeedDrawerFooter(
                      isDark: ref.watch(isDarkModeProvider),
                      onToggleTheme: () =>
                          ref.read(themeModeProvider.notifier).toggleTheme(),
                      onSettings: () => _afterDrawer(
                        context,
                        (root, _) => showProfileSettingsSheet(root),
                      ),
                      onLogout: () => _confirmLogout(context, ref),
                      onReportBug: () => _afterDrawer(
                        context,
                        (root, _) => showBugReportSheet(root),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, void Function(String route) action) {
    final strings = l10n(context);
    final entries = [
      (Icons.grid_view, strings.profilePosts, AppRoutes.profilePosts),
      (
        Icons.shopping_bag_outlined,
        strings.productMyListings,
        AppRoutes.profileProducts,
      ),
      (Icons.bookmark_outline, strings.profileSaved, AppRoutes.profileSaved),
      (Icons.shopping_cart_outlined, strings.cartTitle, AppRoutes.cart),
      (Icons.receipt_long_outlined, strings.ordersTitle, AppRoutes.orders),
      (
        Icons.account_balance_wallet_outlined,
        strings.walletTitle,
        AppRoutes.wallet,
      ),
      (
        Icons.notifications_outlined,
        strings.notificationsTitle,
        AppRoutes.notifications,
      ),
      (Icons.settings_outlined, strings.profileSettings, ''),
      (Icons.help_outline, strings.profileHelpSupport, AppRoutes.faq),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: entries
            .map(
              (entry) => MenuListTile(
                icon: entry.$1,
                label: entry.$2,
                onTap: entry.$3.isEmpty
                    ? () => _afterDrawer(
                        context,
                        (root, _) => showProfileSettingsSheet(root),
                      )
                    : () => action(entry.$3),
              ),
            )
            .toList(),
      ),
    );
  }
}
