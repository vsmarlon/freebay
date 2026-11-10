import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final String Function(BuildContext)? _localizedTitle;
  final String Function(BuildContext)? _localizedSubtitle;
  final VoidCallback? _onRetry;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  }) : _localizedTitle = null,
       _localizedSubtitle = null,
       _onRetry = null;

  const EmptyState._({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this._localizedTitle,
    this._localizedSubtitle,
    this._onRetry,
  });

  factory EmptyState.noPosts({Key? key, String? subtitle, Widget? action}) {
    return EmptyState._(
      key: key,
      icon: Icons.explore_outlined,
      title: '',
      subtitle: subtitle,
      localizedTitle: (context) => l10n(context).feedNoPosts,
      localizedSubtitle: subtitle == null
          ? (context) => l10n(context).feedNoPostsBody
          : null,
      action: action,
    );
  }

  factory EmptyState.noResults({Key? key, String? subtitle, Widget? action}) {
    return EmptyState._(
      key: key,
      icon: Icons.search_off,
      title: '',
      subtitle: subtitle,
      localizedTitle: (context) => l10n(context).commonNoResults.toUpperCase(),
      action: action,
    );
  }

  factory EmptyState.error({Key? key, String? message, VoidCallback? onRetry}) {
    return EmptyState._(
      key: key,
      icon: Icons.error_outline,
      title: '',
      subtitle: message,
      localizedTitle: (context) => l10n(context).commonError.toUpperCase(),
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _localizedTitle?.call(context) ?? this.title;
    final subtitle = _localizedSubtitle?.call(context) ?? this.subtitle;
    final action =
        this.action ??
        (_onRetry == null
            ? null
            : TextButton(
                onPressed: _onRetry,
                child: Text(
                  l10n(context).commonRetry.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.surfaceMidColor,
                border: Border.all(color: context.textSecondary, width: 2),
              ),
              child: Icon(icon, size: 40, color: context.textSecondary),
            ),
            Spacing.vLg,
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              Spacing.vSm,
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[Spacing.vLg, action],
          ],
        ),
      ),
    );
  }
}
