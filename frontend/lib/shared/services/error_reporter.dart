import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:freebay/shared/config/app_config.dart';

String safeErrorSummary(String context, Object error) {
  final label = context.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final safeContext = label.substring(0, label.length > 40 ? 40 : label.length);
  return '[$safeContext] ${error.runtimeType}';
}

class ErrorReporter {
  const ErrorReporter._();

  static bool get isEnabled => Sentry.isEnabled;

  static Future<void> initialize() async {
    if (AppConfig.sentryDsn.isEmpty) {
      return;
    }
    await SentryFlutter.init((options) {
      options.dsn = AppConfig.sentryDsn;
      options.debug = kDebugMode;
    });
  }

  static void report(String context, Object error, [StackTrace? stackTrace]) {
    final summary = safeErrorSummary(context, error);
    if (kDebugMode) {
      debugPrint('$summary: $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
    if (!isEnabled) return;
    Sentry.captureException(
      StateError(error.runtimeType.toString()),
      // The original error and stack may contain request or account data.
      withScope: (scope) => scope.setTag(
        'boot_stage',
        summary.substring(1, summary.indexOf(']')),
      ),
    );
  }
}
