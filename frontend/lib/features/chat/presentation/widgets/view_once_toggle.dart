import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

/// A toggle button for enabling/disabling view-once (ephemeral) messages.
///
/// When active, photos/messages sent will auto-delete after being viewed by the recipient.
class ViewOnceToggle extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const ViewOnceToggle({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled
          ? 'Foto única ativada (apaga após visualização)'
          : 'Visualização única (apaga após abrir)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primaryContainer.withAlpha(30)
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
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
    );
  }
}
