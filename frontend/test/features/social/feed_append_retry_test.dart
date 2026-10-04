import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart' show AppButton;
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/feed_page_result.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';

class _RetryRepository extends SocialRepository {
  final cursors = <String?>[];

  @override
  Future<Either<Failure, FeedPageResult>> getFeed({
    int limit = 20,
    String? cursor,
    int? offset,
    FeedType type = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
  }) async {
    cursors.add(cursor);
    if (cursors.length == 2) return const Left(ServerFailure('offline'));
    if (cursors.length == 3) {
      return const Right(FeedPageResult(posts: [], hasMore: false));
    }
    return Right(
      FeedPageResult(
        posts: [
          PostEntity(
            id: 'post-1',
            userId: 'author-1',
            createdAt: DateTime.utc(2026, 9, 28),
            user: const UserEntity(id: 'author-1'),
            content: 'Retained post',
          ),
        ],
        hasMore: true,
        nextCursor: 'cursor-1',
      ),
    );
  }
}

void main() {
  testWidgets('append retry keeps posts and retries the current cursor', (
    tester,
  ) async {
    final repository = _RetryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repository),
          authControllerProvider.overrideWith(() => TestAuthController(null)),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Retained post', findRichText: true), findsOneWidget);
    expect(repository.cursors, [null]);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.cursors, [null, 'cursor-1']);
    expect(find.text('Retained post', findRichText: true), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(FeedPage)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    final retryButton = find.widgetWithText(AppButton, 'Tentar novamente');
    await tester.ensureVisible(retryButton);
    await tester.pumpAndSettle();
    await tester.tap(retryButton);
    await tester.pump();
    await tester.pump();
    expect(repository.cursors, [null, 'cursor-1', 'cursor-1']);
    expect(find.text('Retained post', findRichText: true), findsOneWidget);
  });
}
