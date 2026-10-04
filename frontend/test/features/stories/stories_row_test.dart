import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
import 'package:freebay/features/stories/presentation/widgets/stories_row.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('create-story label fits at normal and large text scales', (
    tester,
  ) async {
    for (final (locale, label) in [
      (const Locale('pt', 'BR'), 'Criar story'),
      (const Locale('en'), 'Create story'),
    ]) {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storiesProvider.overrideWith(
                (ref) async => const StoriesResponse(),
              ),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(body: StoriesRow()),
              ),
            ),
          ),
        );
        await tester.pump();

        final text = find.text(label);
        expect(text, findsOneWidget);
        final widget = tester.widget<Text>(text);
        expect(widget.maxLines, 2);
        expect(widget.overflow, isNull);
        final paragraph = find.descendant(
          of: text,
          matching: find.byType(RichText),
        );
        expect(
          tester.renderObject<RenderParagraph>(paragraph).didExceedMaxLines,
          isFalse,
          reason: '$label at text scale $scale',
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}
