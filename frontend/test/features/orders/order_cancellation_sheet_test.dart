import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/orders/presentation/widgets/order_cancellation_sheet.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'requires a reason, keeps it after failure, and closes on retry success',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showBrutalistSheet<void>(
                  context: context,
                  title: 'CANCELAR PEDIDO',
                  scrollable: false,
                  builder: (_) => OrderCancellationSheet(
                    onConfirm: (_) async => ++attempts > 1,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final confirm = find.byType(AppButton).last;
      expect(tester.widget<AppButton>(confirm).onPressed, isNull);
      await tester.tap(find.text('Mudei de ideia'));
      await tester.pump();
      expect(tester.widget<AppButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(attempts, 1);
      expect(find.text('Mudei de ideia'), findsOneWidget);
      expect(find.byType(OrderCancellationSheet), findsOneWidget);

      await tester.tap(find.byType(AppButton).last);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.byType(OrderCancellationSheet), findsNothing);
    },
  );

  testWidgets('does not send twice while confirmation is pending', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBrutalistSheet<void>(
                context: context,
                scrollable: false,
                builder: (_) => OrderCancellationSheet(
                  onConfirm: (_) {
                    calls++;
                    return pending.future;
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudei de ideia'));
    await tester.pump();
    await tester.tap(find.byType(AppButton).last);
    await tester.pump();
    await tester.tap(find.byType(AppButton).last, warnIfMissed: false);
    expect(calls, 1);

    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(OrderCancellationSheet), findsNothing);
  });
}
