import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// A toggle button for enabling/disabling view-once (ephemeral) messages.
///
/// When active, photos/messages sent will auto-delete after being viewed by the recipient.
class ViewOnceToggle extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final String? semanticLabel;

  const ViewOnceToggle({
    super.key,
    required this.enabled,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel ?? l10n(context).chatViewOnce,
      child: Semantics(
        button: true,
        selected: enabled,
        label: semanticLabel ?? l10n(context).chatViewOnce,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primaryContainer.withAlpha(30)
                    : Colors.transparent,
                border: Border.all(
                  color: enabled
                      ? AppColors.primaryContainer
                      : context.borderColor,
                  width: enabled ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.looks_one_outlined,
                    color: enabled
                        ? AppColors.primaryContainer
                        : context.textSecondary,
                    size: 20,
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
