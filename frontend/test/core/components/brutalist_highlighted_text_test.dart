import 'package:freebay/core/ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrutalistHighlightedText', () {
    testWidgets('renders plain text cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrutalistHighlightedText(text: 'Olá mundo sem links'),
          ),
        ),
      );

      expect(find.byType(BrutalistHighlightedText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Olá mundo sem links');
    });

    testWidgets('parses and tokenizes URLs, mentions, and hashtags', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrutalistHighlightedText(
              text:
                  'Confira https://freebay.app e fale com @marlon sobre #vintage',
              onLinkTap: (_) {},
              onMentionTap: (_) {},
              onHashtagTap: (_) {},
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      expect(span.children, isNotNull);

      expect(
        richText.text.toPlainText(),
        'Confira https://freebay.app e fale com @marlon sobre #vintage',
      );
    });

    testWidgets('handles search query highlights', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrutalistHighlightedText(
              text: 'Bicicleta aro 29 nova',
              highlightQuery: 'bicicleta',
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Bicicleta aro 29 nova');
    });

    testWidgets('does not swallow trailing punctuation in mentions', (
      tester,
    ) async {
      String? tappedMention;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrutalistHighlightedText(
              text: 'Fale com @marlon. Entendeu?',
              onMentionTap: (m) => tappedMention = m,
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      final mentionSpan =
          span.children!.firstWhere((s) => s is TextSpan && s.text == '@marlon')
              as TextSpan;
      expect(mentionSpan.text, '@marlon');
      (mentionSpan.recognizer as TapGestureRecognizer).onTap?.call();
      expect(tappedMention, '@marlon');
      expect(richText.text.toPlainText(), 'Fale com @marlon. Entendeu?');
    });

    testWidgets('does not treat & as part of mention handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrutalistHighlightedText(
              text: 'Veja com @marlon&cia',
              onMentionTap: (_) {},
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      final mentionSpan =
          span.children!.firstWhere((s) => s is TextSpan && s.text == '@marlon')
              as TextSpan;
      expect(mentionSpan.text, '@marlon');
      expect(richText.text.toPlainText(), 'Veja com @marlon&cia');
    });
  });
}
