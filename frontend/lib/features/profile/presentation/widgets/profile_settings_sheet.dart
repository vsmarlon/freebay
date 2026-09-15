import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/providers/background_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/features/profile/presentation/widgets/phone_verification_sheet.dart';

void showProfileSettingsSheet(BuildContext context) {
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final router = GoRouter.of(context);
  var biometricBusy = false;
  var logoutBusy = false;
  showBrutalistSheet(
    context: context,
    title: 'Configurações',
    builder: (sheetContext) {
      return Consumer(
        builder: (consumerContext, consumerRef, _) {
          final currentThemeMode = consumerRef.watch(themeModeProvider);
          final user = consumerRef.watch(authControllerProvider).value;
          final isAvailable =
              consumerRef.watch(biometryAvailableProvider).value ?? false;
          final isEnabled =
              consumerRef.watch(biometryEnabledProvider).value ?? false;
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
                  style: TextStyle(color: consumerContext.textSecondary),
                ),
                trailing: isAvailable
                    ? _BrutalistSwitch(
                        value: isEnabled,
                        onChanged: (value) async {
                          if (biometricBusy) return;
                          biometricBusy = true;
                          final biometryService = consumerRef.read(
                            biometryServiceProvider,
                          );

                          if (value) {
                            // ── ENABLING ──
                            // Enroll direto: prompt biométrico + POST
                            // /auth/biometric-token/enroll com o JWT da sessão.
                            final authenticated = await biometryService
                                .authenticate(
                                  reason:
                                      'Confirme para ativar login biométrico',
                                );
                            if (!authenticated) {
                              biometricBusy = false;
                              return;
                            }

                            try {
                              final enrollment = await consumerRef
                                  .read(authRepositoryProvider)
                                  .enrollBiometricToken();
                              if (enrollment.isLeft) {
                                if (consumerContext.mounted) {
                                  AppSnackbar.error(
                                    consumerContext,
                                    'Não foi possível ativar a biometria.',
                                  );
                                }
                                biometricBusy = false;
                                return;
                              }
                              final token = enrollment.rightOrNull;
                              if (token == null || token.isEmpty) {
                                if (consumerContext.mounted) {
                                  AppSnackbar.error(
                                    consumerContext,
                                    'Não foi possível ativar a biometria.',
                                  );
                                }
                                biometricBusy = false;
                                return;
                              }
                              if (user == null) {
                                biometricBusy = false;
                                return;
                              }
                              await StorageService.saveBiometricToken(token);
                              await StorageService.saveBiometricOwner(user.id);
                              await biometryService.setEnabled(true);
                              await biometryService.setHasPrompted(true);
                              await StorageService.saveRememberMe(true);
                              consumerRef.invalidate(biometryEnabledProvider);
                              biometricBusy = false;
                            } catch (_) {
                              try {
                                await biometryService.clearCredentials();
                              } catch (_) {}
                              if (consumerContext.mounted) {
                                AppSnackbar.error(
                                  consumerContext,
                                  'Não foi possível ativar a biometria.',
                                );
                              }
                              biometricBusy = false;
                            }
                          } else {
                            // ── DISABLING ──
                            try {
                              final result = await consumerRef
                                  .read(authRepositoryProvider)
                                  .revokeBiometricToken();
                              if (result.isLeft) {
                                if (consumerContext.mounted) {
                                  AppSnackbar.error(
                                    consumerContext,
                                    'Não foi possível desativar a biometria.',
                                  );
                                }
                                biometricBusy = false;
                                return;
                              }
                              await biometryService.clearState();
                              consumerRef.invalidate(biometryEnabledProvider);
                              biometricBusy = false;
                            } catch (_) {
                              if (consumerContext.mounted) {
                                AppSnackbar.error(
                                  consumerContext,
                                  'Não foi possível desativar a biometria.',
                                );
                              }
                              biometricBusy = false;
                            }
                          }
                        },
                      )
                    : const SizedBox.shrink(),
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
                trailing: _BrutalistSwitch(
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
                    showBrutalistSheet(
                      context: rootNavigator.context,
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
                                  Text(
                                    'Em caso de dúvidas ou problemas, acesse o centro de ajuda:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: consumerContext.textSecondary,
                                    ),
                                  ),
                                  Spacing.vLg,
                                  SizedBox(
                                    width: double.infinity,
                                    child: AppButton(
                                      label: 'Central de ajuda',
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (rootNavigator.mounted) {
                                                router.push(AppRoutes.faq);
                                              }
                                            });
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

class _BrutalistSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BrutalistSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = context.textPrimary;
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
              duration: AppMotion.base,
              curve: AppMotion.enterCurve,
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
