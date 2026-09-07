import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:freebay/shared/config/app_config.dart';

class ErrorReporter {
  const ErrorReporter._();

  static bool get isEnabled => AppConfig.sentryDsn.isNotEmpty;

  static Future<void> run(Future<void> Function() body) async {
    if (!isEnabled) {
      await body();
      return;
    }
    await SentryFlutter.init((options) {
      options.dsn = AppConfig.sentryDsn;
    }, appRunner: body);
  }

  static void report(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[$context] $error');
    if (!isEnabled) return;
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('boot_stage', context),
    );
  }
}
