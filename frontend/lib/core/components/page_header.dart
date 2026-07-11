import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/error_indicator.dart';
import 'package:freebay/core/providers/last_error_provider.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/features/bug_report/presentation/widgets/bug_report_sheet.dart';

class PageHeader extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final lastError = ref.watch(lastErrorProvider);
    final trailingActions = [
      ...?actions,
      if (lastError != null)
        ErrorIndicator(
          onTap: () {
            ref.read(lastErrorProvider.notifier).state = null;
            showBugReportSheet(
              context,
              prefillDescription: lastError.message,
              screenContext: lastError.route,
            );
          },
        ),
    ];
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
          bottom: BorderSide(color: context.borderColor, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (leading != null) ...[
                  SizedBox(width: 40, height: 40, child: leading!),
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
                Wrap(
                  spacing: 8,
                  runAlignment: WrapAlignment.center,
                  children: trailingActions,
                ),
              ],
            ),
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
