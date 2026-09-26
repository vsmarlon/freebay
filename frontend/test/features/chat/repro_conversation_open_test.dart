import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_header.dart';
import 'package:freebay/features/chat/presentation/widgets/message_bubble.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _ChatRepository extends ChatRepository {
  var conversationCalls = 0;
  final conversationCallsById = <String, int>{};

  @override
  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) async {
    return const Right(CursorPage.empty());
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getStarredMessages(
    String conversationId,
  ) async {
    return const Right([]);
  }

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
    conversationCallsById[conversationId] =
        (conversationCallsById[conversationId] ?? 0) + 1;
    return Right((
      messages: [
        MessageEntity(
          id: 'm-$conversationId',
          conversationId: conversationId,
          senderId: 'user-2',
          content: 'Oi $conversationId',
          createdAt: DateTime(2026),
        ),
      ],
      hasMore: false,
      nextCursor: null,
      threadType: ChatThreadType.direct,
      otherUserId: 'user-2',
      otherUserName: 'Vendedor $conversationId',
      otherUserAvatarUrl: null,
      preference: null,
    ));
  }
}

void main() {
  testWidgets('opens a conversation without throwing', (tester) async {
    final repository = _ChatRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'user-1')),
          ),
          chatRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ChatConversationPage(chatId: 'conv-1')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(find.text('Vendedor conv-1'), findsOneWidget);
    expect(find.text('Conversa'), findsNothing);
    expect(repository.conversationCalls, 1);
  });

  testWidgets('retained conversation rebinds state and refreshes its theme', (
    tester,
  ) async {
    final repository = _ChatRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => TestAuthController(testUser(id: 'user-1')),
        ),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatConversationPage(chatId: 'conv-1')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Vendedor conv-1'), findsOneWidget);
    expect(repository.conversationCallsById['conv-1'], 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatConversationPage(chatId: 'conv-2')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Vendedor conv-2'), findsOneWidget);
    expect(find.text('Oi conv-1'), findsNothing);
    expect(repository.conversationCallsById['conv-2'], 1);

    container
        .read(conversationMessagesProvider('conv-1').notifier)
        .addOptimistic(
          MessageEntity(
            id: 'stale',
            conversationId: 'conv-1',
            senderId: 'user-2',
            content: 'stale old conversation',
            createdAt: DateTime(2026),
          ),
        );
    await tester.pump();
    expect(find.text('stale old conversation'), findsNothing);

    final currentNotifier = container.read(
      conversationMessagesProvider('conv-2').notifier,
    );
    currentNotifier.addOptimistic(
      MessageEntity(
        id: 'current',
        conversationId: 'conv-2',
        senderId: 'user-2',
        content: 'current conversation message',
        createdAt: DateTime(2026),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container
          .read(conversationMessagesProvider('conv-2'))
          .messages
          .any((message) => message.id == 'current'),
      isTrue,
    );
    expect(find.byType(MessageBubble), findsNWidgets(2));

    currentNotifier.setPreference(
      const ConversationPreference(theme: 'CRIMSON'),
    );
    await tester.pumpAndSettle();
    final header = tester.widget<ChatHeader>(find.byType(ChatHeader));
    expect(header.accentColor, const Color(0xFFDC2626));
  });
}
