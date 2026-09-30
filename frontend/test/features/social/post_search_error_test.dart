import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/social/presentation/pages/post_search_page.dart';
import 'package:freebay/features/social/presentation/providers/post_search_provider.dart';

void main() {
  testWidgets(
    'shows a retryable error instead of an empty result after search fails',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postSearchProvider.overrideWithValue(
              const PostSearchState(error: 'Sem conexão'),
            ),
          ],
          child: const MaterialApp(home: PostSearchPage()),
        ),
      );

      expect(find.text('Sem conexão'), findsOneWidget);
      expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);
      expect(find.text('NENHUM RESULTADO'), findsNothing);
    },
  );
}
