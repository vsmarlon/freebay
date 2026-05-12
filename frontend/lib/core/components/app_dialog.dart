import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class AppDialog extends StatelessWidget {
  final String? logoAsset;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? dismissText;
  final String? okText;
  final VoidCallback? onDismiss;
  final VoidCallback? onOk;
  final bool isError;
  final bool isSuccess;
  final bool showCloseButton;
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
    VoidCallback? onDismiss,
    VoidCallback? onOk,
    bool isError = false,
    bool isSuccess = false,
    bool showCloseButton = false,
    List<Widget>? customActions,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppDialog(
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
          customActions: customActions,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.linear,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static Future<T?> showError<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    String okText = 'Entendi',
    VoidCallback? onOk,
  }) {
    return show<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      okText: okText,
      onOk: onOk,
      isError: true,
      icon: Icons.error_outline,
      iconColor: AppColors.error,
    );
  }

  static Future<T?> showSuccess<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    String okText = 'OK',
    VoidCallback? onOk,
  }) {
    return show<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      okText: okText,
      onOk: onOk,
      isSuccess: true,
      icon: Icons.check_circle_outline,
      iconColor: AppColors.success,
    );
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBorder(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showCloseButton) _buildCloseButton(context),
                      if (icon != null) ...[
                        _buildIcon(isDark),
                        const SizedBox(height: 16),
                      ],
                      _buildTitle(isDark),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        _buildSubtitle(isDark),
                      ],
                      const SizedBox(height: 24),
                      _buildActions(context, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBorder() {
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

  Widget _buildIcon(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: (iconColor ?? AppColors.primaryContainer).withAlpha(25),
        border: Border.all(
          color: iconColor ?? AppColors.primaryContainer,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 32,
        color: iconColor ?? AppColors.primaryContainer,
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return Text(
      subtitle!,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.outline,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    if (customActions != null) {
      return Row(
        children: customActions!,
      );
    }

    final hasDismiss = dismissText != null;
    final hasOk = okText != null;

    if (!hasDismiss && !hasOk) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasDismiss) ...[
          Expanded(
            child: _buildButton(
              context: context,
              text: dismissText!,
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              isPrimary: false,
            ),
          ),
          if (hasOk) const SizedBox(width: 12),
        ],
        if (hasOk)
          Expanded(
            child: _buildButton(
              context: context,
              text: okText!,
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              isPrimary: true,
              isError: isError,
              isSuccess: isSuccess,
            ),
          ),
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    bool isError = false,
    bool isSuccess = false,
  }) {
    final isDark = context.isDark;
    Color backgroundColor;
    Color textColor;

    if (isPrimary) {
      if (isError) {
        backgroundColor = AppColors.error;
        textColor = AppColors.onPrimary;
      } else if (isSuccess) {
        backgroundColor = AppColors.success;
        textColor = AppColors.onPrimary;
      } else {
        backgroundColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimary;
      }
    } else {
      backgroundColor =
          isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer;
      textColor = isDark ? AppColors.inverseOnSurface : AppColors.onSurface;
    }

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
            width: 2,
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
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

  Widget _buildCloseButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
          onDismiss?.call();
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline, width: 1),
          ),
          child: Icon(
            Icons.close,
            size: 18,
            color: AppColors.outline,
          ),
        ),
      ),
    );
  }
}
