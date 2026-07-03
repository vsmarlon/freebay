import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_dialog.dart';
import 'package:freebay/core/components/brutalist_box.dart';
import 'package:freebay/core/components/menu_list_tile.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/stat_column.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/bug_report/presentation/widgets/bug_report_sheet.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_menu_list.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_settings_sheet.dart';

class FeedDrawer extends ConsumerWidget {
  const FeedDrawer({super.key});

  void _closeDrawer(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
    }
  }

  void _goProfile(BuildContext context) {
    _closeDrawer(context);
    context.go('/profile');
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    AppDialog.show(
      context: context,
      icon: Icons.logout,
      iconColor: AppColors.error,
      title: 'Sair da conta?',
      subtitle: 'Você precisará entrar novamente para acessar sua conta.',
      dismissText: 'Cancelar',
      okText: 'Sair',
      isError: true,
      onOk: () {
        _closeDrawer(context);
        ref.read(authControllerProvider.notifier).logout();
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final bio = user?.bio;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Header(
                    name: user?.displayName ?? 'Usuário',
                    avatarUrl: user?.avatarUrl,
                    isVerified: user?.isVerified ?? false,
                    onTap: () => _goProfile(context),
                  ),
                  _StatsStrip(
                    followers: user?.followersCount ?? 0,
                    following: user?.followingCount ?? 0,
                    sales: user?.salesCount ?? 0,
                    reputation: user?.reputationScore ?? 0,
                    onFollowers: () {
                      _closeDrawer(context);
                      context.push('/profile/followers');
                    },
                    onFollowing: () {
                      _closeDrawer(context);
                      context.push('/profile/following');
                    },
                  ),
                  if (bio != null && bio.isNotEmpty) _BioBlock(bio: bio),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ProfileMenuList(showLogout: false),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: BrutalistBox(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          MenuListTile(
                            icon: Icons.settings_outlined,
                            label: 'Configurações',
                            onTap: () {
                              _closeDrawer(context);
                              showProfileSettingsSheet(context);
                            },
                          ),
                          MenuListTile(
                            icon: Icons.help_outline,
                            label: 'Ajuda e suporte',
                            onTap: () {
                              _closeDrawer(context);
                              context.push('/faq');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Footer(
              isDark: ref.watch(isDarkModeProvider),
              onToggleTheme: () =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
              onSettings: () {
                _closeDrawer(context);
                showProfileSettingsSheet(context);
              },
              onLogout: () => _confirmLogout(context, ref),
              onReportBug: () {
                _closeDrawer(context);
                showBugReportSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable header → opens the user's profile. Big Space Grotesk name paired
/// with a small all-caps label (editorial pairing).
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    Spacing.vXs,
                    Text(
                      'VER MEU PERFIL',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

/// Tonal-blocked stats row. Followers/Following are tappable.
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BIO',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: context.textSecondary,
            ),
          ),
          Spacing.vSm,
          Text(
            bio,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned footer: dark-mode toggle on the left, settings + logout on the right.
/// Sits on a distinct surface tone (tonal blocking) — no divider line.
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
    return Material(
      color: context.surfaceMidColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _FooterAction(
              icon:
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              label: isDark ? 'ESCURO' : 'CLARO',
              onTap: onToggleTheme,
            ),
            const Spacer(),
            _FooterAction(
              icon: Icons.bug_report_outlined,
              onTap: onReportBug,
            ),
            Spacing.hSm,
            _FooterAction(
              icon: Icons.settings_outlined,
              onTap: onSettings,
            ),
            Spacing.hSm,
            _FooterAction(
              icon: Icons.logout,
              label: 'SAIR',
              color: AppColors.error,
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color? color;

  const _FooterAction({
    required this.icon,
    this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: tint, size: 20),
            if (label != null) ...[
              Spacing.hSm,
              Text(
                label!,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: tint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
