import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';
import 'app_button.dart';
import 'brutalist_box.dart';
import 'brutalist_background.dart';
import 'spacing.dart';

class GuestGateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> benefits;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;

  const GuestGateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.benefits = const [
      '0% de taxa sobre compras e vendas',
      'Custódia segura até a entrega garantida',
      'Chat em tempo real com compradores e vendedores',
    ],
    this.onLoginPressed,
    this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return BrutalistBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: BrutalistBox(
              backgroundColor: isDark
                  ? AppColors.surfaceDark.withAlpha(230)
                  : AppColors.white.withAlpha(240),
              borderColor: context.borderColor,
              borderWidth: 2.0,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glowing icon badge
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withAlpha(30),
                        border: Border.all(
                          color: AppColors.primaryContainer,
                          width: 2.0,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.primaryContainer,
                        size: 36,
                      ),
                    ),
                  ),
                  Spacing.vLg,

                  // Restrict tag
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerDark
                            : AppColors.surfaceContainerHigh,
                        border: Border.all(
                          color: context.borderColor.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'MODO CONVIDADO',
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Spacing.vSm,

                  // Title
                  Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                      color: context.textPrimary,
                    ),
                  ),
                  Spacing.vSm,

                  // Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  Spacing.vLg,

                  // Benefits list
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceContainerDark.withAlpha(120)
                          : AppColors.surfaceContainerLow,
                      border: Border.all(
                        color: context.borderColor.withAlpha(40),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: benefits
                          .map(
                            (benefit) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Spacing.vXl,

                  // Actions
                  AppButton(
                    label: 'ENTRAR NA CONTA',
                    size: AppButtonSize.large,
                    onPressed: onLoginPressed ??
                        () => Navigator.of(context).pushNamed('/login'),
                  ),
                  Spacing.vSm,
                  AppButton(
                    label: 'CRIAR CONTA GRATUITA',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.standard,
                    onPressed: onRegisterPressed ??
                        () => Navigator.of(context).pushNamed('/register'),
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
