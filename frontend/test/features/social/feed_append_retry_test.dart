import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_list.dart';

void main() {
  testWidgets('failed append keeps posts and offers a deliberate retry', (
    tester,
  ) async {
    var retries = 0;
    final state = FeedState(
      posts: [
        PostEntity(
          id: 'post-1',
          userId: 'author-1',
          createdAt: DateTime.utc(2026, 9, 28),
          user: const UserEntity(id: 'author-1'),
          content: 'Primeira publicação',
        ),
      ],
      error: 'offline',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                FeedPostList(
                  state: state,
                  onRetry: () => retries++,
                  emptyState: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);
    await tester.tap(find.text('TENTAR NOVAMENTE'));
    expect(retries, 1);
    expect(
      find.text('Primeira publicação', findRichText: true),
      findsOneWidget,
    );
  });
}
