import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/profile/presentation/pages/saved_posts_page.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class _Adapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions)> responses = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => responses.removeAt(0)(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _mutation({required bool active}) => ResponseBody.fromString(
  jsonEncode({
    'success': true,
    'data': {'active': active},
  }),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _savedPage() => ResponseBody.fromString(
  jsonEncode({
    'success': true,
    'data': {
      'items': [
        {
          'id': 'post-1',
          'userId': 'user-1',
          'user': {'id': 'user-1', 'displayName': 'Ana'},
          'content': 'A saved post',
          'createdAt': '2026-09-28T12:00:00.000Z',
          'isSaved': true,
        },
      ],
      'hasMore': false,
      'nextCursor': null,
    },
  }),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test('restores a failed unsave and retries successfully', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    adapter.responses.add((_) => ResponseBody.fromString('', 500));
    adapter.responses.add((_) => _mutation(active: false));
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(
          SocialRepository(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(savesProvider.notifier);

    expect(await notifier.toggleSave('post-1', initialIsSaved: true), isFalse);
    expect(container.read(savesProvider).getSavedOverride('post-1'), isTrue);
    expect(await notifier.toggleSave('post-1', initialIsSaved: true), isTrue);
    expect(container.read(savesProvider).getSavedOverride('post-1'), isFalse);
  });

  testWidgets('saved list removes a post unsaved from its detail screen', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter()
      ..responses.add((_) => _savedPage())
      ..responses.add((_) => _mutation(active: false));
    dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(
          SocialRepository(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SavedPostsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A saved post', findRichText: true), findsOneWidget);

    await tester.runAsync(
      () => container
          .read(savesProvider.notifier)
          .toggleSave('post-1', initialIsSaved: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('A saved post', findRichText: true), findsNothing);
    expect(find.text('NENHUMA PUBLICAÇÃO SALVA'), findsOneWidget);
  });
}
