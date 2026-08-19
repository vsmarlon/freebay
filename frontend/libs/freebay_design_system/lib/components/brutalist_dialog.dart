import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';
import 'app_button.dart';
import 'spacing.dart';

class BrutalistDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final Widget? customBody;

  const BrutalistDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'CONFIRMAR',
    this.cancelLabel = 'CANCELAR',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.customBody,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'CONFIRMAR',
    String? cancelLabel = 'CANCELAR',
    bool isDestructive = false,
    Widget? customBody,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BrutalistDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        customBody: customBody,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isDestructive ? AppColors.error : context.borderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTypography.h3.copyWith(
                color: isDestructive ? AppColors.error : context.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Spacing.vMd,
            if (customBody != null)
              customBody!
            else
              Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.textPrimary,
                ),
              ),
            Spacing.vXl,
            Row(
              children: [
                if (cancelLabel != null) ...[
                  Expanded(
                    child: AppButton(
                      label: cancelLabel!,
                      variant: AppButtonVariant.ghost,
                      onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                    ),
                  ),
                  Spacing.hMd,
                ],
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: isDestructive
                        ? AppButtonVariant.danger
                        : AppButtonVariant.primary,
                    onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
