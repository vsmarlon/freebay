import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class BrutalistConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  const BrutalistConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            Spacing.vMd,
            Text(
              message,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
            Spacing.vLg,
            AppButton(
              label: confirmLabel,
              variant: isDanger
                  ? AppButtonVariant.danger
                  : AppButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Center(
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
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
