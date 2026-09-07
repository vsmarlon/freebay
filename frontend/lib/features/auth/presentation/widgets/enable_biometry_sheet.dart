import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

/// Shows a bottom sheet offering biometric login opt-in after a
/// successful password login. Returns `true` if the user accepted,
/// `false` if dismissed.
Future<bool> showEnableBiometrySheet(BuildContext context) async {
  final result = await showBrutalistSheet<bool>(
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
              const Text(
                'Use sua impressão digital ou Face ID para entrar '
                'rapidamente, sem digitar sua senha.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  color: AppColors.mediumGray,
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

                  // Confirm identity with biometric prompt
                  final authenticated = await biometryService.authenticate(
                    reason: 'Confirme para ativar login biométrico',
                  );
                  if (!consumerContext.mounted) return;
                  if (!authenticated) {
                    Navigator.pop(consumerContext, false);
                    return;
                  }

                  // Store credentials for future biometric login
                  // (The biometricToken itself was already stored by AuthRepository during login)
                  await biometryService.setEnabled(true);
                  consumerRef.invalidate(biometryEnabledProvider);

                  if (consumerContext.mounted) {
                    Navigator.pop(consumerContext, true);
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
  return result ?? false;
}
