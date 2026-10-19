import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/pages/post_search_page.dart';
import 'package:freebay/features/social/presentation/providers/post_search_provider.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets(
    'search results show safe quote source and quote their own post',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final post = PostEntity(
        id: 'quote-post',
        userId: 'quoting-author',
        content: 'Quoted post body',
        createdAt: DateTime.utc(2026),
        user: const UserEntity(
          id: 'quoting-author',
          displayName: 'Quoting author',
        ),
        isQuote: true,
        quoteSource: QuoteSource.post(
          id: 'source-post',
          post: PostEntity(
            id: 'source-post',
            userId: 'original-author',
            content: 'Original post body',
            createdAt: DateTime.utc(2025),
            user: const UserEntity(
              id: 'original-author',
              displayName: 'Original author',
            ),
          ),
        ),
      );
      final quotablePost = PostEntity(
        id: 'quote-post',
        userId: 'quoting-author',
        content: 'Quoted post body',
        createdAt: DateTime.utc(2026),
        user: const UserEntity(
          id: 'quoting-author',
          displayName: 'Quoting author',
        ),
      );
      final router = GoRouter(
        initialLocation: AppRoutes.postSearch,
        routes: [
          GoRoute(
            path: AppRoutes.postSearch,
            builder: (_, _) => const PostSearchPage(),
          ),
          GoRoute(
            path: AppRoutes.createPost,
            builder: (_, state) => Scaffold(
              body: Text(
                state.extra is QuoteSource &&
                        (state.extra! as QuoteSource).id == 'quote-post'
                    ? 'Quoting quote-post'
                    : 'Wrong quote source',
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postSearchProvider.overrideWithValue(
              PostSearchState(posts: [post, quotablePost]),
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Original author'), findsOneWidget);
      expect(find.text('Original post body'), findsOneWidget);
      expect(
        find.text('Quoted post body', findRichText: true),
        findsNWidgets(2),
      );

      await tester.tap(find.byKey(const ValueKey('post-action-quote')));
      await tester.pumpAndSettle();
      expect(find.text('Quoting quote-post'), findsOneWidget);
    },
  );

  testWidgets('search result with unavailable quote hides source body', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postSearchProvider.overrideWithValue(
            PostSearchState(
              posts: [
                PostEntity(
                  id: 'unavailable-quote',
                  userId: 'author',
                  content: 'Quoted post body',
                  createdAt: DateTime.utc(2026),
                  user: const UserEntity(id: 'author', displayName: 'Author'),
                  isQuote: true,
                ),
              ],
            ),
          ),
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
          home: PostSearchPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('Este conteúdo citado não está mais disponível.'),
      findsOneWidget,
    );
    expect(find.text('Quoted post body', findRichText: true), findsOneWidget);
  });
}
