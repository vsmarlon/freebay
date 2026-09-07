import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class BrutalistBiometricModal extends StatelessWidget {
  const BrutalistBiometricModal({super.key});

  static Future<bool> show(BuildContext context, WidgetRef ref) async {
    final biometryService = ref.read(biometryServiceProvider);
    final isAvailable = await biometryService.isAvailable();
    final isEnabled = await biometryService.isEnabled();

    if (!isAvailable || isEnabled) return false;

    await biometryService.setHasPrompted(true);

    if (!context.mounted) return false;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'BiometricPrompt',
      barrierColor: AppColors.onSurface.withValues(alpha: 0.54),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const BrutalistBiometricModal();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AppMotion.baseCurve,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final backgroundColor = context.surfaceColor;
    final borderColor = AppColors.onSurface;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryContainer, AppColors.primary],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Consumer(
                    builder: (consumerContext, ref, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withAlpha(25),
                              border: Border.all(
                                color: AppColors.primaryContainer,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              size: 36,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          Spacing.vLg,
                          Text(
                            'ATIVAR BIOMETRIA?',
                            style: TextStyle(
                              fontFamily: AppTypography.headlineFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppColors.inverseOnSurface
                                  : AppColors.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Spacing.vSm,
                          Text(
                            'Use sua impressão digital ou Face ID para entrar com rapidez, facilidade e segurança nas próximas vezes.',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.inverseOnSurface.withAlpha(180)
                                  : AppColors.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Spacing.vXl,
                          Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  context: consumerContext,
                                  label: 'AGORA NÃO',
                                  isPrimary: false,
                                  onPressed: () {
                                    Navigator.of(consumerContext).pop(false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildButton(
                                  context: consumerContext,
                                  label: 'ATIVAR',
                                  isPrimary: true,
                                  icon: Icons.fingerprint,
                                  onPressed: () async {
                                    final biometryService = ref.read(
                                      biometryServiceProvider,
                                    );
                                    final authenticated = await biometryService
                                        .authenticate(
                                          reason:
                                              'Confirme para ativar login biométrico no FreeBay',
                                        );
                                    if (!consumerContext.mounted) return;
                                    if (authenticated) {
                                      await biometryService.setEnabled(true);
                                      ref.invalidate(biometryEnabledProvider);
                                      if (consumerContext.mounted) {
                                        Navigator.of(consumerContext).pop(true);
                                      }
                                    } else {
                                      if (consumerContext.mounted) {
                                        Navigator.of(
                                          consumerContext,
                                        ).pop(false);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    final isDark = context.isDark;
    final backgroundColor = isPrimary
        ? AppColors.primaryContainer
        : (isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainer);
    final textColor = isPrimary ? AppColors.onPrimary : (context.textPrimary);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isPrimary ? Colors.transparent : AppColors.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
