import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/app_dialog.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('a non-dismissible dialog ignores back navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              AppDialog.showError<void>(
                context: context,
                title: 'Sessão expirada',
                barrierDismissible: false,
                preventBack: true,
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('SESSÃO EXPIRADA'), findsOneWidget);
  });
}
