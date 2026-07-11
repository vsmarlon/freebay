import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/phone_verification_sheet.dart';
import 'package:freebay/core/components/app_snackbar.dart';

final biometryServiceProvider = Provider<BiometryService>((ref) {
  return BiometryService();
});

final biometryAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometryServiceProvider).isAvailable();
});

final biometryEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometryServiceProvider).isEnabled();
});

void showProfileSettingsSheet(BuildContext context) {
  showBrutalistSheet(
    context: context,
    title: 'Configurações',
    builder: (sheetContext) {
      return Consumer(
        builder: (consumerContext, consumerRef, _) {
          final currentThemeMode = consumerRef.watch(themeModeProvider);
          final user = consumerRef.watch(authControllerProvider).valueOrNull;
          final isAvailable =
              consumerRef.watch(biometryAvailableProvider).valueOrNull ?? false;
          final isEnabled =
              consumerRef.watch(biometryEnabledProvider).valueOrNull ?? false;

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
                  style: const TextStyle(color: AppColors.mediumGray),
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
              ListTile(
                leading: Icon(
                  Icons.fingerprint,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Biometria',
                  style: TextStyle(color: consumerContext.textPrimary),
                ),
                subtitle: Text(
                  isAvailable
                      ? 'Usar biometria para login'
                      : 'Não disponível no dispositivo',
                  style: const TextStyle(color: AppColors.mediumGray),
                ),
                trailing: isAvailable
                    ? _BrutalistSwitch(
                        value: isEnabled,
                        onChanged: (value) async {
                          if (value) {
                            final authenticated = await consumerRef
                                .read(biometryServiceProvider)
                                .authenticate();
                            if (!authenticated) {
                              return;
                            }
                          }
                          await consumerRef
                              .read(biometryServiceProvider)
                              .setEnabled(value);
                          consumerRef.invalidate(biometryEnabledProvider);
                        },
                      )
                    : const SizedBox.shrink(),
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
                  context.push('/profile/edit');
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
                  style: const TextStyle(
                    color: AppColors.mediumGray,
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
                  if (user?.isVerified ?? false) {
                    AppSnackbar.success(
                      context,
                      'Seu perfil já está verificado!',
                    );
                  } else {
                    showPhoneVerificationSheet(context);
                  }
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
                  showBrutalistSheet(
                    context: context,
                    title: 'Ajuda e suporte',
                    builder: (sheetContext) {
                      return Consumer(
                        builder: (consumerContext, consumerRef, _) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Em caso de dúvidas ou problemas, acesse o centro de ajuda:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                                Spacing.vLg,
                                SizedBox(
                                  width: double.infinity,
                                  child: AppButton(
                                    label: 'Central de ajuda',
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      context.push('/faq');
                                    },
                                  ),
                                ),
                                Spacing.vSm,
                                InkWell(
                                  onTap: () => Navigator.pop(sheetContext),
                                  child: Container(
                                    width: double.infinity,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.onSurface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Fechar',
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
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

class _BrutalistSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BrutalistSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = isDark ? AppColors.white : AppColors.onSurface;
    final activeColor = AppColors.primaryContainer;
    final trackColor = value
        ? activeColor
        : (isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLow);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          color: trackColor,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              left: value ? 24 : 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? AppColors.onPrimary : borderColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
