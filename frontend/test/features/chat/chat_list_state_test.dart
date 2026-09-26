import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/last_message_info.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/services/chat_socket_service.dart';

class _Socket extends ChatSocketService {
  final _messages = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messageStream => _messages.stream;

  void emit(Map<String, dynamic> message) => _messages.add(message);

  @override
  void dispose() => _messages.close();
}

class _Repository extends ChatRepository {
  _Repository(this.responses);

  final List<Future<Either<Failure, CursorPage<ChatEntity>>>> responses;
  final queries = <String?>[];
  int calls = 0;

  @override
  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) {
    queries.add(query);
    return responses[calls++];
  }
}

ChatEntity _chat(String id, DateTime time) => ChatEntity(
  id: id,
  threadType: ChatThreadType.direct,
  otherUser: UserEntity(id: 'user-$id'),
  createdAt: time,
  lastMessageInfo: LastMessageInfo(content: id, createdAt: time),
);

CursorPage<ChatEntity> _page(
  List<ChatEntity> chats, {
  bool hasMore = false,
  String? nextCursor,
}) => CursorPage(items: chats, hasMore: hasMore, nextCursor: nextCursor);

ProviderContainer _container(_Repository repository, _Socket socket) {
  return ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(repository),
      chatSocketServiceProvider.overrideWithValue(socket),
    ],
  );
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );

  test('discards a slow response from the previous query', () async {
    final oldResponse = Completer<Either<Failure, CursorPage<ChatEntity>>>();
    final newResponse = Completer<Either<Failure, CursorPage<ChatEntity>>>();
    final repository = _Repository([oldResponse.future, newResponse.future]);
    final container = _container(repository, _Socket());
    addTearDown(container.dispose);

    final subscription = container.listen(liveChatListProvider, (_, _) {});
    addTearDown(subscription.close);
    await _settle();
    container.read(chatListQueryProvider.notifier).state = 'new';
    for (var attempt = 0; attempt < 20 && repository.calls < 2; attempt++) {
      await _settle();
    }

    newResponse.complete(
      Right(_page([_chat('new', DateTime.utc(2026, 9, 21))])),
    );
    await _settle();
    await _settle();
    oldResponse.complete(
      Right(_page([_chat('old', DateTime.utc(2026, 9, 20))])),
    );
    await _settle();

    expect(container.read(liveChatListProvider).items.map((chat) => chat.id), [
      'new',
    ]);
    expect(repository.queries, [null, 'new']);
  });

  test('keeps a live update while fetchMore is pending', () async {
    final moreResponse = Completer<Either<Failure, CursorPage<ChatEntity>>>();
    final socket = _Socket();
    final repository = _Repository([
      Future.value(
        Right(
          _page(
            [_chat('one', DateTime.utc(2026, 9, 20))],
            hasMore: true,
            nextCursor: 'tail',
          ),
        ),
      ),
      moreResponse.future,
    ]);
    final container = _container(repository, socket);
    addTearDown(container.dispose);

    container.read(liveChatListProvider);
    await _settle();
    final more = container.read(liveChatListProvider.notifier).fetchMore();
    socket.emit({
      'conversationId': 'one',
      'content': 'live',
      'createdAt': '2026-09-21T00:00:00Z',
      'senderId': 'other',
    });
    moreResponse.complete(
      Right(_page([_chat('two', DateTime.utc(2026, 9, 19))])),
    );
    await more;

    final state = container.read(liveChatListProvider);
    expect(state.items.map((chat) => chat.id), ['one', 'two']);
    expect(state.items.first.lastMessage, 'live');
  });

  test('coalesces burst refreshes and permits retry after failure', () async {
    final refresh = Completer<Either<Failure, CursorPage<ChatEntity>>>();
    final retry = Completer<Either<Failure, CursorPage<ChatEntity>>>();
    final repository = _Repository([
      Future.value(Right(_page([_chat('one', DateTime.utc(2026, 9, 20))]))),
      refresh.future,
      retry.future,
    ]);
    final container = _container(repository, _Socket());
    addTearDown(container.dispose);

    container.read(liveChatListProvider);
    await _settle();
    final first = container.read(liveChatListProvider.notifier).refreshRecent();
    final second = container
        .read(liveChatListProvider.notifier)
        .refreshRecent();
    expect(identical(first, second), isTrue);
    refresh.complete(const Left(UnknownFailure()));
    await first;

    final retried = container
        .read(liveChatListProvider.notifier)
        .refreshRecent();
    retry.complete(Right(_page([_chat('two', DateTime.utc(2026, 9, 21))])));
    await retried;

    expect(repository.calls, 3);
    expect(container.read(liveChatListProvider).items.first.id, 'two');
  });
}
