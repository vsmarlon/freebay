import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class MenuListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;

  const MenuListTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? AppColors.error : context.textPrimary;

    final iconColor = isDestructive ? AppColors.error : context.textPrimary;

    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        dense: true,
        minLeadingWidth: 32,
        horizontalTitleGap: 12,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing:
            trailing ??
            Icon(Icons.chevron_right, color: AppColors.mediumGray, size: 20),
        onTap: onTap,
      ),
    );
  }
}
