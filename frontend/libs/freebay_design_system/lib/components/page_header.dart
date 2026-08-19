import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';
import 'brutalist_breadcrumb.dart';

class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String text;
  final String? exclamation;
  final Widget? leading;
  final List<Widget>? actions;
  final List<Widget>? trailingActions;
  final String? subtitle;
  final List<BreadcrumbItem>? breadcrumbs;
  final bool showBottomBorder;

  const PageHeader({
    super.key,
    required this.text,
    this.exclamation,
    this.leading,
    this.actions,
    this.trailingActions,
    this.subtitle,
    this.breadcrumbs,
    this.showBottomBorder = true,
  });

  List<Widget>? get _effectiveActions => actions ?? trailingActions;

  @override
  Size get preferredSize => Size.fromHeight(
        subtitle != null || (breadcrumbs != null && breadcrumbs!.isNotEmpty)
            ? 76.0
            : 56.0,
      );

  @override
  Widget build(BuildContext context) {
    final actionsList = _effectiveActions;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: context.appBarColor,
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: context.borderColor.withAlpha(50),
                  width: 1.5,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: text.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: context.textPrimary,
                    ),
                    children: exclamation != null
                        ? [
                            TextSpan(
                              text: exclamation,
                              style: const TextStyle(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              ...?actionsList,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
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
