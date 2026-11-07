import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Confirmação de descarte do editor de mídia.
Future<bool?> showDiscardEditorDialog(
  BuildContext context, {
  VoidCallback? onDiscard,
}) async {
  final strings = l10n(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      backgroundColor: context.surfaceColor,
      title: Text(
        strings.chatEditorDiscardChangesTitle,
        style: AppTypography.h3,
      ),
      content: Text(
        strings.chatEditorDiscardChangesBody,
        style: AppTypography.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            strings.commonCancel.toUpperCase(),
            style: AppTypography.button,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onDiscard?.call();
          },
          child: Text(
            strings.chatEditorDiscard.toUpperCase(),
            style: AppTypography.button.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  return result;
}
