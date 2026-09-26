import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'app_dialog/app_dialog_body.dart';

class AppDialog extends StatelessWidget {
  final String? logoAsset;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? dismissText;
  final String? okText;
  final FutureOr<void> Function()? onDismiss;
  final FutureOr<void> Function()? onOk;
  final bool isError;
  final bool isSuccess;
  final bool showCloseButton;
  final bool preventBack;
  final List<Widget>? customActions;

  const AppDialog({
    super.key,
    this.logoAsset,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.dismissText,
    this.okText,
    this.onDismiss,
    this.onOk,
    this.isError = false,
    this.isSuccess = false,
    this.showCloseButton = false,
    this.preventBack = false,
    this.customActions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? logoAsset,
    IconData? icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    String? dismissText,
    String? okText,
    FutureOr<void> Function()? onDismiss,
    FutureOr<void> Function()? onOk,
    bool isError = false,
    bool isSuccess = false,
    bool showCloseButton = false,
    List<Widget>? customActions,
    bool barrierDismissible = true,
    bool preventBack = false,
  }) {
    final List<Widget> actions = customActions ?? [];

    if (customActions == null) {
      if (dismissText != null) {
        actions.add(
          BrutalistDialogAction(
            text: dismissText.toUpperCase(),
            onPressed: () {
              onDismiss?.call();
              Navigator.of(context).pop();
            },
          ),
        );
      }

      if (okText != null || dismissText == null) {
        actions.add(
          BrutalistDialogAction(
            text: (okText ?? 'OK').toUpperCase(),
            isDefaultAction: true,
            isDestructiveAction: isError,
            onPressed: () {
              onOk?.call();
              Navigator.of(context).pop();
            },
          ),
        );
      }
    }

    return showBrutalistCupertinoDialog<T>(
      context: context,
      title: title.toUpperCase(),
      content: subtitle,
      actions: actions,
      preventBack: preventBack,
    );
  }

  static Future<T?> showError<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    String okText = 'Entendi',
    FutureOr<void> Function()? onOk,
    String? dismissText,
    FutureOr<void> Function()? onDismiss,
    bool barrierDismissible = true,
    bool preventBack = false,
  }) => show<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    okText: okText,
    onOk: onOk,
    dismissText: dismissText,
    onDismiss: onDismiss,
    barrierDismissible: barrierDismissible,
    preventBack: preventBack,
    isError: true,
    icon: Icons.error_outline,
    iconColor: AppColors.error,
  );

  static Future<T?> showSuccess<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    String okText = 'OK',
    VoidCallback? onOk,
  }) => show<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    okText: okText,
    onOk: onOk,
    isSuccess: true,
    icon: Icons.check_circle_outline,
    iconColor: AppColors.success,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !preventBack,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border.all(color: AppColors.onSurface, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DialogTopBorder(isError: isError, isSuccess: isSuccess),
                  AppDialogBody(
                    logoAsset: logoAsset,
                    icon: icon,
                    iconColor: iconColor,
                    title: title,
                    subtitle: subtitle,
                    dismissText: dismissText,
                    okText: okText,
                    onDismiss: onDismiss,
                    onOk: onOk,
                    isError: isError,
                    isSuccess: isSuccess,
                    showCloseButton: showCloseButton,
                    onClose: () {
                      HapticFeedback.lightImpact();
                      onDismiss?.call();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    customActions: customActions,
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

class _DialogTopBorder extends StatelessWidget {
  final bool isError;
  final bool isSuccess;

  const _DialogTopBorder({required this.isError, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primaryContainer, AppColors.primary];
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isError
              ? [AppColors.error, AppColors.error.withAlpha(150)]
              : isSuccess
              ? [AppColors.success, AppColors.success.withAlpha(150)]
              : colors,
        ),
      ),
    );
  }
}
