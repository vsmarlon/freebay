import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';

class PageHeader extends StatelessWidget {
  final String text;
  final String? exclamation;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final List<BreadcrumbItem>? breadcrumbs;

  const PageHeader({
    super.key,
    required this.text,
    this.exclamation,
    this.subtitle,
    this.leading,
    this.actions,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: context.appBarColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: text,
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                          color: context.textPrimary,
                        ),
                      ),
                      if (exclamation != null)
                        TextSpan(
                          text: exclamation,
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            const SizedBox(height: 8),
            BrutalistBreadcrumb(items: breadcrumbs!),
          ],
        ],
      ),
    );
  }
}
