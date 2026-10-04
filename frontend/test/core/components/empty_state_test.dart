import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('error state invokes retry action', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EmptyState.error(onRetry: () => retried = true),
      ),
    );

    await tester.tap(find.text('TENTAR NOVAMENTE'));

    expect(retried, isTrue);
  });
}
