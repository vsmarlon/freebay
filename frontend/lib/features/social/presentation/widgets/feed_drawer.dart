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

class FeedDrawer extends ConsumerWidget {
  const FeedDrawer({super.key});

  void _afterDrawer(
    BuildContext drawerContext,
    void Function(BuildContext rootContext, GoRouter router) action,
  ) {
    final navigator = Navigator.of(drawerContext, rootNavigator: true);
    final router = GoRouter.of(drawerContext);
    final scaffold = Scaffold.maybeOf(drawerContext);
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
    }
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
      title: 'Sair da conta?',
      subtitle: 'Você precisará entrar novamente para acessar sua conta.',
      dismissText: 'Cancelar',
      okText: 'Sair',
      isError: true,
      onOk: () async {
        if (ref.read(authControllerProvider).isLoading) return;
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold?.isDrawerOpen ?? false) scaffold!.closeDrawer();
        await ref.read(authControllerProvider.notifier).logout();
        if (navigator.mounted) router.go(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final bio = user?.bio;
    final stats = ref.watch(profileStatsProvider).value;

    return RepaintBoundary(
      child: Drawer(
        elevation: 0,
        width: MediaQuery.of(context).size.width * 0.78,
        backgroundColor: Colors.transparent,
        child: AppBackground(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.primaryContainer.withAlpha(120),
                  width: 2.0,
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
                          child: _Header(
                            name: user?.displayName ?? 'Usuário',
                            avatarUrl: user?.avatarUrl,
                            isVerified: user?.isVerified ?? false,
                            onTap: () => _afterDrawer(
                              context,
                              (rootContext, router) =>
                                  router.go(AppRoutes.profile),
                            ),
                          ),
                        ),
                        RepaintBoundary(
                          child: _StatsStrip(
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
                            onFollowers: () {
                              _afterDrawer(
                                context,
                                (rootContext, router) => router.push(
                                  AppRoutes.followersWith(user?.id ?? ''),
                                ),
                              );
                            },
                            onFollowing: () {
                              _afterDrawer(
                                context,
                                (rootContext, router) => router.push(
                                  AppRoutes.followingWith(user?.id ?? ''),
                                ),
                              );
                            },
                          ),
                        ),
                        if (bio != null && bio.isNotEmpty) _BioBlock(bio: bio),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MenuListTile(
                                icon: Icons.grid_view,
                                label: 'Meus posts',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.profilePosts),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Meus anúncios',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.profileProducts),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.bookmark_outline,
                                label: 'Salvos',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.profileSaved),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.shopping_cart_outlined,
                                label: 'Carrinho',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.cart),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.receipt_long_outlined,
                                label: 'Meus pedidos',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.orders),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Carteira e custódia',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.wallet),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.notifications_outlined,
                                label: 'Notificações',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.notifications),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.settings_outlined,
                                label: 'Configurações',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      showProfileSettingsSheet(rootContext),
                                ),
                              ),
                              MenuListTile(
                                icon: Icons.help_outline,
                                label: 'Ajuda e suporte',
                                onTap: () => _afterDrawer(
                                  context,
                                  (rootContext, router) =>
                                      router.push(AppRoutes.faq),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  RepaintBoundary(
                    child: _Footer(
                      isDark: ref.watch(isDarkModeProvider),
                      onToggleTheme: () =>
                          ref.read(themeModeProvider.notifier).toggleTheme(),
                      onSettings: () => _afterDrawer(
                        context,
                        (rootContext, router) =>
                            showProfileSettingsSheet(rootContext),
                      ),
                      onLogout: () => _confirmLogout(context, ref),
                      onReportBug: () => _afterDrawer(
                        context,
                        (rootContext, router) =>
                            showBugReportSheet(rootContext),
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
}

class _Header extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final VoidCallback onTap;

  const _Header({
    required this.name,
    required this.avatarUrl,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceMidColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withAlpha(50),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: avatarUrl,
                isVerified: isVerified,
                size: AppAvatarSize.large,
              ),
              Spacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: context.textPrimary,
                      ),
                    ),
                    Spacing.vXs,
                    const Text(
                      'VER MEU PERFIL',
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final int followers;
  final int following;
  final int sales;
  final num reputation;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;

  const _StatsStrip({
    required this.followers,
    required this.following,
    required this.sales,
    required this.reputation,
    required this.onFollowers,
    required this.onFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surfaceMidColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatColumn(
                  label: 'Seguidores',
                  value: '$followers',
                  uppercaseLabel: true,
                  onTap: onFollowers,
                ),
              ),
              Expanded(
                child: StatColumn(
                  label: 'Seguindo',
                  value: '$following',
                  uppercaseLabel: true,
                  onTap: onFollowing,
                ),
              ),
            ],
          ),
          Spacing.vMd,
          Row(
            children: [
              Expanded(
                child: StatColumn(
                  label: 'Vendas',
                  value: '$sales',
                  uppercaseLabel: true,
                ),
              ),
              Expanded(
                child: StatColumn(
                  label: 'Reputação',
                  value: reputation.toStringAsFixed(1),
                  uppercaseLabel: true,
                  usePrimaryColor: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BioBlock extends StatelessWidget {
  final String bio;

  const _BioBlock({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BIO',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bio,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              color: context.textPrimary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback onReportBug;

  const _Footer({
    required this.isDark,
    required this.onToggleTheme,
    required this.onSettings,
    required this.onLogout,
    required this.onReportBug,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceMidColor,
        border: Border(
          top: BorderSide(color: context.borderColor.withAlpha(50), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.textPrimary,
            ),
            tooltip: isDark ? 'Modo claro' : 'Modo escuro',
            onPressed: onToggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.bug_report_outlined, color: context.textSecondary),
            tooltip: 'Reportar problema',
            onPressed: onReportBug,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textSecondary),
            tooltip: 'Configurações',
            onPressed: onSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Sair',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
