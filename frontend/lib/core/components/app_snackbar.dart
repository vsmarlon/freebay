import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/providers/last_error_provider.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/shared/errors/error_messages.dart';

enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  static SnackBar _build({
    required String message,
    required AppSnackbarType type,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final color = switch (type) {
      AppSnackbarType.success => AppColors.success,
      AppSnackbarType.error => AppColors.error,
      AppSnackbarType.warning => AppColors.warning,
      AppSnackbarType.info => AppColors.primaryContainer,
    };

    final icon = switch (type) {
      AppSnackbarType.success => Icons.check_circle_outline,
      AppSnackbarType.error => Icons.error_outline,
      AppSnackbarType.warning => Icons.warning_amber_outlined,
      AppSnackbarType.info => Icons.info_outline,
    };

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
      action: action,
      backgroundColor: AppColors.darkGray,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.all(16),
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      _build(message: message, type: type, duration: duration),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.success);

  static void error(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.error);
    _recordError(context, message);
  }

  /// Renders the generic copy for [failure]. Never surfaces raw exception text:
  /// anything that is not a [Failure] falls back to [kGenericErrorMessage].
  static void handleFailure(BuildContext context, Object? failure) =>
      error(context, userMessageOf(failure));

  /// Optimistic destructive action: the UI removes the item immediately and
  /// [onCommit] only fires once the snackbar closes without UNDO being tapped.
  static void undoable(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    required VoidCallback onCommit,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger
        .showSnackBar(
          _build(
            message: message,
            type: AppSnackbarType.info,
            duration: duration,
            action: SnackBarAction(
              label: 'DESFAZER',
              textColor: AppColors.onPrimaryContainer,
              onPressed: onUndo,
            ),
          ),
        )
        .closed
        .then((reason) {
          if (reason != SnackBarClosedReason.action) onCommit();
        });
  }

  static void _recordError(BuildContext context, String message) {
    String? route;
    try {
      route = GoRouterState.of(context).uri.toString();
    } catch (_) {}
    try {
      ProviderScope.containerOf(context, listen: false)
          .read(lastErrorProvider.notifier)
          .setError(LastErrorInfo(message, route));
    } catch (_) {}
  }

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message);
}
