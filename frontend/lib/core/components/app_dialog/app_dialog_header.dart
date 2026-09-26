import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class AppDialogHeader extends StatelessWidget {
  final String? logoAsset;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const AppDialogHeader({
    super.key,
    this.logoAsset,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.showCloseButton = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCloseButton) _buildCloseButton(),
        if (icon != null) ...[_buildIcon(), Spacing.vMd],
        Text(
          title.toUpperCase(),
          style: AppTypography.h3
              .weight(800)
              .copyWith(letterSpacing: 0.5, color: context.textPrimary),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          Spacing.vSm,
          Text(
            subtitle!,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildIcon() {
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

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
          ),
          child: const Icon(Icons.close, size: 18, color: AppColors.outline),
        ),
      ),
    );
  }
}
