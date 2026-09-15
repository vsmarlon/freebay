import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/models/cursor_page.dart';

class _AuthController extends AuthController {
  @override
  AsyncValue<UserEntity?> build() =>
      const AsyncValue.data(UserEntity(id: 'user-1'));
}

class _ChatRepository extends ChatRepository {
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
        String threadType,
        String otherUserId,
        String otherUserName,
        String? otherUserAvatarUrl,
        ConversationPreference? preference,
      })
    >
  >
  getConversation(String conversationId, {String? cursor, int? limit}) async {
    return Right((
      messages: [
        MessageEntity(
          id: 'm-1',
          conversationId: conversationId,
          senderId: 'user-2',
          content: 'Oi',
          createdAt: DateTime(2026),
        ),
      ],
      hasMore: false,
      nextCursor: null,
      threadType: 'DIRECT',
      otherUserId: 'user-2',
      otherUserName: 'Vendedor',
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
          authControllerProvider.overrideWith(_AuthController.new),
          chatRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: ChatConversationPage(chatId: 'conv-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(find.text('Vendedor'), findsOneWidget);
    expect(find.text('Conversa'), findsNothing);
  });
}
