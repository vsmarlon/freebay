import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class AppDialogActions extends StatelessWidget {
  final String? dismissText;
  final String? okText;
  final FutureOr<void> Function()? onDismiss;
  final FutureOr<void> Function()? onOk;
  final bool isError;
  final bool isSuccess;

  const AppDialogActions({
    super.key,
    this.dismissText,
    this.okText,
    this.onDismiss,
    this.onOk,
    this.isError = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDismiss = dismissText != null;
    final hasOk = okText != null;
    if (!hasDismiss && !hasOk) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasDismiss) ...[
          _DialogButton(
            text: dismissText!,
            onPressed: onDismiss,
            isPrimary: false,
          ),
          if (hasOk) const SizedBox(height: 12),
        ],
        if (hasOk)
          _DialogButton(
            text: okText!,
            onPressed: onOk,
            isPrimary: true,
            isError: isError,
            isSuccess: isSuccess,
          ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String text;
  final FutureOr<void> Function()? onPressed;
  final bool isPrimary;
  final bool isError;
  final bool isSuccess;

  const _DialogButton({
    required this.text,
    required this.onPressed,
    required this.isPrimary,
    this.isError = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final Color backgroundColor;
    final Color textColor;
    if (isPrimary) {
      backgroundColor = isError
          ? AppColors.error
          : isSuccess
          ? AppColors.success
          : AppColors.primaryContainer;
      textColor = AppColors.onPrimary;
    } else {
      backgroundColor = isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainer;
      textColor = context.textPrimary;
    }

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await onPressed?.call();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isPrimary ? Colors.transparent : AppColors.outline,
            width: 2,
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
