import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/comment_context.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/comment_context_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/notification_socket_service.dart';
import '../../support/test_users.dart';

class _Repository extends SocialRepository {
  _Repository(this.respond) : super(client: Dio());

  final Future<Either<Failure, CommentContext>> Function(
    String commentId, {
    String? replyCursor,
    String? ancestorCursor,
    String replySort,
  })
  respond;

  @override
  Future<Either<Failure, CommentContext>> getCommentContext(
    String commentId, {
    String? replyCursor,
    String? ancestorCursor,
    String replySort = 'recent',
  }) => respond(
    commentId,
    replyCursor: replyCursor,
    ancestorCursor: ancestorCursor,
    replySort: replySort,
  );
}

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

class _SocketEvents extends NotificationSocketService {
  _SocketEvents() : super(tokenReader: () async => null);

  final _controller = StreamController<NotificationSocketEvent>.broadcast();

  @override
  Stream<NotificationSocketEvent> get events => _controller.stream;

  void emit(NotificationSocketEvent event) => _controller.add(event);

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

void main() {
  test(
    'independently merges ancestor and reply pages without cursor loss',
    () async {
      final requests = <({String? reply, String? ancestor, String sort})>[];
      final repository = _Repository((
        commentId, {
        replyCursor,
        ancestorCursor,
        replySort = 'recent',
      }) async {
        requests.add((
          reply: replyCursor,
          ancestor: ancestorCursor,
          sort: replySort,
        ));
        if (ancestorCursor == null && replyCursor == null) {
          return Right(
            _context(
              ancestors: [_comment('a32', parent: 'a31')],
              replies: [_comment('r1', parent: 'focus')],
              nextAncestor: 'ancestor-1',
              nextReply: 'reply-1',
            ),
          );
        }
        if (ancestorCursor != null) {
          return Right(
            _context(
              ancestors: [
                _comment('a1', parent: null),
                _comment('a2', parent: 'a1'),
                _comment('a32', parent: 'a31'),
              ],
              nextAncestor: 'ancestor-2',
            ),
          );
        }
        return Right(
          _context(
            replies: [
              _comment('r1', parent: 'focus'),
              _comment('r2', parent: 'focus'),
              _comment('r2', parent: 'focus'),
            ],
          ),
        );
      });
      final container = _container(repository);
      addTearDown(container.dispose);
      final provider = commentContextControllerProvider(
        'focus',
        replySort: 'likes',
      );
      await container.read(provider.future);

      await Future.wait([
        container.read(provider.notifier).loadAncestors(),
        container.read(provider.notifier).loadReplies(),
      ]);
      final result = container.read(provider).requireValue.value;

      expect(result.ancestors.map((comment) => comment.id), [
        'a1',
        'a2',
        'a32',
      ]);
      expect(result.replies.map((comment) => comment.id), ['r1', 'r2']);
      expect(result.nextAncestorCursor, 'ancestor-2');
      expect(result.nextReplyCursor, isNull);
      expect(requests[1], (reply: null, ancestor: 'ancestor-1', sort: 'likes'));
      expect(requests[2], (reply: 'reply-1', ancestor: null, sort: 'likes'));
    },
  );

  test(
    'pagination failure keeps cursor and retry uses the same cursor',
    () async {
      var ancestorRequests = 0;
      final repository = _Repository((
        commentId, {
        replyCursor,
        ancestorCursor,
        replySort = 'recent',
      }) async {
        if (ancestorCursor == null) {
          return Right(
            _context(
              ancestors: [_comment('a32', parent: 'a31')],
              nextAncestor: 'cursor-stable',
            ),
          );
        }
        ancestorRequests++;
        if (ancestorRequests == 1) {
          return const Left(ServerFailure('temporary'));
        }
        return Right(_context(ancestors: [_comment('a1', parent: null)]));
      });
      final container = _container(repository);
      addTearDown(container.dispose);
      final provider = commentContextControllerProvider('focus');
      await container.read(provider.future);

      await container.read(provider.notifier).loadAncestors();
      expect(container.read(provider).requireValue.ancestorError, 'temporary');
      expect(
        container.read(provider).requireValue.value.nextAncestorCursor,
        'cursor-stable',
      );

      await container.read(provider.notifier).loadAncestors();
      final result = container.read(provider).requireValue;
      expect(ancestorRequests, 2);
      expect(result.value.ancestors.map((item) => item.id), ['a1', 'a32']);
      expect(result.value.nextAncestorCursor, isNull);
      expect(result.ancestorError, isNull);
    },
  );

  test(
    'late page is ignored after account change and private invalidation',
    () async {
      final pendingPage = Completer<Either<Failure, CommentContext>>();
      final pendingRefresh = Completer<Either<Failure, CommentContext>>();
      var calls = 0;
      final repository = _Repository((
        commentId, {
        replyCursor,
        ancestorCursor,
        replySort = 'recent',
      }) {
        calls++;
        if (calls == 1) {
          return Future.value(
            Right(
              _context(
                replies: [_comment('r1', parent: 'focus')],
                nextReply: 'reply-cursor',
              ),
            ),
          );
        }
        if (calls == 2) return pendingPage.future;
        if (calls == 3) return pendingRefresh.future;
        return Future.value(
          Right(
            _context(replies: [_comment('private-fresh', parent: 'focus')]),
          ),
        );
      });
      final socket = _SocketEvents();
      final container = _container(repository, socket: socket);
      addTearDown(() {
        container.dispose();
        socket.dispose();
      });
      final provider = commentContextControllerProvider('focus');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final pageRequest = container.read(provider.notifier).loadReplies();

      final auth = container.read(authControllerProvider.notifier) as _Auth;
      auth.switchTo(testUser(id: 'account-b'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(provider).isLoading, isTrue);
      pendingPage.complete(
        Right(
          _context(replies: [_comment('stale-old-account', parent: 'focus')]),
        ),
      );
      await pageRequest;
      expect(container.read(provider).isLoading, isTrue);

      // The watched auth change starts a fresh request. Invalidation then starts
      // another fresh read; neither earlier response may become visible.
      socket.emit(const PrivateContentInvalidated());
      await Future<void>.delayed(Duration.zero);
      pendingRefresh.complete(
        Right(
          _context(
            replies: [_comment('stale-before-revocation', parent: 'focus')],
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final latest = container.read(provider).asData?.value.value;
      expect(latest?.replies.map((item) => item.id), ['private-fresh']);
    },
  );

  test(
    'a page response for another focus is rejected without advancing cursor',
    () async {
      final repository = _Repository((
        commentId, {
        replyCursor,
        ancestorCursor,
        replySort = 'recent',
      }) async {
        if (ancestorCursor == null) {
          return Right(
            _context(
              ancestors: [_comment('a32', parent: 'a31')],
              nextAncestor: 'bound-to-focus',
            ),
          );
        }
        return Right(
          CommentContext(
            ancestors: [_comment('leaked-parent', parent: null)],
            focus: _comment('different-focus', parent: 'leaked-parent'),
            replies: const [],
          ),
        );
      });
      final container = _container(repository);
      addTearDown(container.dispose);
      final provider = commentContextControllerProvider('focus');
      await container.read(provider.future);

      await container.read(provider.notifier).loadAncestors();
      final failed = container.read(provider).requireValue;
      expect(failed.ancestorError, 'Context response focus mismatch');
      expect(failed.value.ancestors.map((item) => item.id), ['a32']);
      expect(failed.value.nextAncestorCursor, 'bound-to-focus');
    },
  );
}

ProviderContainer _container(
  SocialRepository repository, {
  _SocketEvents? socket,
}) {
  final service = socket ?? _SocketEvents();
  return ProviderContainer(
    overrides: [
      socialRepositoryProvider.overrideWithValue(repository),
      authControllerProvider.overrideWith(
        () => _Auth(testUser(id: 'account-a')),
      ),
      notificationSocketServiceProvider.overrideWith((ref) => service),
    ],
  );
}

CommentContext _context({
  List<CommentEntity> ancestors = const [],
  List<CommentEntity> replies = const [],
  String? nextAncestor,
  String? nextReply,
}) => CommentContext(
  ancestors: ancestors,
  focus: _comment('focus', parent: 'a31'),
  replies: replies,
  nextAncestorCursor: nextAncestor,
  nextReplyCursor: nextReply,
);

CommentEntity _comment(String id, {required String? parent}) => CommentEntity(
  id: id,
  content: id,
  userId: 'author',
  postId: 'post',
  parentId: parent,
  createdAt: DateTime.utc(2026),
);
