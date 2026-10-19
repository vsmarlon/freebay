import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

Widget _app({required VoidCallback onRepost, required VoidCallback onQuote}) =>
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PostActions(
          isLiked: false,
          isSaved: false,
          isReposted: false,
          isLikeLoading: false,
          likesCount: 0,
          commentsCount: 0,
          sharesCount: 0,
          onLike: () {},
          onSave: () {},
          onRepost: onRepost,
          onQuote: onQuote,
        ),
      ),
    );

void main() {
  testWidgets('repost tap remains pure; long-press extras quote', (
    tester,
  ) async {
    var reposts = 0;
    var quotes = 0;
    await tester.pumpWidget(
      _app(onRepost: () => reposts++, onQuote: () => quotes++),
    );
    final repost = find.byKey(const ValueKey('post-action-repost'));

    await tester.tap(repost);
    expect(reposts, 1);
    expect(quotes, 0);

    await tester.longPress(repost);
    await tester.pumpAndSettle();
    expect(reposts, 1);
    expect(find.text('CONTEÚDO CITADO'), findsOneWidget);
    await tester.tap(find.text('CONTEÚDO CITADO'));
    await tester.pumpAndSettle();
    expect(reposts, 1);
    expect(quotes, 1);
  });

  testWidgets('quote actions wrap at narrow width with large text and counts', (
    tester,
  ) async {
    var likes = 0;
    var comments = 0;
    var reposts = 0;
    var quotes = 0;
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SizedBox(
                width: 320,
                child: PostActions(
                  isLiked: false,
                  isSaved: false,
                  isReposted: false,
                  isLikeLoading: false,
                  likesCount: 9999,
                  commentsCount: 9999,
                  sharesCount: 9999,
                  onLike: () => likes++,
                  onSave: () => saves++,
                  onRepost: () => reposts++,
                  onComment: () => comments++,
                  onQuote: () => quotes++,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final key in [
      'post-action-like',
      'post-action-comment',
      'post-action-repost',
      'post-action-quote',
      'post-action-save',
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
    }
    expect(tester.takeException(), isNull);
    expect((likes, comments, reposts, quotes, saves), (1, 1, 1, 1, 1));
  });
}
