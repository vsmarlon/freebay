import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _Repository extends ChatRepository {
  _Repository(this.pages);

  final List<CursorPage<ChatEntity>> pages;
  int calls = 0;

  @override
  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) async => Right(pages[calls++]);
}

ChatEntity _chat(String id) => ChatEntity(
  id: id,
  threadType: ChatThreadType.direct,
  otherUser: UserEntity(id: 'user-$id'),
  createdAt: DateTime.utc(2026, 9, 20),
  lastMessageInfo: LastMessageInfo(
    content: id,
    createdAt: DateTime.utc(2026, 9, 20),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );

  test(
    'fetchMore appends only new conversations when the page overlaps',
    () async {
      final repository = _Repository([
        CursorPage(
          items: [_chat('one'), _chat('two')],
          hasMore: true,
          nextCursor: 'next',
        ),
        CursorPage(items: [_chat('two'), _chat('three')], hasMore: false),
      ]);
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repository),
          chatSocketServiceProvider.overrideWithValue(ChatSocketService()),
        ],
      );
      addTearDown(container.dispose);

      container.read(liveChatListProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await container.read(liveChatListProvider.notifier).fetchMore();

      expect(
        container.read(liveChatListProvider).items.map((chat) => chat.id),
        ['one', 'three', 'two'],
      );
      expect(repository.calls, 2);
    },
  );
}
