import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:freebay/shared/config/app_config.dart';

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
    if (kDebugMode) debugPrint('[$context] $error');
    if (!isEnabled) return;
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('boot_stage', context),
    );
  }
}
