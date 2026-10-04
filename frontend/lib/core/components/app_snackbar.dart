import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/providers/last_error_provider.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  static SnackBar _build({
    required String message,
    required AppSnackbarType type,
    required Duration duration,
    SnackBarAction? action,
    VoidCallback? onVisible,
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
      onVisible: onVisible,
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
    SnackBarAction? action,
  }) {
    _showOnMessenger(
      ScaffoldMessenger.of(context),
      message: message,
      type: type,
      duration: duration,
      action: action,
    );
  }

  static void _showOnMessenger(
    ScaffoldMessengerState messenger, {
    required String message,
    required AppSnackbarType type,
    required Duration duration,
    SnackBarAction? action,
  }) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      _build(message: message, type: type, duration: duration, action: action),
    );
  }

  /// Use after a page has been popped; the root messenger may still be active.
  static void errorOnMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    if (!messenger.mounted) return;
    _showOnMessenger(
      messenger,
      message: message,
      type: AppSnackbarType.error,
      duration: const Duration(seconds: 3),
    );
    _recordError(messenger.context, message);
  }

  static void infoOnMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    if (!messenger.mounted) return;
    _showOnMessenger(
      messenger,
      message: message,
      type: AppSnackbarType.info,
      duration: const Duration(seconds: 3),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.success);

  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.error,
      action: action,
    );
    _recordError(context, message);
  }

  /// Renders localized copy without exposing arbitrary server error text.
  static void handleFailure(BuildContext context, Object? failure) =>
      error(context, localizedFailureMessage(context, failure));

  /// Keep the delete pending until the undo window expires. A snackbar with an
  /// action may stay visible indefinitely with accessibility navigation enabled.
  static void undoable(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    required VoidCallback onCommit,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    Timer? timer;
    var resolved = false;
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    controller = messenger.showSnackBar(
      _build(
        message: message,
        type: AppSnackbarType.info,
        duration: duration,
        onVisible: () {
          timer = Timer(duration, () {
            if (resolved) return;
            resolved = true;
            onCommit();
            controller.close();
          });
        },
        action: SnackBarAction(
          label: l10n(context).commonUndo,
          textColor: AppColors.onPrimaryContainer,
          onPressed: () {
            if (resolved) return;
            resolved = true;
            timer?.cancel();
            onUndo();
          },
        ),
      ),
    );
    controller.closed.then((_) {
      timer?.cancel();
      if (!resolved) onUndo();
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
