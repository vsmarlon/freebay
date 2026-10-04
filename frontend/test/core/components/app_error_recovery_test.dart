import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/app_error_widget.dart';
import 'package:freebay/shared/l10n/app_locale_resolution.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'renders a fallback error screen before localization is available',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppErrorWidget(
            details: FlutterErrorDetails(
              exception: StateError('startup error'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('startup error'), findsOneWidget);
    },
  );

  testWidgets(
    'renders and recovers without an app shell above the root error widget',
    (tester) async {
      final recovery = Completer<void>();
      var recoveries = 0;
      final retryLabel = lookupAppLocalizations(
        resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales),
      ).commonRetry.toUpperCase();
      await tester.pumpWidget(
        AppErrorWidget(
          details: FlutterErrorDetails(exception: StateError('startup error')),
          onRecover: () {
            recoveries++;
            return recovery.future;
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(retryLabel), findsOneWidget);
      expect(find.bySemanticsLabel(retryLabel), findsOneWidget);
      await tester.tap(find.text(retryLabel));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tapAt(
        tester.getCenter(find.byType(CircularProgressIndicator)),
      );
      expect(recoveries, 1);
      recovery.complete();
      await tester.pumpAndSettle();
      expect(recoveries, 1);
    },
  );

  testWidgets('invokes the supplied recovery action once per tap', (
    tester,
  ) async {
    var recoveries = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppErrorWidget(
          details: FlutterErrorDetails(exception: StateError('failed')),
          onRecover: () async => recoveries++,
        ),
      ),
    );

    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pumpAndSettle();
    expect(recoveries, 1);
  });

  testWidgets('keeps recovery available when a retry fails', (tester) async {
    var recoveries = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppErrorWidget(
          details: FlutterErrorDetails(exception: StateError('failed')),
          onRecover: () async {
            recoveries++;
            throw StateError('still failing');
          },
        ),
      ),
    );

    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pumpAndSettle();
    expect(recoveries, 1);
    expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);
    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pumpAndSettle();
    expect(recoveries, 2);
  });

  testWidgets('disables repeated taps while recovery is pending', (
    tester,
  ) async {
    final recovery = Completer<void>();
    var recoveries = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppErrorWidget(
          details: FlutterErrorDetails(exception: StateError('failed')),
          onRecover: () {
            recoveries++;
            return recovery.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pump();
    await tester.tapAt(
      tester.getCenter(find.byType(CircularProgressIndicator)),
    );
    expect(recoveries, 1);
    recovery.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('labels route recovery as back rather than retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppErrorWidget(
          details: FlutterErrorDetails(exception: StateError('failed')),
          onRecover: () async {},
          action: AppErrorAction.back,
        ),
      ),
    );

    expect(find.text('VOLTAR'), findsOneWidget);
    expect(find.text('TENTAR NOVAMENTE'), findsNothing);
  });

  testWidgets('labels root recovery as home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppErrorWidget(
          details: FlutterErrorDetails(exception: StateError('failed')),
          onRecover: () async {},
          action: AppErrorAction.home,
        ),
      ),
    );

    expect(find.text('INÍCIO'), findsOneWidget);
    expect(find.text('TENTAR NOVAMENTE'), findsNothing);
  });
}
