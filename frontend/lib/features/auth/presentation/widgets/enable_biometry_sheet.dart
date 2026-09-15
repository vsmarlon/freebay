import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';

/// Shows a bottom sheet offering biometric login opt-in after a
/// successful password login. Returns `true` if the user accepted,
/// `false` if dismissed.
Future<bool> showEnableBiometrySheet(BuildContext context) async {
  final service = ProviderScope.containerOf(
    context,
  ).read(biometryServiceProvider);
  if (!await service.isAvailable() ||
      await service.isEnabled() ||
      await service.hasPrompted()) {
    return false;
  }
  if (!context.mounted) return false;

  bool? result;
  try {
    result = await showBrutalistSheet<bool>(
      context: context,
      title: 'Login biométrico',
      builder: (sheetContext) {
        return Consumer(
          builder: (consumerContext, consumerRef, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Biometric icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withAlpha(26),
                      border: Border.all(
                        color: AppColors.primaryContainer,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 32,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ),
                Spacing.vLg,
                Text(
                  'Deseja usar biometria para entrar?',
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: consumerContext.textPrimary,
                  ),
                ),
                Spacing.vSm,
                Text(
                  'Use sua impressão digital ou Face ID para entrar '
                  'rapidamente, sem digitar sua senha.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
                Spacing.vXl,
                AppButton(
                  label: 'Ativar biometria',
                  icon: Icons.fingerprint,
                  onPressed: () async {
                    final biometryService = consumerRef.read(
                      biometryServiceProvider,
                    );
                    var enrolled = false;
                    try {
                      final authenticated = await biometryService.authenticate(
                        reason: 'Confirme para ativar login biométrico',
                      );
                      if (!authenticated) return;

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
                        return;
                      }

                      final token = enrollment.rightOrNull;
                      if (token == null) return;
                      final user = consumerRef
                          .read(authControllerProvider)
                          .value;
                      if (user == null) return;
                      await StorageService.saveBiometricToken(token);
                      await StorageService.saveBiometricOwner(user.id);
                      await biometryService.setEnabled(true);
                      consumerRef.invalidate(biometryEnabledProvider);
                      enrolled = true;
                    } finally {
                      if (!enrolled) {
                        try {
                          await biometryService.clearCredentials();
                        } catch (_) {}
                      }
                      if (consumerContext.mounted) {
                        Navigator.pop(consumerContext, enrolled);
                      }
                    }
                  },
                ),
                Spacing.vSm,
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Agora não',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.pop(consumerContext, false),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  } catch (_) {
    result = false;
  }

  if (result == true) {
    await service.setHasPrompted(true);
    await StorageService.saveRememberMe(true);
    return true;
  }

  if (!context.mounted) return false;
  await service.setHasPrompted(true);
  return false;
}
