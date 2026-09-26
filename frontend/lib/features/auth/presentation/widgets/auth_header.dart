import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

/// Shared top bar for the login and register pages: centered massive
/// title with an optional back button.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.showBack = true,
    this.backTooltip,
  });

  final String title;
  final VoidCallback onBack;
  final bool showBack;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) {
    final backButton = BrutalistIconButton(
      icon: Icons.arrow_back,
      onTap: onBack,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withAlpha(40),
            width: 1.5,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: backTooltip,
                child: backTooltip == null
                    ? backButton
                    : Tooltip(message: backTooltip!, child: backButton),
              ),
            ),
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: context.textPrimary,
                shadows: [
                  const Shadow(
                    color: AppColors.primaryContainer,
                    offset: AppDepth.shadowOffsetSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
