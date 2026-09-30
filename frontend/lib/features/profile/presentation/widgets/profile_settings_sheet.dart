import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/providers/background_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/biometry_setting_tile.dart';
import 'package:freebay/features/profile/presentation/widgets/phone_verification_sheet.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_help_sheet.dart';

void showProfileSettingsSheet(BuildContext context) {
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final router = GoRouter.of(context);
  var logoutBusy = false;
  showBrutalistSheet(
    context: context,
    title: 'Configurações',
    builder: (sheetContext) {
      return Consumer(
        builder: (consumerContext, consumerRef, _) {
          final currentThemeMode = consumerRef.watch(themeModeProvider);
          final user = consumerRef.watch(authControllerProvider).value;
          final backgroundAnimated = consumerRef.watch(
            backgroundAnimatedProvider,
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  currentThemeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : currentThemeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Tema',
                  style: TextStyle(color: consumerContext.textPrimary),
                ),
                subtitle: Text(
                  currentThemeMode == ThemeMode.dark
                      ? 'Escuro'
                      : currentThemeMode == ThemeMode.light
                      ? 'Claro'
                      : 'Sistema',
                  style: TextStyle(color: consumerContext.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemeOption(
                      label: 'S',
                      isSelected: currentThemeMode == ThemeMode.system,
                      onTap: () => consumerRef
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.system),
                    ),
                    const SizedBox(width: 4),
                    _ThemeOption(
                      label: 'L',
                      isSelected: currentThemeMode == ThemeMode.light,
                      onTap: () => consumerRef
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.light),
                    ),
                    const SizedBox(width: 4),
                    _ThemeOption(
                      label: 'D',
                      isSelected: currentThemeMode == ThemeMode.dark,
                      onTap: () => consumerRef
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              BiometrySettingTile(userId: user?.id),
              ListTile(
                leading: const Icon(
                  Icons.group_outlined,
                  color: AppColors.success,
                ),
                title: Text(
                  'Amigos próximos',
                  style: AppTypography.bodyMedium.copyWith(
                    color: consumerContext.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Escolha quem vê seus stories privados',
                  style: AppTypography.bodySmall.copyWith(
                    color: consumerContext.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(consumerContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (rootNavigator.mounted) {
                      router.push(AppRoutes.profileCloseFriends);
                    }
                  });
                },
              ),
              ListTile(
                leading: Icon(
                  backgroundAnimated ? Icons.animation : Icons.block_outlined,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Fundo animado',
                  style: TextStyle(color: consumerContext.textPrimary),
                ),
                subtitle: Text(
                  'Desligue para usar fundo estático',
                  style: TextStyle(color: context.textSecondary),
                ),
                trailing: BrutalistSwitch(
                  value: backgroundAnimated,
                  onChanged: (value) async {
                    await consumerRef
                        .read(backgroundAnimatedProvider.notifier)
                        .setAnimated(value);
                  },
                ),
              ),
              Spacing.vMd,
              ListTile(
                leading: Icon(Icons.edit, color: consumerContext.textPrimary),
                title: Text(
                  'Editar perfil',
                  style: TextStyle(color: consumerContext.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(consumerContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (rootNavigator.mounted) {
                      router.push(AppRoutes.profileEdit);
                    }
                  });
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Verificação da conta',
                  style: TextStyle(color: consumerContext.textPrimary),
                ),
                subtitle: Text(
                  (user?.isVerified ?? false)
                      ? 'Conta verificada'
                      : 'Solicitar selo de verificação',
                  style: TextStyle(
                    color: consumerContext.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: (user?.isVerified ?? false)
                    ? const Icon(
                        Icons.verified,
                        color: AppColors.primaryContainer,
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(consumerContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!rootNavigator.mounted) return;
                    if (user?.isVerified ?? false) {
                      AppSnackbar.success(
                        rootNavigator.context,
                        'Seu perfil já está verificado!',
                      );
                    } else {
                      showPhoneVerificationSheet(rootNavigator.context);
                    }
                  });
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.help_outline,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Ajuda e suporte',
                  style: TextStyle(color: consumerContext.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(consumerContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!rootNavigator.mounted) return;
                    showProfileHelpSheet(
                      context: rootNavigator.context,
                      router: router,
                    );
                  });
                },
              ),
              Spacing.vSm,
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  if (logoutBusy) return;
                  logoutBusy = true;
                  Navigator.pop(consumerContext);
                  await consumerRef
                      .read(authControllerProvider.notifier)
                      .logout();
                  if (rootNavigator.mounted) {
                    router.go(AppRoutes.login);
                  }
                },
              ),
              Spacing.vMd,
            ],
          );
        },
      );
    },
  );
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
