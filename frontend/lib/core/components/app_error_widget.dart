import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'empty_state.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:freebay/shared/l10n/app_locale_resolution.dart';
import 'package:freebay/shared/services/error_reporter.dart';

enum AppErrorAction { retry, back, home }

class AppErrorWidget extends StatefulWidget {
  const AppErrorWidget({
    super.key,
    required this.details,
    this.onRecover,
    this.action = AppErrorAction.retry,
  });

  final FlutterErrorDetails details;
  final Future<void> Function()? onRecover;
  final AppErrorAction action;

  @override
  State<AppErrorWidget> createState() => _AppErrorWidgetState();
}

class _AppErrorWidgetState extends State<AppErrorWidget> {
  bool _recovering = false;

  static AppLocalizations _localizations(BuildContext context) =>
      maybeL10n(context) ??
      lookupAppLocalizations(
        resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales),
      );

  Future<void> _recover() async {
    if (_recovering || widget.onRecover == null) return;
    setState(() => _recovering = true);
    try {
      await widget.onRecover!();
    } catch (error, stack) {
      ErrorReporter.report('error-recovery', error, stack);
      if (mounted) setState(() => _recovering = false);
      return;
    }
    if (mounted) setState(() => _recovering = false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _localizations(context);
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Material(
        color: context.bgColor,
        child: Center(
          child: SingleChildScrollView(
            child: EmptyState(
              icon: Icons.error_outline,
              title: localizations.commonError.toUpperCase(),
              subtitle: kDebugMode
                  ? widget.details.exception.toString()
                  : localizations.errorScreenLoad,
              action: widget.onRecover == null
                  ? null
                  : AppButton(
                      label: switch (widget.action) {
                        AppErrorAction.retry =>
                          localizations.commonRetry.toUpperCase(),
                        AppErrorAction.back =>
                          localizations.commonBack.toUpperCase(),
                        AppErrorAction.home =>
                          localizations.navHome.toUpperCase(),
                      },
                      onPressed: _recovering ? null : _recover,
                      isLoading: _recovering,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
