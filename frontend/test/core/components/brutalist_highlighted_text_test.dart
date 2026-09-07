import 'package:freebay/core/ui.dart';
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
  });
}
