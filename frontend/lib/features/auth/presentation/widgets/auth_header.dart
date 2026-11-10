import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Shared auth top bar with a fixed-height, single-line title.
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
      semanticLabel: backTooltip ?? l10n(context).accessibilityBack,
      onTap: onBack,
    );

    return SizedBox(
      height: 72,
      child: Container(
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
              Align(alignment: Alignment.centerLeft, child: backButton),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
              child: Center(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.h2
                      .weight(900)
                      .copyWith(
                        color: context.textPrimary,
                        shadows: const [
                          Shadow(
                            color: AppColors.primaryContainer,
                            offset: AppDepth.shadowOffsetSmall,
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
