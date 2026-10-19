import 'dart:io';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/comment_context.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/pages/comment_context_page.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:freebay/shared/services/notification_socket_service.dart';
import 'package:freebay/shared/services/storage_service.dart';

class _Auth extends AuthController {
  _Auth(this.user);
  UserEntity? user;

  @override
  AsyncValue<UserEntity?> build() => AsyncData(user);

  void switchTo(UserEntity? value) {
    user = value;
    state = AsyncData(value);
  }
}

class _Repository extends SocialRepository {
  _Repository() : super(client: Dio());

  var createCalls = 0;
  final requestIds = <String>[];
  final contents = <String>[];
  Completer<Either<Failure, CommentEntity>>? pendingCreate;

  @override
  Future<Either<Failure, CommentContext>> getCommentContext(
    String commentId, {
    String? replyCursor,
    String? ancestorCursor,
    String replySort = 'recent',
  }) async => Right(
    CommentContext(
      ancestors: [
        _comment(
          'parent',
          postId: commentId == 'focus-2' ? 'post-2' : 'post-1',
          parentId: null,
        ),
      ],
      focus: _comment(
        commentId,
        postId: commentId == 'focus-2' ? 'post-2' : 'post-1',
        parentId: 'parent',
      ),
      replies: const [],
    ),
  );

  @override
  Future<Either<Failure, CommentEntity>> createComment(
    String postId,
    String content, {
    String? parentId,
    required String clientRequestId,
  }) async {
    createCalls++;
    requestIds.add(clientRequestId);
    contents.add(content);
    final pending = pendingCreate;
    if (pending != null) return pending.future;
    if (createCalls == 1) return const Left(ServerFailure('temporary'));
    return Right(_comment('created', postId: postId, parentId: parentId));
  }
}

class _Socket extends NotificationSocketService {
  _Socket() : super(tokenReader: () async => null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cacheDirectory;

  setUpAll(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('comment-drafts-');
    Hive.init(cacheDirectory.path);
    StorageService.enableCacheStore();
    await StorageService.readCachedJson(userId: '_warmup', key: '_');
  });

  tearDownAll(() async {
    await Hive.close();
    await cacheDirectory.delete(recursive: true);
  });

  Future<void> pumpFrame(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> flushCache(WidgetTester tester, String userId) async {
    await tester.runAsync(
      () => StorageService.writeCachedJson(
        userId: userId,
        key: '_comment_context_test_barrier',
        json: const {},
      ),
    );
  }

  testWidgets(
    'draft restore is account/target scoped and failed-send retry keeps its key',
    (tester) async {
      await tester.runAsync(StorageService.clearUserCache);
      await tester.runAsync(
        () => StorageService.writeCachedJson(
          userId: 'alice',
          key: 'social.comment.post-1.focus-1',
          json: {'content': 'Alice draft'},
        ),
      );
      await tester.runAsync(
        () => StorageService.writeCachedJson(
          userId: 'bob',
          key: 'social.comment.post-1.focus-1',
          json: {'content': 'Bob draft'},
        ),
      );
      final repository = _Repository();
      final socket = _Socket();
      final auth = _Auth(const UserEntity(id: 'alice'));

      Future<void> pumpPage(String postId, String commentId) async {
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('conversation-test-scope'),
            overrides: [
              authControllerProvider.overrideWith(() => auth),
              socialRepositoryProvider.overrideWithValue(repository),
              notificationSocketServiceProvider.overrideWith((ref) => socket),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: CommentContextPage(postId: postId, commentId: commentId),
            ),
          ),
        );
        await pumpFrame(tester);
      }

      Future<void> unmountPage() async {
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('conversation-test-scope'),
            overrides: [
              authControllerProvider.overrideWith(() => auth),
              socialRepositoryProvider.overrideWithValue(repository),
              notificationSocketServiceProvider.overrideWith((ref) => socket),
            ],
            child: const MaterialApp(home: SizedBox.shrink()),
          ),
        );
        await pumpFrame(tester);
      }

      await pumpPage('post-1', 'focus-1');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Alice draft',
      );

      auth.switchTo(const UserEntity(id: 'bob'));
      await pumpFrame(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Bob draft',
      );

      await pumpPage('post-2', 'focus-2');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.runAsync(() async {
        await tester.enterText(find.byType(TextField), 'retry this exact text');
        await tester.tap(find.byIcon(Icons.send));
      });
      await pumpFrame(tester);
      expect(repository.createCalls, 1);

      await flushCache(tester, 'bob');
      final saved = await tester.runAsync(
        () => StorageService.readCachedJson(
          userId: 'bob',
          key: 'social.comment.post-2.focus-2',
        ),
      );
      expect(saved?['content'], 'retry this exact text');
      expect(saved?['clientRequestId'], isA<String>());
      final requestId = saved!['clientRequestId'];

      await unmountPage();
      await pumpPage('post-2', 'focus-2');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'retry this exact text',
      );
      await tester.runAsync(() async {
        await tester.enterText(find.byType(TextField), 'retry this exact text');
        await tester.testTextInput.receiveAction(TextInputAction.send);
      });
      await pumpFrame(tester);
      expect(repository.requestIds, [requestId, requestId]);
      expect(repository.contents, [
        'retry this exact text',
        'retry this exact text',
      ]);
      await flushCache(tester, 'bob');
      final completed = await tester.runAsync(
        () => StorageService.readCachedJson(
          userId: 'bob',
          key: 'social.comment.post-2.focus-2',
        ),
      );
      expect(completed?['content'], isEmpty);
      expect(completed?.containsKey('clientRequestId'), isFalse);

      await unmountPage();
      await tester.runAsync(StorageService.clearUserCache);
      socket.dispose();
    },
  );

  testWidgets('a delayed send does not clear a newer composer draft', (
    tester,
  ) async {
    await tester.runAsync(StorageService.clearUserCache);
    final repository = _Repository()
      ..pendingCreate = Completer<Either<Failure, CommentEntity>>();
    final socket = _Socket();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _Auth(const UserEntity(id: 'alice')),
          ),
          socialRepositoryProvider.overrideWithValue(repository),
          notificationSocketServiceProvider.overrideWith((ref) => socket),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CommentContextPage(
            postId: 'post-1',
            commentId: 'focus-1',
          ),
        ),
      ),
    );
    await pumpFrame(tester);
    await tester.runAsync(() async {
      await tester.enterText(find.byType(TextField), 'sent draft');
      await tester.tap(find.byIcon(Icons.send));
    });
    await tester.pump();
    await tester.runAsync(
      () => tester.enterText(find.byType(TextField), 'new draft'),
    );
    await tester.runAsync(
      () => tester.enterText(find.byType(TextField), 'sent draft'),
    );
    repository.pendingCreate!.complete(
      Right(_comment('created', postId: 'post-1', parentId: 'focus-1')),
    );
    await pumpFrame(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'sent draft',
    );
    await flushCache(tester, 'alice');
    final saved = await tester.runAsync(
      () => StorageService.readCachedJson(
        userId: 'alice',
        key: 'social.comment.post-1.focus-1',
      ),
    );
    expect(saved?['content'], 'sent draft');
    expect(saved?.containsKey('clientRequestId'), isFalse);
    await tester.runAsync(StorageService.clearUserCache);
    socket.dispose();
  });

  testWidgets(
    'discard removes the retry identity before saving an empty draft',
    (tester) async {
      await tester.runAsync(StorageService.clearUserCache);
      final repository = _Repository()
        ..pendingCreate = Completer<Either<Failure, CommentEntity>>();
      final socket = _Socket();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _Auth(const UserEntity(id: 'alice')),
            ),
            socialRepositoryProvider.overrideWithValue(repository),
            notificationSocketServiceProvider.overrideWith((ref) => socket),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CommentContextPage(
              postId: 'post-1',
              commentId: 'focus-1',
            ),
          ),
        ),
      );
      await pumpFrame(tester);
      await tester.runAsync(() async {
        await tester.enterText(find.byType(TextField), 'pending draft');
        await tester.tap(find.byIcon(Icons.send));
      });
      await tester.pump();
      await flushCache(tester, 'alice');
      final pending = await tester.runAsync(
        () => StorageService.readCachedJson(
          userId: 'alice',
          key: 'social.comment.post-1.focus-1',
        ),
      );
      expect(pending?['clientRequestId'], isA<String>());

      await tester.runAsync(() async {
        await tester.tap(find.bySemanticsLabel('Clear'));
      });
      await pumpFrame(tester);
      await flushCache(tester, 'alice');
      final discarded = await tester.runAsync(
        () => StorageService.readCachedJson(
          userId: 'alice',
          key: 'social.comment.post-1.focus-1',
        ),
      );
      expect(discarded?['content'], isEmpty);
      expect(discarded?.containsKey('clientRequestId'), isFalse);

      repository.pendingCreate!.complete(
        Right(_comment('created', postId: 'post-1', parentId: 'focus-1')),
      );
      await pumpFrame(tester);

      await tester.runAsync(
        () => tester.enterText(find.byType(TextField), 'fresh draft'),
      );
      expect(repository.createCalls, 1);
      await flushCache(tester, 'alice');
      final freshDraft = await tester.runAsync(
        () => StorageService.readCachedJson(
          userId: 'alice',
          key: 'social.comment.post-1.focus-1',
        ),
      );
      expect(freshDraft?['content'], 'fresh draft');
      expect(freshDraft?.containsKey('clientRequestId'), isFalse);

      await tester.runAsync(() async {
        await tester.testTextInput.receiveAction(TextInputAction.send);
      });
      await pumpFrame(tester);
      expect(repository.createCalls, 2);
      expect(repository.requestIds[1], isNot(repository.requestIds[0]));
      await tester.runAsync(StorageService.clearUserCache);
      socket.dispose();
    },
  );
}

CommentEntity _comment(
  String id, {
  required String postId,
  required String? parentId,
}) => CommentEntity(
  id: id,
  content: id,
  userId: 'author',
  postId: postId,
  parentId: parentId,
  createdAt: DateTime.utc(2026),
);
