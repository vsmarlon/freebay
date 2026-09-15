import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';
import 'app_button.dart';
import 'brutalist_box.dart';
import '../tokens/spacing.dart';

class GuestGateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;

  const GuestGateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onLoginPressed,
    this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: BrutalistBox(
            borderColor: context.borderColor,
            borderWidth: 2.0,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                AppButton(
                  label: 'ENTRAR NA CONTA',
                  size: AppButtonSize.large,
                  onPressed:
                      onLoginPressed ??
                      () => Navigator.of(context).pushNamed('/login'),
                ),
                Spacing.vSm,
                AppButton(
                  label: 'CRIAR CONTA',
                  variant: AppButtonVariant.ghost,
                  onPressed:
                      onRegisterPressed ??
                      () => Navigator.of(context).pushNamed('/register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
