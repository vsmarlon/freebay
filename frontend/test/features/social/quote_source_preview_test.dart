import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/widgets/quote_source_preview.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('post quote preview preserves author, content and target route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.feed,
      routes: [
        GoRoute(
          path: AppRoutes.feed,
          builder: (_, _) =>
              Scaffold(body: QuoteSourcePreview(source: _postSource())),
        ),
        GoRoute(
          path: AppRoutes.postDetails,
          builder: (_, state) =>
              Scaffold(body: Text('Post ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    expect(find.text('Original author'), findsOneWidget);
    expect(find.text('Original post body'), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);

    await tester.tap(find.text('Original post body'));
    await tester.pumpAndSettle();
    expect(find.text('Post source-post'), findsOneWidget);
  });

  testWidgets('comment quote preview preserves author, body and comment route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.feed,
      routes: [
        GoRoute(
          path: AppRoutes.feed,
          builder: (_, _) =>
              Scaffold(body: QuoteSourcePreview(source: _commentSource())),
        ),
        GoRoute(
          path: AppRoutes.commentDetails,
          builder: (_, state) => Scaffold(
            body: Text(
              'Comment ${state.pathParameters['postId']}/${state.pathParameters['commentId']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    expect(find.text('Original commenter'), findsOneWidget);
    expect(find.text('Original comment body'), findsOneWidget);

    await tester.tap(find.text('Original comment body'));
    await tester.pumpAndSettle();
    expect(find.text('Comment source-post/source-comment'), findsOneWidget);
  });

  testWidgets('unavailable quote does not expose source content or author', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(const QuoteSourcePreview(source: null)),
    );

    expect(
      find.text('Este conteúdo citado não está mais disponível.'),
      findsOneWidget,
    );
    expect(find.text('Original post body'), findsNothing);
    expect(find.text('Original author'), findsNothing);
  });
}

Widget _app(GoRouter router) => MaterialApp.router(
  locale: const Locale('pt', 'BR'),
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

Widget _localizedApp(Widget child) => MaterialApp(
  locale: const Locale('pt', 'BR'),
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

QuoteSource _postSource() => QuoteSource.post(
  id: 'source-post',
  post: PostEntity(
    id: 'source-post',
    userId: 'author',
    content: 'Original post body',
    createdAt: DateTime(2026),
    user: const UserEntity(id: 'author', displayName: 'Original author'),
  ),
);

QuoteSource _commentSource() => QuoteSource.comment(
  id: 'source-comment',
  postId: 'source-post',
  comment: CommentEntity(
    id: 'source-comment',
    content: 'Original comment body',
    userId: 'commenter',
    postId: 'source-post',
    createdAt: DateTime(2026),
    user: const UserEntity(id: 'commenter', displayName: 'Original commenter'),
  ),
);
