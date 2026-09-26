import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/chat_socket_service.dart';

class _ReloadRepository extends ChatRepository {
  int conversationCalls = 0;
  int starredCalls = 0;

  @override
  Future<
    Either<
      Failure,
      ({
        List<MessageEntity> messages,
        bool hasMore,
        String? nextCursor,
        ChatThreadType threadType,
        String otherUserId,
        String otherUserName,
        String? otherUserAvatarUrl,
        ConversationPreference? preference,
      })
    >
  >
  getConversation(String conversationId, {String? cursor, int? limit}) async {
    conversationCalls++;
    if (conversationCalls == 1) {
      return const Left(ServerFailure('initial load failed'));
    }
    return Right((
      messages: [
        MessageEntity(
          id: 'message-1',
          conversationId: conversationId,
          senderId: 'user-2',
          content: 'reloaded',
          createdAt: DateTime(2026),
        ),
      ],
      hasMore: false,
      nextCursor: null,
      threadType: ChatThreadType.direct,
      otherUserId: 'user-2',
      otherUserName: 'User 2',
      otherUserAvatarUrl: null,
      preference: null,
    ));
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getStarredMessages(
    String conversationId,
  ) async {
    starredCalls++;
    return const Right([]);
  }
}

void main() {
  testWidgets('successful silent reload clears the previous load error', (
    tester,
  ) async {
    final repository = _ReloadRepository();
    final socket = ChatSocketService();
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        chatSocketServiceProvider.overrideWithValue(socket),
      ],
    );
    addTearDown(() {
      container.dispose();
      socket.dispose();
    });

    final notifier = container.read(
      conversationMessagesProvider('conversation-1').notifier,
    );
    await tester.pump();
    await tester.pump();

    final failedState = container.read(
      conversationMessagesProvider('conversation-1'),
    );
    expect(failedState.loadError, 'initial load failed');
    expect(failedState.isLoading, isFalse);
    expect(repository.starredCalls, 1);

    await notifier.refresh();

    final reloadedState = container.read(
      conversationMessagesProvider('conversation-1'),
    );
    expect(reloadedState.loadError, isNull);
    expect(reloadedState.isLoading, isFalse);
    expect(reloadedState.messages.single.content, 'reloaded');
    expect(repository.conversationCalls, 2);
    expect(repository.starredCalls, 2);
  });
}
