import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/providers/background_provider.dart';
import 'package:freebay/shared/providers/app_locale_preference_provider.dart';
import 'package:freebay/shared/providers/session_lock_preference_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/biometry_setting_tile.dart';
import 'package:freebay/features/profile/presentation/widgets/phone_verification_sheet.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_help_sheet.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

void showProfileSettingsSheet(BuildContext context) {
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final router = GoRouter.of(context);
  showBrutalistSheet(
    context: context,
    title: l10n(context).profileSettings,
    builder: (sheetContext) =>
        _SettingsSheetBody(rootNavigator: rootNavigator, router: router),
  );
}

class _SettingsSheetBody extends ConsumerStatefulWidget {
  final NavigatorState rootNavigator;
  final GoRouter router;

  const _SettingsSheetBody({required this.rootNavigator, required this.router});

  @override
  ConsumerState<_SettingsSheetBody> createState() => _SettingsSheetBodyState();
}

class _SettingsSheetBodyState extends ConsumerState<_SettingsSheetBody> {
  bool _logoutBusy = false;

  // Keep the sheet in the history so Back returns to it open.
  void _pushKeepingSettings(String route) => widget.router.push(route);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authControllerProvider).value;
    final backgroundAnimated = ref.watch(backgroundAnimatedProvider);
    final localePreference = ref.watch(appLocalePreferenceProvider);
    final sessionLockMinutes = ref.watch(sessionLockPreferenceProvider);
    final strings = l10n(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowLabel(strings.profileTheme),
        Spacing.vSm,
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(switch (themeMode) {
            ThemeMode.dark => Icons.dark_mode,
            ThemeMode.light => Icons.light_mode,
            ThemeMode.system => Icons.brightness_auto,
          }, color: context.textPrimary),
          title: Text(
            strings.profileTheme,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          subtitle: Text(
            switch (themeMode) {
              ThemeMode.dark => strings.profileThemeDark,
              ThemeMode.light => strings.profileThemeLight,
              ThemeMode.system => strings.profileThemeSystem,
            },
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                label: 'S',
                isSelected: themeMode == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setTheme(ThemeMode.system),
              ),
              Spacing.hXs,
              _ThemeOption(
                label: 'L',
                isSelected: themeMode == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setTheme(ThemeMode.light),
              ),
              Spacing.hXs,
              _ThemeOption(
                label: 'D',
                isSelected: themeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setTheme(ThemeMode.dark),
              ),
            ],
          ),
        ),
        Spacing.vMd,
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            backgroundAnimated ? Icons.animation : Icons.block_outlined,
            color: context.textPrimary,
          ),
          title: Text(
            strings.profileAnimatedBackground,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          subtitle: Text(
            strings.profileStaticBackgroundDescription,
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          trailing: BrutalistSwitch(
            value: backgroundAnimated,
            onChanged: (value) async {
              await ref
                  .read(backgroundAnimatedProvider.notifier)
                  .setAnimated(value);
            },
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.language, color: context.textPrimary),
          title: Text(
            strings.settingsLanguage,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          trailing: SizedBox(
            width: 152,
            child: DropdownButton<String>(
              value: localePreference,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(
                    strings.settingsLanguageSystem,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'pt_BR',
                  child: Text(
                    strings.settingsLanguagePortugueseBrazil,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(
                    strings.settingsLanguageEnglish,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(appLocalePreferenceProvider.notifier)
                      .setPreference(value);
                }
              },
            ),
          ),
        ),
        Spacing.vLg,
        EyebrowLabel(strings.faqAccountProfile),
        Spacing.vSm,
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.lock_clock, color: context.textPrimary),
          title: Text(
            strings.settingsSessionLockTitle,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          subtitle: Text(
            strings.settingsSessionLockDescription,
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          trailing: SizedBox(
            width: 152,
            child: DropdownButton<int>(
              value: sessionLockMinutes,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(
                    strings.settingsSessionLockOff,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(
                    strings.settingsSessionLockOneMinute,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text(
                    strings.settingsSessionLockFiveMinutes,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 15,
                  child: Text(
                    strings.settingsSessionLockFifteenMinutes,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text(
                    strings.settingsSessionLockThirtyMinutes,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(sessionLockPreferenceProvider.notifier)
                      .setMinutes(value);
                }
              },
            ),
          ),
        ),
        BiometrySettingTile(userId: user?.id),
        MenuListTile(
          icon: Icons.edit,
          label: strings.profileEdit,
          onTap: () => _pushKeepingSettings(AppRoutes.profileEdit),
        ),
        MenuListTile(
          icon: Icons.group_outlined,
          label: strings.closeFriendsTitle,
          onTap: () => _pushKeepingSettings(AppRoutes.profileCloseFriends),
        ),
        MenuListTile(
          icon: Icons.block_outlined,
          label: strings.profileBlockedUsersTitle,
          onTap: () => _pushKeepingSettings(AppRoutes.profileBlocked),
        ),
        MenuListTile(
          icon: Icons.bookmark_border,
          label: strings.profileSavedPostsTitle,
          onTap: () => _pushKeepingSettings(AppRoutes.profileSaved),
        ),
        MenuListTile(
          icon: Icons.favorite_border,
          label: strings.profileFavoritesTitle,
          onTap: () => _pushKeepingSettings(AppRoutes.profileFavorites),
        ),
        MenuListTile(
          icon: Icons.receipt_long_outlined,
          label: strings.profilePurchasesTitle,
          onTap: () => _pushKeepingSettings(AppRoutes.profilePurchases),
        ),
        MenuListTile(
          icon: Icons.privacy_tip_outlined,
          label: strings.privacyTitle,
          onTap: () => _pushKeepingSettings(AppRoutes.profilePrivacy),
        ),
        MenuListTile(
          icon: Icons.verified_user_outlined,
          label: strings.profileVerification,
          trailing: (user?.isVerified ?? false)
              ? const Icon(Icons.verified, color: AppColors.primaryContainer)
              : Icon(
                  Icons.chevron_right,
                  color: context.textSecondary,
                  size: 20,
                ),
          onTap: () {
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!widget.rootNavigator.mounted) return;
              final rootContext = widget.rootNavigator.context;
              if (user?.isVerified ?? false) {
                AppSnackbar.success(
                  rootContext,
                  l10n(rootContext).profileAlreadyVerified,
                );
              } else {
                showPhoneVerificationSheet(rootContext);
              }
            });
          },
        ),
        MenuListTile(
          icon: Icons.help_outline,
          label: strings.profileHelpSupport,
          onTap: () {
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!widget.rootNavigator.mounted) return;
              showProfileHelpSheet(
                context: widget.rootNavigator.context,
                router: widget.router,
              );
            });
          },
        ),
        Spacing.vLg,
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: !_logoutBusy,
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: Text(
            strings.authLogout,
            style: AppTypography.labelLarge.copyWith(color: AppColors.error),
          ),
          onTap: _logoutBusy ? null : _confirmLogout,
        ),
        Spacing.vMd,
      ],
    );
  }

  void _confirmLogout() {
    final navContext = widget.rootNavigator.context;
    AppDialog.show(
      context: navContext,
      icon: Icons.logout,
      iconColor: AppColors.error,
      title: l10n(navContext).feedLogOutTitle,
      subtitle: l10n(navContext).feedLogOutBody,
      dismissText: l10n(navContext).commonCancel,
      okText: l10n(navContext).authLogout,
      isError: true,
      onOk: () async {
        setState(() => _logoutBusy = true);
        try {
          await ref.read(authControllerProvider.notifier).logout();
          if (mounted) Navigator.pop(context);
          if (widget.rootNavigator.mounted) {
            widget.router.go(AppRoutes.login);
          }
        } catch (error) {
          if (!mounted) return;
          setState(() => _logoutBusy = false);
          AppSnackbar.handleFailure(context, error);
        }
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : context.borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.onPrimary : context.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
