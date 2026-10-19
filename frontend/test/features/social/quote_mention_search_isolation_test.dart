import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/pages/create_post_page.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _SearchAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'users': [
            {'id': 'candidate', 'displayName': 'Candidate'},
          ],
          'hasMore': false,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _QuoteCaptureRepository extends SocialRepository {
  String? content;
  List<String>? mentionIds;

  @override
  Future<Either<Failure, PostEntity>> createQuote({
    required String content,
    required String sourceId,
    required bool sourceIsComment,
    required String clientRequestId,
    List<String> mentionIds = const [],
    String? imagePath,
  }) async {
    this.content = content;
    this.mentionIds = mentionIds;
    return const Left(ServerFailure('expected test failure'));
  }
}

class _UserSearch extends UserSearch {
  @override
  UserSearchState build() => const UserSearchState();

  @override
  Future<void> search({String? query, bool refresh = false}) async {
    state = const UserSearchState(
      users: [UserSearchEntity(id: 'found-user', displayName: 'Found User')],
    );
  }
}

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool showQuoteComposer = false;

  @override
  Widget build(BuildContext context) => showQuoteComposer
      ? CreatePostPage(quoteSource: _source())
      : Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => setState(() => showQuoteComposer = true),
              child: const Text('Open quote composer'),
            ),
          ),
        );
}

QuoteSource _source() => QuoteSource.post(
  id: 'post-1',
  post: PostEntity(
    id: 'post-1',
    userId: 'author',
    createdAt: DateTime.utc(2026),
    user: testUser(id: 'author'),
  ),
);

void main() {
  testWidgets('quote composer disposal preserves People Search results', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => TestAuthController(testUser(id: 'viewer')),
        ),
        userSearchProvider.overrideWith(_UserSearch.new),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(userSearchProvider.notifier)
        .search(query: 'found', refresh: true);
    expect(container.read(userSearchProvider).users, hasLength(1));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _Host(),
        ),
      ),
    );
    await tester.tap(find.text('Open quote composer'));
    await tester.pump();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );

    expect(container.read(userSearchProvider).users, hasLength(1));
    expect(container.read(userSearchProvider).users.single.id, 'found-user');
  });

  test(
    'quote mention provider reads candidates from SocialRepository',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _SearchAdapter();
      dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(
            SocialRepository(client: dio),
          ),
        ],
      );
      addTearDown(container.dispose);

      final candidates = await container.read(
        quoteMentionCandidatesProvider('candidate').future,
      );

      expect(adapter.request?.path, '/users/search');
      expect(adapter.request?.queryParameters['q'], 'candidate');
      expect(candidates.single.id, 'candidate');
    },
  );

  testWidgets('unselected quote search text is not posted as a mention', (
    tester,
  ) async {
    final repository = _QuoteCaptureRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'viewer')),
          ),
          socialRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CreatePostPage(quoteSource: _source()),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Good post');
    await tester.enterText(find.byType(TextField).last, 'alice');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Good post',
    );
    tester.widget<AppButton>(find.byType(AppButton)).onPressed!();
    expect(repository.content, 'Good post');
    expect(repository.mentionIds, isEmpty);
  });
}
